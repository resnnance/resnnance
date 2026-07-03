---
-- {{ name }}_ctrl.vhd
--
-- Convolutional 2D layer - Control unit
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
    adi:  out std_logic_vector(conv2D_logm-1 downto 0);
    eni:  out std_logic;

    sr:   out std_logic_vector(0 to conv2D_k-1);
    adr:  out std_logic_vector(conv2D_logn-1 downto 0);
    wadr: out std_logic_vector(conv2D_logf-1 downto 0);
    enr:  out std_logic
);
end entity;

architecture arch of {{ name }}_ctrl is
    type state_t is (idle, run);
    type reg_t is record
        state: state_t;
        x:     unsigned(conv2D_logmx-1 downto 0);
        y:     unsigned(conv2D_logmy-1 downto 0);
        z:     unsigned(conv2D_logkz-1 downto 0);
        f:     unsigned(conv2D_logf-1 downto 0);
        xo:    unsigned(conv2D_logmx-1 downto 0);
        yo:    unsigned(conv2D_logmy-1 downto 0);
        len:   std_logic;
    end record;
    signal rn, rr: reg_t;

    constant conv2D_l: natural := ((conv2D_ky - 1) * conv2D_mx + conv2D_kx) * conv2D_kz;
    signal ln, lr: std_logic_vector(0 to conv2D_l-1);
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
                f     => (others => '0'),
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
            constant umy: unsigned(y'range) := to_unsigned(conv2D_my, y'length);
        begin
            return resize(umy * y + x, adi'length);
        end function;

        function get_adiz(x: unsigned; y: unsigned; z: unsigned) return unsigned is
            constant umx: unsigned(x'range) := to_unsigned(conv2D_mx, x'length);
            constant umy: unsigned(y'range) := to_unsigned(conv2D_my, y'length);
        begin
            return resize(umx * umy * z + umy * y + x, adi'length);
        end function;

        function get_adr(x: unsigned; y: unsigned) return unsigned is
            constant uny: unsigned(y'range) := to_unsigned(conv2D_ny, y'length);
        begin
            return resize(uny * y + x, adr'length);
        end function;

        function get_adrf(x: unsigned; y: unsigned; f: unsigned) return unsigned is
            constant unx: unsigned(x'range) := to_unsigned(conv2D_nx, x'length);
            constant uny: unsigned(y'range) := to_unsigned(conv2D_ny, y'length);
        begin
            return resize(unx * uny * f + uny * y + x, adr'length);
        end function;

        function kernel_aligned(x: unsigned; y: unsigned) return boolean is
        begin
            if x >= (conv2D_kx - 1) and y >= (conv2D_ky - 1) then
                return true;
            else
                return false;
            end if;
        end function;

        function kernel_alignedz(x: unsigned; y: unsigned; z: unsigned) return boolean is
        begin
            if x >= (conv2D_kx - 1) and y >= (conv2D_ky - 1) and z = (conv2D_kz - 1) then
                return true;
            else
                return false;
            end if;
        end function;

        function out_x(x: unsigned) return unsigned is
        begin
            return x - (conv2D_kx - 1);
        end function;

        function out_y(y: unsigned) return unsigned is
        begin
            return y - (conv2D_ky - 1);
        end function;

        function row(i: natural) return natural is
        begin
            return ((conv2D_ky - 1) - i) * conv2D_kz * conv2D_mx + (conv2D_kz * conv2D_kx - 1);  -- Row position in line buffer
        end function;

        function tap(i: natural) return natural is
        begin
            return row(i) + (conv2D_kz * conv2D_kx * i);  -- Tap position
        end function;

        function taps(l: std_logic_vector) return std_logic_vector is
            variable s: std_logic_vector(sr'range);
        begin
            for k in 0 to conv2D_kz-1 loop
                for i in 0 to conv2D_ky-1 loop  -- One tap per row
                    for j in 0 to conv2D_kx-1 loop
                        s(conv2D_kx * conv2D_kz * i + conv2D_kz * j + k) := l(tap(i));
                    end loop;
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
        if conv2D_kz = 1 then
            adi <= std_logic_vector(get_adi(rr.x, rr.y));
        else
            adi <= std_logic_vector(get_adiz(rr.x, rr.y, rr.z));
        end if;
        eni <= '0';

        -- Postsynaptic
        rn.xo <= out_x(rn.x);
        rn.yo <= out_y(rn.y);

        sr <= taps(lr);
        if conv2D_kz = 1 then
            if kernel_aligned(rr.x, rr.y) then
                if conv2D_f = 1 then
                    adr <= std_logic_vector(get_adr(rr.xo, rr.yo));
                else
                    adr <= std_logic_vector(get_adrf(rr.xo, rr.yo, rr.f));
                end if;
            else
                adr <= (others => '0');
            end if;
        else
            if kernel_alignedz(rr.x, rr.y, rr.z) then
                if conv2D_f = 1 then
                    adr <= std_logic_vector(get_adr(rr.xo, rr.yo));
                else
                    adr <= std_logic_vector(get_adrf(rr.xo, rr.yo, rr.f));
                end if;
            else
                adr <= (others => '0');
            end if;
        end if;
        wadr <= std_logic_vector(rr.f);
        enr  <= '0';

        -- Ctrl FSM
        if rr.state = idle then
            if tick = '1' then
                rn.state <= run;
            end if;
        else
            -- Input control
            eni <= '1';
            if rr.z < (conv2D_kz - 1) then
                -- Sweep z dim
                rn.z <= rr.z + 1;
            else
                rn.z <= (others => '0');

                if rr.x < (conv2D_mx - 1) then
                    -- Sweep x dim
                    rn.x <= rr.x + 1;
                else
                    rn.x <= (others => '0');

                    if rr.y < (conv2D_my - 1) then
                        -- Sweep y dim
                        rn.y <= rr.y + 1;
                    else
                        rn.y <= (others => '0');

                        if rr.f < (conv2D_f - 1) then
                            -- Sweep kernels
                            rn.f <= rr.f + 1;
                        else
                            rn.f     <= (others => '0');
                            rn.state <= idle;
                        end if;
                    end if;
                end if;
            end if;

            -- Line buffer control
            rn.len <= '1';

            -- Kernel alignment
            if conv2D_kz = 1 then
                if kernel_aligned(rr.x, rr.y) then
                    enr <= '1';
                end if;
            else
                if kernel_alignedz(rr.x, rr.y, rr.z) then
                    enr <= '1';
                end if;
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