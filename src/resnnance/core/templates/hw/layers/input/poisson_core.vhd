library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.{{ name }}_aux.all;

entity {{ name }}_core is
port (
    rst:  in  std_logic;
    clk:  in  std_logic;

    tick: in  std_logic;

    so:   out std_logic;
    ado:  out std_logic_vector(logn-1 downto 0);
    eno:  out std_logic
);
end entity;

architecture arch of {{ name }}_core is
    signal mem: mem_t(0 to n-1) := numpy2vhd("mnist.txt", n);
    signal wra, rda: unsigned(logn-1 downto 0);
    signal wrd, rdd: unsigned(w-1 downto 0);
    signal wr,  rd:  std_logic;

    --constant poly:     natural := 16#B8#;
    --constant poly_w:   natural := 8;
    constant poly:     natural := 16#D008#;
    constant poly_w:   natural := 16;
    constant poly_slv: std_logic_vector(poly_w-1 downto 0) := std_logic_vector(to_unsigned(poly, poly_w));

    type state_t is (idle, run);
    type reg_t is record
        state: state_t;
        addr:  unsigned(logn-1 downto 0);
        saddr: unsigned(logn-1 downto 0);
        rd:    std_logic;
        lfsr:  std_logic_vector(poly_w-1 downto 0);
    end record;
    signal rn, rr: reg_t;
begin

    ---
    -- Input memory
    inmem: process (clk)
    begin
        if rising_edge(clk) then
            if wr = '1' then
                mem(to_integer(wra)) <= wrd;
            end if;
            if rd = '1' then
                rdd <= mem(to_integer(rda));
            end if;
        end if;
    end process;

    ---
    -- Registers
    reg: process (rst, clk)
    begin
        if rst = '0' then
            rr <= (
                state => idle,
                addr  => (others => '0'),
                saddr => (others => '0'),
                rd    => '0',
                lfsr  => (0 => '1', others => '0')
            );
        elsif rising_edge(clk) then
            rr <= rn;
        end if;
    end process;

    ---
    -- Datapath
    dp: process (rr, tick, rdd, rd)
        function fibonacci(lr: std_logic_vector) return std_logic_vector is
            variable feedback: std_logic;
            variable ln: std_logic_vector(lr'range);
        begin
            feedback := '0';

            for i in 0 to lr'left loop
                if poly_slv(i) = '1' then
                    feedback := feedback xor lr(i);
                end if;
            end loop;

            ln(ln'left downto 1) := lr(lr'left-1 downto 0);
            ln(0) := feedback;

            return ln;
        end function;

        function spike(pixel: unsigned; rand: unsigned; s: natural) return boolean is
            variable lambda: natural;
            variable p:      unsigned(rand'range);
            variable spike:  boolean;
        begin
            lambda := rand'length - pixel'length - s;
            p      := shift_left(resize(pixel, rand'length), lambda);     -- p = 2^lambda * pixel
            
            if p >= rand then
                spike := true;
            else
                spike := false;
            end if;

            return spike;
        end function;
    begin
        -- Defaults
        rn <= rr;

        -- Input memory defaults
        wra <= (others => '0');
        wrd <= (others => '0');
        wr  <= '0';
        rda <= rr.addr;
        rd  <= '0';

        so <= '0';
        ado <= std_logic_vector(rr.saddr);
        eno <= rr.rd;

        -- Pseudo-pipeline
        rn.rd    <= rd;
        rn.saddr <= rr.addr;

        if rr.state = idle then
            -- Idle
            rn.addr <= (others => '0');

            if tick = '1' then
                rd       <= '1';
                rn.addr  <= rr.addr + 1;
                rn.lfsr  <= fibonacci(rr.lfsr);
                rn.state <= run;
            end if;
        else
            -- Running
            rd      <= '1';
            rn.lfsr <= fibonacci(rr.lfsr);

            if rr.addr < n - 1 then
                rn.addr <= rr.addr + 1;
            else
                rn.addr  <= (others => '0');
                rn.state <= idle;
            end if;
            
            ---
            -- Conversion
            --
            -- P(1 spike during dt) = rate * dt = p
            -- 
            -- if (p >= x), x = Uniform random number [0, 1] => Spike
            --
            --if spike(rdd, unsigned(rr.lfsr), 7) then  -- 100 us
            if spike(rdd, unsigned(rr.lfsr), 4) then    -- 1 ms
                so <= '1';
            end if;
        end if;
    end process;

end architecture;
