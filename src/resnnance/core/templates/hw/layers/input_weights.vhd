library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package {{ name }} is
    constant n: integer := {{ n }};     -- Outputs / weights

    constant w: natural := 16;          -- Weight bit width
    type mem_input_t is array (0 to 2**n-1) of unsigned(w-1 downto 0);
    type mem_spike_t is array (0 to 2**n-1) of std_logic;

    constant {{ name }}_vector: mem_input_t;
end {{ name }};