---
-- {{ name }}.vhd
--
-- Conv2D layer
--
-- params:
--      'name':   self.label
--      'weights': self.label + "_weights"
--      'logm': self.get_logm(),
--      'logn': self.get_logn(),
--      'syn': self.__get_synapses(),
--      'n': self.input_shape,          # (ny, nx, nz)
--      'k': self.kernel_shape,         # (ky, kx, 1, f)
--      'p': self.padding,
--      's': self.strides,              # (sy, sx)
--      'm': self.__get_output_shape(), # (my, mx, f)
--      'l': self.__get_lbuffer_len()   # l
---

---
-- {{ name }}
--
-- Input shape:  ({{ n[0] }}, {{ n[1] }}, {{ n[2] }})
-- Kernel shape: ({{ k[0] }}, {{ k[1] }}, {{ k[2] }}) x {{ k[3] }} kernels
-- Output shape: ({{ m[0] }}, {{ m[1] }}, {{ m[2] }})
---

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Kernel data
use work.{{ weights }}.all;

entity {{ name }} is
generic (
    m: natural := {{ logm }};   -- # synapses = 2^m
    n: natural := {{ logn }}    -- # neurons  = 2^n
);
port (
    rst:  in  std_logic;
    clk:  in  std_logic;
    tick: in  std_logic;

    -- Input
    asi:  out std_logic_vector(m-1 downto 0);
    rsi:  out std_logic;
    si:   in  std_logic;

    -- Output
    aso: in  std_logic_vector(n-1 downto 0);
    rso: in  std_logic;
    so:  out std_logic
);
end {{ name }};

architecture arch of {{ name }} is
    constant l:   natural := {{ l }}; -- Line buffer length
    constant syn: natural := {{ syn }}; -- Number of synapses

    type line_buf_t is array (0 to l-1) of std_logic;
    signal ln, lr: line_buf_t;

    type state_t is (idle, running);
    type reg_t is record
        state: state_t;
        asi:   unsigned(m-1 downto 0);
    end record;
    signal rn, rr: reg_t;
begin

    ---
    -- Line buffer
    lb: process (rst, clk)
    begin
        if rst = '0' then
            lr <= (others => '0');
        elsif rising_edge(clk) then
            lr <= ln;
        end if;
    end process;

    ---
    -- Registers
    reg: process (rst, clk)
    begin
        if rst = '0' then
            rr <= (
                state => idle,
                asi   => (others => '0')
            );
        elsif rising_edge(clk) then
            rr <= rn;
        end if;
    end process;

    ---
    -- Datapath
    dp: process (rr, lr, tick)
    begin
        -- Default
        ln <= lr;
        rn <= rr;

        -- Outputs
        asi <= std_logic_vector(rr.asi);
        rsi <= '0';

        if rr.state = idle then
            if tick = '1' then
                rn.state <= running;
                rn.asi   <= (others => '0');
            end if;
        elsif rr.state = running then
            -- Read input values
            rsi <= '1';

            -- Sweep input synapse addresses
            if rr.asi + 1 = syn then
                rn.asi   <= (others => '0');
                rn.state <= idle;
            else
                rn.asi <= rr.asi + 1;
            end if;
        end if;

    end process;

end arch;