library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity network_tb is
end network_tb;

architecture arch of network_tb is
    constant period: time := 10 ns;

    signal rst:  std_logic := '0';
    signal clk:  std_logic := '0';
    signal tick: std_logic;
begin

    ---
    -- Tick base
    simtick: entity work.simtick
    generic map(
        tclk => period,
        dt => 200 us
    )
    port map (
        rst => rst, clk => clk, tick => tick
    );

    ---
    -- DUT
    dut: entity work.network
    port map (
        rst => rst, clk => clk, tick => tick
    );

    -- Testbench signals
    rst <= '1', '0' after 0.25 * period, '1' after 2*period;
    clk <= not clk after period/2;

end arch;