library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- Weight data
use work.{{ weights }}.all;

entity {{ name }} is
generic (
    m: natural := {{ logm }}    -- # synapses = 2^m
    n: natural := {{ logn }};   -- # neurons  = 2^n
);
port (
    rst:  in  std_logic;
    clk:  in  std_logic;

    -- Input
    tick: in  std_logic;
    addr: out std_logic_vector(m-1 downto 0);
    rdi:  out std_logic;
    si:   in  std_logic;

    -- Output
    so:   out std_logic_vector(2**n-1 downto 0);
    eo:   out std_logic
);
end {{ name }};

architecture arch of {{ name }} is
    ---
    -- Neuron data
    type neuron_state_t is record
        u: signed(15 downto 0);
    end record;

    -- 1 - Input spike processing
    function vsyn(x: neuron_state_t; s0: std_logic)
    return neuron_state_t is
        variable xg:    neuron_state_t;
        constant urest: signed(15 downto 0) := to_signed(-64,  16);
    begin
        -- Default - no spiking
        xg := x;

        -- Virtual synapse
        if s0 = '1' then
            xg.u := urest;
        end if;

        return xg;
    end function;

    function isyn(x: neuron_state_t; s: std_logic; w: signed(15 downto 0))
    return neuron_state_t is
        variable xg: neuron_state_t;
    begin
        -- Default - no spiking
        xg := x;

        if s = '1' then
            xg.u := xg.u + w;
        end if;

        return xg;
    end function;

    -- 2 - Advance neuron dynamics
    function dyn(xg: neuron_state_t)
    return neuron_state_t is
        variable dx:    neuron_state_t;
        variable xs:    neuron_state_t;
        constant urest: signed(15 downto 0) := to_signed(-64,  16);
    begin
        -- Default - no change
        xs := xg;

        -- d/dt
        dx.u := shift_right(-(xg.u - urest), 5);

        -- Solver
        xs.u := xg.u + dx.u;

        return xs;
    end function;

    -- 3 - Generate output spike
    function spike(xs: neuron_state_t)
    return std_logic is
        variable spike: std_logic;
        constant uth: signed(15 downto 0) := to_signed(8192, 16);
    begin
        -- Default
        spike := '0';

        if xs.u > uth then
            spike := '1';
        end if;

        return spike;
    end function;

    ---
    -- Memories

    -- x
    type x_mem_t is array (0 to 2**n-1) of neuron_state_t;
    signal x_mem: x_mem_t := (others => (u => (others => '0')));
    signal x_in, x_out: neuron_state_t;

    -- s0
    type s0_mem_t is array (0 to 2**n-1) of std_logic;
    signal s0_mem: s0_mem_t := (others => '0');
    signal s0_in, s0_out: std_logic;

    -- w
    type w_mem_t   is array (0 to 2**n-1) of signed(15 downto 0);
    type w_group_t is array (0 to 2**m-1) of w_mem_t;
    type w_ports_t is array (w_group_t'range) of signed(15 downto 0);

    impure function rand_w(min_val, max_val: integer) return w_group_t is
        variable s: signed(15 downto 0) := (others => '0');
        variable w: w_group_t;
    begin
        for i in w_group_t'range loop
            for j in w_mem_t'range loop
                w(i)(j) := resize(resize(s, 14), 16);
                s := s + to_signed(12435, 16);
            end loop;
        end loop;

        return w;
    end function;

    signal w_group:     w_group_t := rand_w(-1024, 1024);
    signal w_in, w_out: w_ports_t;
    signal w_wr: std_logic;

    -- Ctrl
    type rd_array_t is array (w_group_t'range) of std_logic;
    signal srd, rd, wr: std_logic;

    ---
    -- Neuron core
    type spike_input_array_t is array (0 to 2**m-1) of std_logic;
    type neuron_state_array_t is array (0 to 2**m-1) of neuron_state_t;
    type neuron_counter_array_t is array (neuron_state_array_t'range) of unsigned(n-1 downto 0);
    type core_state_t is (idle, sim);
    type core_state_array_t is array (0 to 2**m-1) of core_state_t;
    type reg_t is record
        ---
        -- Pipeline

        -- Neuron counter
        nc:  unsigned(n-1 downto 0);
        -- Synapse counter
        sc:  unsigned(m-1 downto 0);
        -- Virtual synapse
        csv: core_state_t;
        rdv: std_logic;
        srdv: std_logic;
        nv:  unsigned(n-1 downto 0);
        -- Synapses
        csg: core_state_array_t;
        rdg:  rd_array_t;
        srdg: rd_array_t;
        sig: spike_input_array_t;
        ng:  neuron_counter_array_t;
        xg:  neuron_state_array_t;
        -- Neuron dynamics
        csd: core_state_t;
        nd:  unsigned(n-1 downto 0);
        xd:  neuron_state_t;
        -- Spike generation
        css: core_state_t;
        ns:  unsigned(n-1 downto 0);
        xs:  neuron_state_t;

        ---
        -- Output
        so: std_logic_vector(2**n-1 downto 0);
        eo: std_logic;
    end record;
    signal rn, rr: reg_t;
begin

    ---
    -- Neuron core state
    ncs: process (rst, clk)
    begin
        if rst = '0' then
            rr <= (
                nc  => (others => '0'),
                sc  => (others => '0'),
                -- Virtual synapse
                csv => idle,
                rdv => '0',
                srdv => '0',
                nv  => (others => '0'),
                -- Synapses
                csg => (others => idle),
                rdg => (others => '0'),
                srdg => (others => '0'),
                sig => (others => '0'),
                ng  => (others => (others => '0')),
                xg  => (others => (others => (others => '0'))),
                -- Neuron dynamics
                csd => idle,
                nd  => (others => '0'),
                xd  => (others => (others => '0')),
                -- Spike generation
                css => idle,
                ns  => (others => '0'),
                xs  => (others => (others => '0')),
                -- Output
                so  => (others => '0'),
                eo  => '0'
            );
        elsif rising_edge(clk) then
            rr <= rn;
        end if;
    end process;

    ncsdp: process (
        -- Registers / Pipeline
        rn, rr,
        -- Inputs
        tick, si,
        -- Memory
        x_out, s0_out, w_out,
        -- Signals
        rd, srd
    )
    begin
        -- Default
        rn    <= rr;
        rn.eo <= '0';

        -- Spike input control
        rdi <= '0';
        srd <= '0';

        -- Memory control
        rd <= '0';
        wr <= '0';

        -- Fetch input spikes
        if tick = '1' and rr.sc = 0 then
            -- Start counting
            rn.sc <= rr.sc + 1;
            rdi   <= '1';
            srd   <= '1';
        elsif rr.sc > 0 then
            -- Keep counting
            rn.sc <= rr.sc + 1;
            rdi   <= '1';
        end if;

        -- Propagate spike input read
        rn.srdv <= srd;

        -- Fetch neuron info
        if tick = '1' and rr.nc = 0 then
            -- Reset output
            rn.so  <= (others => '0');
            -- Start counting
            rn.nc  <= rr.nc + 1;
            -- Propagate counter
            rn.csv <= sim;
            rn.nv  <= rr.nc;
            -- Fetch neuron state
            rd     <= '1';
        elsif rr.nc > 0 then
            -- Keep counting
            rn.nc  <= rr.nc + 1;
            -- Propagate counter
            rn.nv  <= rr.nc;
            -- Keep fetching
            rd     <= '1';
        elsif rr.nc = 0 then
            rn.csv <= idle;
        end if;

        -- Propagate weight fetch
        rn.rdv <= rd;

        -- Virtual synapse
        rn.csg(0) <= rr.csv;
        if rr.csv = sim then
            rn.rdg(0)  <= rr.rdv;
            rn.srdg(0) <= rr.srdv;
            if rr.srdv = '1' then
                rn.sig(0) <= si;
            end if;
            rn.ng(0)   <= rr.nv;
            rn.xg(0)   <= vsyn(x_out, s0_out);
        end if;

        -- Input synapses
        for i in 0 to rr.csg'length-2 loop
            rn.csg(i+1) <= rr.csg(i);
        end loop;
        rn.csd <= rr.csg(rr.csg'length-1);

        for i in 0 to rr.ng'length-2 loop
            if rr.csg(i) = sim then
                rn.rdg(i+1) <= rr.rdg(i);
                rn.srdg(i+1) <= rr.srdg(i);
                if rr.srdg(i) = '1' then
                    rn.sig(i+1) <= si;
                end if;
                rn.ng(i+1)  <= rr.ng(i);
                rn.xg(i+1)  <= isyn(rr.xg(i), rr.sig(i), w_out(i));
            end if;
        end loop;
        rn.nd <= rr.ng(rr.ng'length-1);
        rn.xd <= isyn(rr.xg(rr.xg'length-1), rr.sig(rr.sig'length-1), w_out(rr.xg'length-1));

        -- Neuron dynamics
        rn.css <= rr.csd;
        if rr.csd = sim then
            rn.ns <= rr.nd;
            rn.xs <= dyn(rr.xd);
        end if;

        -- Spike generation
        x_in  <= rr.xs;
        s0_in <= spike(rr.xs);

        if rr.css = sim then
            rn.so(to_integer(rr.ns)) <= spike(rr.xs);

            -- Writeback
            wr <= '1';

            -- End tick
            if rn.css = idle then
                rn.eo <= '1';
            end if;
        end if;
    end process;

    ---
    -- Neuron memories
    mem: process (clk)
    begin
        if rising_edge(clk) then
            -- Fetch
            if rd = '1' then
                x_out  <= x_mem(to_integer(rr.nc));
                s0_out <= s0_mem(to_integer(rr.nc));
            end if;
            if wr = '1' then
                x_mem(to_integer(rr.ns))  <= x_in;
                s0_mem(to_integer(rr.ns)) <= s0_in;
            end if;
        end if;
    end process;

    ---
    -- Weight memories
    w_wr <= not rst;
    wmemg: for i in w_group'range generate
        wmem: process (clk)
        begin
            if rising_edge(clk) then
                -- Input spikes
                if rn.rdg(i) = '1' then
                    w_out(i) <= w_group(i)(to_integer(rn.ng(i)));
                end if;
            end if;
        end process;
    end generate;

    ---
    -- Outputs
    addr <= std_logic_vector(rr.sc);
    so   <= rr.so;
    eo   <= rr.eo;

end arch;
