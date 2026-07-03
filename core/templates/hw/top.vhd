library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
port (
    rst: in  std_logic;
    clk: in  std_logic;

    {% with last = layers | last -%}
    ---
    -- Network output
    so:  out std_logic;
    ado: in  std_logic_vector({{ last.logn }}-1 downto 0);
    eno: in  std_logic
    {%- endwith %}
);
end top;

architecture arch of top is
    signal tick: std_logic;

    {% with first = layers | first -%}
    ---
    -- Network input
    signal si:  std_logic;
    signal adi: std_logic_vector({{ first.logm }}-1 downto 0);
    signal eni: std_logic;
    {%- endwith %}
begin

    ---
    -- Tick base
    simtick: entity work.simtick
    generic map(
        tclk => 10 ns,
        dt => 10 us
    )
    port map (
        rst => rst, clk => clk, tick => tick
    );

    ---
    -- DUT
    network: entity work.network
    port map (
        rst => rst, clk => clk, tick => tick,
        si => si, adi => adi, eni => eni,
        so => so, ado => ado, eno => eno
    );

end arch;
