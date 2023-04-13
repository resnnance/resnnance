library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.sbus.all;

entity {{ entity_name }} is
generic (
    config: sbus_slave_config_t
    -- | baddr:  natural; (Example base address := 16#10000000#)
    -- | length: natural;
);
port (
    rst: in std_logic;
    clk: in std_logic;

    ---
    -- System bus

    sin: in sbus_dn_t;
    -- | addr:  std_logic_vector(31 downto 0);
    -- | wdata: std_logic_vector(31 downto 0);
    -- | wmask: std_logic_vector(3 downto 0);
    -- | rstb:  std_logic;

    sout: out sbus_up_t
    -- | rdata: std_logic_vector(31 downto 0);
);
end {{ entity_name }};

architecture arch of {{ entity_name }} is
    -- Bus address conversion
    subtype addr_t is natural range 0 to 2**(config.length-2)-1;
    signal addr: addr_t;

    ---
    -- RAM memories (downstream/upstream)
    constant mem_depth: natural := {{ mem_depth }};                 -- 2**mem_depth bytes
    subtype mem_addr_t is natural range 0 to 2**(mem_depth-2)-1;    -- 32-bit wide memory
    type mem_t is array (mem_addr_t) of std_logic_vector(31 downto 0);

    -- Memory
    signal dnmem: mem_t;

    -- Downstream RAM ports - System side
    signal dnmem_waddr: mem_addr_t;
    signal dnmem_wmask: std_logic_vector(3 downto 0);
    signal dnmem_in:    std_logic_vector(31 downto 0);

    -- Downstream RAM ports - Slave core side
    signal dnmem_raddr: std_logic_vector((mem_depth-2)-1 downto 0);
    signal dnmem_rd:    std_logic;
    signal dnmem_out:   std_logic_vector(31 downto 0);

    ---
    -- Signals
    signal status: std_logic_vector(31 downto 0);
    signal ctrl:   std_logic_vector(31 downto 0);
begin

    ---
    -- Slave address mapping check
    assert config.length >= mem_depth + 2 report "Memory mapping not big enough!" severity failure;

    ---
    -- RAM memories

    -- Downstream (master-to-slave) RAM memory
    dnmemp: process (clk)
    begin
        if rising_edge(clk) then
            -- Read from memory (slave)
            if dnmem_rd = '1' then
                dnmem_out <= dnmem(to_integer(unsigned(dnmem_raddr)));
            end if;

            -- Write to memory (master)
            -- Byte-wise access based on wmask
            if dnmem_wmask(0) = '1' then
                dnmem(dnmem_waddr)(7 downto 0)   <= dnmem_in(7 downto 0);
            end if;
            if dnmem_wmask(1) = '1' then
                dnmem(dnmem_waddr)(15 downto 8)  <= dnmem_in(15 downto 8);
            end if;
            if dnmem_wmask(2) = '1' then
                dnmem(dnmem_waddr)(23 downto 16) <= dnmem_in(23 downto 16);
            end if;
            if dnmem_wmask(3) = '1' then
                dnmem(dnmem_waddr)(31 downto 24) <= dnmem_in(31 downto 24);
            end if;
        end if;
    end process;

    ---
    -- Registers
    regp: process (rst, clk)
    begin
        if rst = '0' then
            rr <= (
                status => (others => '0'),
                y      => (others => '0')
            );
        elsif rising_edge(clk) then
            rr <= rn;
        end if;
    end process;

    ---
    -- Master-slave logic
    msl: process (sin, rr, status, y, sen)
        ---
        -- addr_within_bounds
        --
        -- Checks whether the system address bus is addressing this slave
        --
        -- Takes the address upper bits (based on the config.length setting)
        -- and compares them against the slave base address (config.baddr)
        function addr_within_bounds(sin: sbus_dn_t) return boolean is
            variable baup: unsigned(31 downto config.length);  -- Base address upper bits
            variable adup: unsigned(31 downto config.length);  -- Bus address upper bits
        begin
            -- Get base address upper bits
            baup := to_unsigned(config.baddr, 32)(31 downto config.length);
            -- Get address upper bits
            adup := unsigned(sin.addr(31 downto config.length));

            if baup = adup then
                return true;
            end if;

            return false;
        end function;

        ---
        -- addr_dnmem - Checks whether the system address bus is addressing the downstream RAM
        function addr_dnmem(sin: sbus_dn_t) return boolean is
        begin
            if unsigned(sin.addr(config.length-1 downto mem_depth)) = 0 then
                return true;
            end if;

            return false;
        end function;
        ---
        -- addr_ctrl - Checks whether the system address bus is addressing the control register
        function addr_ctrl(sin: sbus_dn_t) return boolean is
        begin
            if unsigned(sin.addr(config.length-1 downto mem_depth)) = 1 then
                return true;
            end if;

            return false;
        end function;
        ---
        -- addr_status - Checks whether the system address bus is addressing the status register
        function addr_status(sin: sbus_dn_t) return boolean is
        begin
            if unsigned(sin.addr(config.length-1 downto mem_depth)) = 2 then
                return true;
            end if;

            return false;
        end function;
        ---
        -- addr_y - Checks whether the system address bus is addressing the output register
        function addr_y(sin: sbus_dn_t) return boolean is
        begin
            if unsigned(sin.addr(config.length-1 downto mem_depth)) = 3 then
                return true;
            end if;

            return false;
        end function;
    begin
        -- Default
        rn <= rr;
        ctrl <= (others => '0');

        ---
        -- Bus address conversion

        -- Discard last 2 LSBs (because we are addressing 32-bit-long words, not bytes)
        -- Truncate upper bits based on slave memory map occupation @ config.length
        -- Cast bus address to natural
        addr <= to_integer(unsigned(sin.addr(config.length-1 downto 2)));

        ---
        -- Bus address
        dnmem_waddr <= to_integer(unsigned(sin.addr(mem_depth-1 downto 2)));

        ---
        -- Bus data
        dnmem_in <= sin.wdata;

        ---
        -- Bus read/write strobes

        -- Default
        dnmem_wmask <= (others => '0');
        sout.rdata  <= rr.status;

        if addr_within_bounds(sin) then
            -- Downstream memory
            if addr_dnmem(sin) then
                dnmem_wmask <= sin.wmask;
            end if;

            -- Downstream registers
            if addr_ctrl(sin) then
                if sin.wmask = "1111" then
                    ctrl <= sin.wdata;
                end if;
            end if;

            -- Upstream registers
            if addr_status(sin) then
                if sin.rstb = '1' then
                    sout.rdata <= rr.status;
                end if;
            end if;

            if addr_y(sin) then
                if sin.rstb = '1' then
                    sout.rdata <= rr.y;
                end if;
            end if;
        end if;

        ---
        -- Core status
        if sen = '1' then
            rn.status <= status;
            rn.y <= y;
        end if;
    end process;

    ---
    -- Slave core
    corep: entity work.{{ core_name }}
    generic map (
        depth => mem_depth
    )
    port map (
        rst => rst, clk => clk,
        -- Downstream memory
        dnmem_raddr => dnmem_raddr, dnmem_rd => dnmem_rd, dnmem_out => dnmem_out,
        -- Registers
        ctrl => ctrl, status => status, y => y, sen => sen
    );

end arch;
