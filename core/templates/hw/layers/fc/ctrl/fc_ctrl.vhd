---
-- {{ name }}_ctrl.vhd
--
-- Fully-connected layer - Control unit
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
    adi:  out std_logic_vector(fc_logm-1 downto 0);
    eni:  out std_logic;

    sr:   out std_logic_vector(0 to fc_m-1);
    adr:  out std_logic_vector(fc_logn-1 downto 0);
    wadr: out std_logic_vector(fc_logn-1 downto 0);
    enr:  out std_logic
);
end entity;

architecture arch of {{ name }}_ctrl is
    type state_t is (idle, run, rdi, rdo);
    type reg_t is record
        -- Ctrl
        state: state_t;
        adi:   unsigned(adi'range);
        ado:   unsigned(adr'range);
        -- Spike buffer
        len:   std_logic;
        la:    natural range 0 to fc_m-1;
    end record;
    signal rn, rr: reg_t;
    signal ln, lr: std_logic_vector(0 to fc_m-1);

    signal en: std_logic;
begin

    ---
    -- Register
    reg: process (rst, clk)
    begin
        if rst = '0' then
            rr <= (
                state => idle,
                adi   => (others => '0'),
                ado   => (others => '0'),
                len   => '0',
                la    => 0
            );
        elsif rising_edge(clk) then
            rr <= rn;
            lr <= ln;
        end if;
    end process;

    ---
    -- Datapath
    dp: process (
        rr, lr, tick, si, en
    )
    begin
        -- Default
        rn <= rr;
        ln <= lr;

        -- Presynaptic
        adi <= std_logic_vector(rr.adi);
        eni <= en;
        en  <= '0';

        -- Postsynaptic
        sr   <= lr;
        adr  <= std_logic_vector(rr.ado);
        wadr <= std_logic_vector(rr.ado);
        enr  <= '0';

        -- Ctrl FSM - NSL
        case rr.state is
            when idle =>
                if tick = '1' then
                    rn.state <= run;
                end if;
            when run =>
                if rr.adi < fc_m - 1 then       -- adi not finished
                    if rr.ado < fc_n - 1 then       -- ado not finished
                        rn.state <= run;
                    else                            -- ado finished
                        rn.state <= rdi;
                    end if;
                else                            -- adi finished
                    if rr.ado < fc_n - 1 then       -- ado not finished
                        rn.state <= rdo;
                    else                            -- ado finished
                        rn.state <= idle;
                    end if;
                end if;
            when rdi =>
                if rr.adi < fc_m - 1 then       -- adi not finished
                    rn.state <= rdi;
                else                            -- adi finished
                    rn.state <= idle;
                end if;
            when rdo =>
                if rr.ado < fc_n - 1 then       -- ado not finished
                    rn.state <= rdo;
                else                            -- ado finished
                    rn.state <= idle;
                end if;
        end case;

        -- Ctrl FSM - adi
        if rr.state = run or rr.state = rdi then
            en <= '1';
            if rr.adi < fc_m - 1 then
                rn.adi <= rr.adi + 1;
            else
                rn.adi <= (others => '0');
            end if;
        end if;

        -- Ctrl FSM - ado
        if rr.state = run or rr.state = rdo then
            enr <= '1';
            if rr.ado < fc_n - 1 then
                rn.ado <= rr.ado + 1;
            else
                rn.ado <= (others => '0');
            end if;
        end if;

        -- lr buffer
        rn.len <= en;
        rn.la  <= to_integer(rr.adi);
        if rr.len = '1' then
            ln(rr.la) <= si;
        end if;

    end process;


end architecture;