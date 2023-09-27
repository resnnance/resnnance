library ieee;
use ieee.std_logic_1164.all;

entity {{ entity_name }} is
generic (
    depth: natural
);
port (
    rst: in std_logic;
    clk: in std_logic;

    ---
    -- Downstream memory
    dnmem_raddr: out std_logic_vector((depth-2)-1 downto 0);
    dnmem_rd:    out std_logic;
    dnmem_out:   in  std_logic_vector(31 downto 0);

    ---
    -- Registers
    ctrl:   in  std_logic_vector(31 downto 0);
    status: out std_logic_vector(31 downto 0);
    y:      out std_logic_vector(31 downto 0);
    sen:    out std_logic
);
end {{ entity_name }};

architecture arch of {{ entity_name }} is
begin

end arch;
