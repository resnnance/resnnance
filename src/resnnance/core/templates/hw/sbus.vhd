library ieee;
use ieee.std_logic_1164.all;

package sbus is

---
-- Bus definition
type sbus_dn_t is record
    addr:  std_logic_vector(31 downto 0);
    wdata: std_logic_vector(31 downto 0);
    wmask: std_logic_vector(3 downto 0);
    rstb:  std_logic;
end record;
type sbus_up_t is record
    rdata: std_logic_vector(31 downto 0);
end record;
type sbus_dn_array_t is array (natural range <>) of sbus_dn_t;
type sbus_up_array_t is array (natural range <>) of sbus_up_t;

---
-- Bus configuration
type sbus_slave_config_t is record
    baddr:  natural;
    length: natural;
end record;
type sbus_config_t is array (natural range <>) of sbus_slave_config_t;

end sbus;
