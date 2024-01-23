---
-- {{ name }}_ctrl.vhd
--
-- Pooling layer - Control unit
--
-- params:
--      'name': self.label
---

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.{{ name }}_config.all;

entity {{ name }}_ctrl is
port (
    rst:  in  std_logic;
    clk:  in  std_logic;

    tick: in  std_logic;

    si:   in  std_logic;
    adi:  out std_logic_vector(pool_logm-1 downto 0);
    eni:  out std_logic;

    sr:   out std_logic_vector(0 to pool_p-1);
    adr:  out std_logic_vector(pool_logn-1 downto 0);
    wadr: out std_logic_vector(pool_logn-1 downto 0);
    enr:  out std_logic
);
end entity;

architecture arch of {{ name }}_ctrl is
    type state_t is (idle, run);
    type reg_t is record
        state: state_t;
        x:     unsigned(pool_logmx-1 downto 0);
        y:     unsigned(pool_logmy-1 downto 0);
        z:     unsigned(pool_logmz-1 downto 0);
        xs:    unsigned(pool_logmx-1 downto 0);
        ys:    unsigned(pool_logmy-1 downto 0);
        sx:    unsigned(pool_logpx-1 downto 0);
        sy:    unsigned(pool_logpy-1 downto 0);
        xo:    unsigned(pool_logmx-1 downto 0);
        yo:    unsigned(pool_logmy-1 downto 0);
        len:   std_logic;
    end record;
    signal rn, rr: reg_t;

    constant pool_l: natural := ((pool_py - 1) * pool_mx + pool_px);
    signal ln, lr: std_logic_vector(0 to pool_l-1);

    signal ad: std_logic_vector(pool_logn-1 downto 0);
begin

    ---
    -- Register
    reg: process (rst, clk)
    begin
        if rst = '0' then
            rr <= (
                state => idle,
                x     => (others => '0'),
                y     => (others => '0'),
                z     => (others => '0'),
                xs    => (others => '0'),
                ys    => (others => '0'),
                sx    => (others => '0'),
                sy    => (others => '0'),
                xo    => (others => '0'),
                yo    => (others => '0'),
                len   => '0'
            );
        elsif rising_edge(clk) then
            rr <= rn;
            lr <= ln;
        end if;
    end process;

    ---
    -- Datapath
    dp: process (
        rn, rr, lr, tick, si
    )
        function get_adi(x: unsigned; y: unsigned) return unsigned is
            constant umy: unsigned(y'range) := to_unsigned(pool_my, y'length);
        begin
            return resize(umy * y + x, adi'length);
        end function;

        function get_adiz(x: unsigned; y: unsigned; z: unsigned) return unsigned is
            constant umx: unsigned(x'range) := to_unsigned(pool_mx, x'length);
            constant umy: unsigned(y'range) := to_unsigned(pool_my, y'length);
        begin
            return resize(umx * umy * z + umy * y + x, adi'length);
        end function;

        function get_adr(x: unsigned; y: unsigned) return unsigned is
            constant uny: unsigned(y'range) := to_unsigned(pool_ny, y'length);
        begin
            return resize(uny * y + x, adr'length);
        end function;

        function kernel_aligned(x: unsigned; y: unsigned) return boolean is
        begin
            if x >= (pool_px - 1) and y >= (pool_py - 1) then
                -- TODO Add support for px, py != 2
                if x(0) = '1' and y(0) = '1' then
                    return true;
                else
                    return false;
                end if;
            else
                return false;
            end if;
        end function;

        function out_x(x: unsigned) return unsigned is
        begin
            return x - (pool_px - 1);
        end function;

        function out_y(y: unsigned) return unsigned is
        begin
            return y - (pool_py - 1);
        end function;

        function row(i: natural) return natural is
        begin
            return ((pool_py - 1) - i) * pool_mx + (pool_px - 1);  -- Row position in line buffer
        end function;

        function tap(i: natural) return natural is
        begin
            return row(i) + (pool_px * i);  -- Tap position
        end function;

        function taps(l: std_logic_vector) return std_logic_vector is
            variable s: std_logic_vector(sr'range);
        begin
            for i in 0 to pool_py-1 loop  -- One tap per row
                for j in 0 to pool_px-1 loop
                    s(pool_px * i + j) := l(tap(i));
                end loop;
            end loop;

            return s;
        end function;
    begin
        -- Default
        rn     <= rr;
        ln     <= lr;
        rn.len <= '0';

        -- Presynaptic
        if pool_mz = 1 then
            adi <= std_logic_vector(get_adi(rr.x, rr.y));
        else
            adi <= std_logic_vector(get_adiz(rr.x, rr.y, rr.z));
        end if;
        eni <= '0';

        -- Postsynaptic
        rn.xo <= out_x(rn.xs);
        rn.yo <= out_y(rn.ys);

        sr <= taps(lr);
        if kernel_aligned(rr.x, rr.y) then
            -- TODO Add support for px, py != 2
            ad <= std_logic_vector(get_adr(rr.xs, rr.ys));
        else
            adr <= (others => '0');
        end if;
        wadr <= (others => '0');
        enr  <= '0';

        -- Ctrl FSM
        if rr.state = idle then
            if tick = '1' then
                rn.state <= run;
            end if;
        else
            -- Input control
            eni <= '1';
            if rr.x < (pool_mx - 1) then
                -- Sweep x dim
                rn.x <= rr.x + 1;

                -- Sweep surrogate x dim
                if rr.sx < (pool_px - 1) then
                    rn.sx <= rr.sx + 1;
                else
                    rn.sx <= (others => '0');
                    rn.xs <= rr.xs + 1;
                end if;
            else
                rn.x  <= (others => '0');
                rn.xs <= (others => '0');
                rn.sx <= (others => '0');

                if rr.y < (pool_my - 1) then
                    -- Sweep y dim
                    rn.y <= rr.y + 1;

                    -- Sweep surrogate y dim
                    if rr.sy < (pool_py - 1) then
                        rn.sy <= rr.sy + 1;
                    else
                        rn.sy <= (others => '0');
                        rn.ys <= rr.ys + 1;
                    end if;
                else
                    rn.y  <= (others => '0');
                    rn.ys <= (others => '0');
                    rn.sy <= (others => '0');

                    if rr.z < (pool_mz - 1) then
                        -- Sweep input maps
                        rn.z <= rr.z + 1;
                    else
                        rn.z     <= (others => '0');
                        rn.state <= idle;
                    end if;
                end if;
            end if;

            -- Line buffer control
            rn.len <= '1';

            -- Kernel alignment
            if kernel_aligned(rr.x, rr.y) then
                enr <= '1';
            end if;
        end if;

        -- Line buffer
        if rr.len = '1' then
            ln(0) <= si;
            for i in 0 to lr'length-2 loop
                ln(i+1) <= lr(i);
            end loop;
        end if;
    end process;

end architecture;