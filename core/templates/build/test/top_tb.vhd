library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_tb is
end top_tb;

architecture arch of top_tb is
    constant period: time := 10 ns;

    signal rst: std_logic := '0';
    signal clk: std_logic := '0';

    {% with last = layers | last -%}
    ---
    -- Network output
    signal  so: std_logic;
    signal ado: std_logic_vector({{ last.logn }}-1 downto 0);
    signal eno: std_logic;
    {%- endwith %}
begin
    ---
    -- DUT
    dut: entity work.top
    port map (
        rst => rst, clk => clk,
        so => so, ado => ado, eno => eno
    );

    -- Testbench signals
    rst <= '1', '0' after 0.25 * period, '1' after 2*period;
    clk <= not clk after period/2;

end arch;