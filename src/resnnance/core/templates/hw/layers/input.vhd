---
-- input.vhd
--
-- params:
--      'name':    self.label
--      'weights': self.label + "_weights"
--      'logn':    int(np.ceil(np.log2(self.weights.shape[1]))),
---
--
-- {{ name }}
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Weight data
use work.{{ weights }}.all;

entity {{ name }} is
generic (
    n: natural := {{ logn }}    -- # neurons  = 2^n
);
port (
    rst:  in  std_logic;
    clk:  in  std_logic;
    tick: in  std_logic;

    -- Output
    aso: in  std_logic_vector(n-1 downto 0);
    rso: in  std_logic;
    so:  out std_logic
);
end {{ name }};

architecture arch of {{ name }} is
    signal mem_input: mem_input_t := {{ weights }}_vector;
    signal mem_input_addr: natural range mem_input_t'range;
    signal mem_input_in, mem_input_out: unsigned(w-1 downto 0);
    signal mem_rd: std_logic;

    signal mem_spike: mem_spike_t := (others => '0');
    signal mem_spike_addr: natural range mem_spike_t'range;
    signal mem_spike_in, mem_spike_out: std_logic;
    signal mem_wr: std_logic;

    alias naso: natural range mem_spike_t'range is to_integer(unsigned(aso));

    ---
    -- LFSR

    -- Galois 16-bit LSFR primitive polynomial
    -- p(x) = x^16 + x^14 + x^13 + x^11 + 1
    --
    -- (The independent term is not considered when encoding
    -- the polynomial into the following digital signal, and
    -- the highest order term should also be ignored)
    constant poly: std_logic_vector(w-1 downto 0) := x"B400"
    constant seed: std_logic_vector(w-1 downto 0) := x"FFFF"    -- Can't be zero
    signal ln, lr: std_logic_vector(w-1 downto 0);
begin

    ---
    -- LFSR
    lfsr_reg: process (rst, clk)
    begin
        if rst = '0' then
            lr <= seed;
        elsif rising_edge(clk) then
            lr <= ln;
        end if;
    end process

    lfsr_dp: process (lr)
    begin
        -- Polynomial xor'ing
        for i in lr'length-2 downto 0 loop:
            if poly(i) = '1' then
                ln(i) <= lr(i+1) xor lr(0);
            else
                ln(i) <= lr(i+1);
            end if;
        end loop;

        -- Polynomial independent term
        ln(w-1) <= lr(0);
    end process;

    ---
    -- Input memory
    mem_input: process (clk)
    begin
        if rising_edge(clk) then
            if mem_rd == '1' then
                mem_input_out <= mem_input(mem_input_addr);
            end if;
        end if;
    end process;

    ---
    -- Spike memory
    mem_spike: process (clk)
    begin
        -- Dual port
        if rising_edge(clk) then
            -- Input side
            if mem_wr == '1' then
                mem_spike(mem_spike_addr) <= mem_spike_in;
            end if;
            -- Output side
            if rso == '1' then
                so <= mem_spike(naso);
            end if;
        end if;
    end process;

end arch;