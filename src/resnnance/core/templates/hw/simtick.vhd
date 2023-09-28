library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use ieee.math_real.ceil;
use ieee.math_real.log2;

entity simtick is
generic (
    tclk: time := 10 ns;
    dt:   time := 1 ms
);
port (
    rst:  in  std_logic;
    clk:  in  std_logic;
    tick: out std_logic
);
end simtick;

architecture arch of simtick is

    constant thresh:  integer := dt / tclk;
    constant w:       natural := natural(ceil(log2(real(thresh))));
    constant uthresh: unsigned(w-1 downto 0) := to_unsigned(thresh, w);

    signal n_next, n_reg: unsigned(w-1 downto 0);

begin

    ---
    -- Prescaler register
    dp: process (rst, clk)
    begin
        if rst = '0' then
            n_reg <= (others => '0');
        elsif rising_edge(clk) then
            n_reg <= n_next;
        end if;
    end process;

    ---
    -- Count
    dl: process (n_next, n_reg)
        variable n: unsigned(w-1 downto 0);
    begin
        n := n_reg + 1;
        tick <= '0';

        if n >= uthresh then
            n_next <= (others => '0');
            tick <= '1';
        else
            n_next <= n;
        end if;
    end process;

end arch;
