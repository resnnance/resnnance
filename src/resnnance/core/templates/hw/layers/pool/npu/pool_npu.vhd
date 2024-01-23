---
-- {{ name }}_npu.vhd
--
-- Pooling layer - Neuron Processing Unit
--
-- params:
--      'name': self.label
---

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.{{ name }}_npu_aux.all;
use work.{{ name }}_config.all;

entity {{ name }}_npu is
port (
    rst: in std_logic;
    clk: in std_logic;

    sr:   in  std_logic_vector(0 to pool_p-1);
    adr:  in  std_logic_vector(pool_logn-1 downto 0);
    wadr: in  std_logic_vector(pool_logn-1 downto 0);
    enr:  in  std_logic;

    so:   out std_logic;
    ado:  out std_logic_vector(pool_logn-1 downto 0);
    eno:  out std_logic
);
end entity;

architecture arch of {{ name }}_npu is
    ---
    -- Memories

    -- x
    type x_mem_t is array (0 to pool_n-1) of x_t;
    signal x_mem:       x_mem_t := (others => (others => '0'));
    signal x_in, x_out: x_t;
    signal x_wr, x_rd:  std_logic;
    signal x_wa, x_ra:  natural range x_mem_t'range;

    -- so
    type so_mem_t is array (0 to pool_n-1) of std_logic;
    signal so_mem:        so_mem_t := (others => '0');
    signal so_in, so_out: std_logic;
    signal so_wr, so_rd:  std_logic;
    signal so_wa, so_ra:  natural range so_mem_t'range;

    -- w
    signal w_out: w_t := weight_conv(pool_w);

    ---
    -- Pipeline
    type xp_t is array (0 to pool_p-1) of x_t;
    type ap_t is array (0 to pool_p-1) of natural range x_mem_t'range;
    type wp_t is array (0 to pool_p-1) of natural range w_mem_t'range;
    type ep_t is array (0 to pool_p-1) of std_logic;

    type p_t is record
        -- Virtual synapse
        xv: x_t;
        av: natural range x_mem_t'range;
        ev: std_logic;

        -- Synapses
        xp: xp_t;
        ap: ap_t;
        ep: ep_t;

        -- Sync
        ab: natural range x_mem_t'range;
        eb: std_logic;

        -- Dynamics
        xd: x_t;
        ad: natural range x_mem_t'range;
        ed: std_logic;

        -- Spike generation
        ss: std_logic;
        as: natural range x_mem_t'range;
        es: std_logic;
    end record;
    signal pn, pr: p_t;
begin

    ---
    -- Memories
    mem: process (clk)
    begin
        if rising_edge(clk) then
            -- x
            if x_rd = '1' then
                x_out <= x_mem(x_ra);
            end if;
            if x_wr = '1' then
                x_mem(x_wa) <= x_in;
            end if;

            -- so
            if so_rd = '1' then
                so_out <= so_mem(so_ra);
            end if;
            if so_wr = '1' then
                so_mem(so_wa) <= so_in;
            end if;
        end if;
    end process;

    ---
    -- Pipeline
    pipe: process (rst, clk)
    begin
        if rst = '0' then
            pr.ev <= '0';
            pr.ep <= (others => '0');
            pr.eb <= '0';
            pr.ed <= '0';
            pr.es <= '0';
        elsif rising_edge(clk) then
            pr <= pn;
        end if;
    end process;

    ---
    -- Datapath
    dp: process (
        pr,
        sr, adr, wadr, enr,
        x_out, so_out, w_out
    )
    begin
        -- Default
        pn <= pr;

        ---
        -- Neurons
        pn.xv    <= gv(x_out, so_out);
        pn.xp(0) <= gi(pr.xv, sr(0), w_out);
        for i in 0 to pr.xp'length-2 loop
            pn.xp(i+1) <= gi(pr.xp(i), sr(i+1), w_out);
        end loop;
        pn.xd    <= dyn(pr.xp(pr.xp'length-1));
        pn.ss    <= h(pr.xd);
        so       <= pr.ss;  -- Output spike

        ---
        -- Addresses
        pn.av    <= to_integer(unsigned(adr));
        pn.ap(0) <= pr.av;
        for i in 0 to pr.ap'length-2 loop
            pn.ap(i+1) <= pr.ap(i);
        end loop;
        pn.ab    <= pr.ap(pr.ap'length-1);
        pn.ad    <= pr.ab;
        pn.as    <= pr.ad;
        ado      <= std_logic_vector(to_unsigned(pr.as, ado'length));  -- Output address

        ---
        -- Enables
        pn.ev    <= enr;
        pn.ep(0) <= pr.ev;
        for i in 0 to pr.ep'length-2 loop
            pn.ep(i+1) <= pr.ep(i);
        end loop;
        pn.eb    <= pr.ep(pr.ep'length-1);
        pn.ed    <= pr.eb;
        pn.es    <= pr.ed;
        eno      <= pr.es;  -- Output enable

        ---
        -- Reads
        x_ra  <= to_integer(unsigned(adr));
        x_rd  <= enr;

        so_ra <= to_integer(unsigned(adr));
        so_rd <= enr;

        ---
        -- Writeback
        x_in  <= pr.xd;
        x_wa  <= pr.ad;
        x_wr  <= pr.ed;

        so_in <= h(pr.xd);
        so_wa <= pr.ad;
        so_wr <= pr.ed;
    end process;

end architecture;