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

    ---
    -- LFSR
    function fibonacci(lr: std_logic_vector)
    return std_logic_vector is
        ---
        -- Galois 16-bit LSFR primitive polynomial
        --
        -- (The independent term is not considered when encoding
        -- the polynomial into the following constant)
        --
        -- p(x) = x^16 + x^15 + x^13 +  x^4 + 1 = x"D008"
        constant poly: std_logic_vector(lr'range) := x"D008";
        variable ln:   std_logic_vector(lr'range);
    begin
        -- Shift
        for i in ln'length-2 downto 0 loop
            ln(i) := lr(i+1);
        end loop;

        -- Feedback
        ln(ln'length-1) := '0';
        for i in poly'range loop
            if poly(i) = '1' then
                ln(ln'length-1) := ln(ln'length-1) xor lr(lr'left-i);
            end if;
        end loop;

        return ln;
    end function;

    constant seed: std_logic_vector(w-1 downto 0) := x"0001";   -- Can't be zero

    ---
    -- Registers
    type state_t is (idle, running);
    type reg_t is record
        state: state_t;
        addr:  unsigned(n-1 downto 0);
        lfsr:  std_logic_vector(w-1 downto 0);
    end record;
    signal rn, rr: reg_t;
begin

    ---
    -- Registers
    reg: process (rst, clk)
    begin
        if rst = '0' then
            rr <= (
                state => idle,
                addr  => (others => '0'),
                lfsr  => seed
            );
        elsif rising_edge(clk) then
            rr <= rn;
        end if;
    end process;

    ---
    -- Datapath
    dp: process (tick, rr)
    begin
        -- Default
        rn     <= rr;
        mem_rd <= '0';
        mem_wr <= '0';

        -- State-independent connections
        mem_input_addr <= to_integer(rr.addr);
        mem_spike_addr <= to_integer(rr.addr);

        -- Spike generation
        if unsigned(rr.lfsr) < mem_input_out then
            -- Big output, bigger chance of spike
            mem_spike_in <= '1';
        else 
            mem_spike_in <= '0';
        end if;

        case rr.state is
            when idle =>
                -- NSL
                if tick = '1' then
                    rn.state <= running;
                end if;
            when running =>
                -- NSL
                if rr.addr + 1 = 0 then
                    rn.state <= idle;
                end if;

                mem_rd  <= '1';
                mem_wr  <= '1';
                rn.addr <= rr.addr + 1;
                rn.lfsr <= fibonacci(rr.lfsr);
        end case;
    end process;

    ---
    -- Input memory
    mem_input_ram: process (clk)
    begin
        if rising_edge(clk) then
            if mem_rd = '1' then
                mem_input_out <= mem_input(mem_input_addr);
            end if;
        end if;
    end process;

    ---
    -- Spike memory
    mem_spike_ram: process (clk)
    begin
        -- Dual port
        if rising_edge(clk) then
            -- Input side
            if mem_wr = '1' then
                mem_spike(mem_spike_addr) <= mem_spike_in;
            end if;
            -- Output side
            if rso = '1' then
                so <= mem_spike(to_integer(unsigned(aso)));
            end if;
        end if;
    end process;

end arch;