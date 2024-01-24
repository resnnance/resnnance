---
-- {{ name }}_core.vhd
--
-- Pooling layer
--
-- params:
--      'name': self.label
---

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

library work;
use work.{{ name }}_config.all;

entity {{ name }}_core is
port (
    rst:  in  std_logic;
    clk:  in  std_logic;

    tick: in  std_logic;

    si:   in  std_logic;
    adi:  out std_logic_vector(pool_logm-1 downto 0);
    eni:  out std_logic;

    so:   out std_logic;
    ado:  out std_logic_vector(pool_logn-1 downto 0);
    eno:  out std_logic
);
end entity;

architecture arch of {{ name }}_core is
    signal sr:   std_logic_vector(0 to pool_p-1);
    signal adr:  std_logic_vector(pool_logn-1 downto 0);
    signal enr:  std_logic;
begin

    ---
    -- Address generation (Pooling layer)
    pool_ctrl_inst: entity work.{{ name }}_ctrl
    port map (
        rst => rst, clk => clk, tick => tick,
        si => si, adi => adi, eni => eni,
        sr => sr, adr => adr, enr => enr
    );

    ---
    -- Neuron processing unit
    pool_npu_inst: entity work.{{ name }}_npu
    port map (
        rst => rst, clk => clk,
        sr => sr, adr => adr, enr => enr,
        so => so, ado => ado, eno => eno
    );

end architecture;