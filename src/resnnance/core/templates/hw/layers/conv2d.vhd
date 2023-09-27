--
-- {{ name }}
--

library ieee;
use ieee.std_logic_1164.all;

entity {{ name }} is
{% if generics | length %}
generic (
    {{ generics }}
)
{% endif %}
{% if ports | length %}
port (
    {{ ports }}
)
{% endif %}
end {{ name }};

architecture arch of {{ name }} is
begin
    {{ arch_description }}
end arch;