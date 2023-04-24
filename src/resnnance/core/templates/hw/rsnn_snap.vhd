--
-- {{ entity_name }}
--

library ieee;
use ieee.std_logic_1164.all;

entity {{ entity_name }} is
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
end {{ entity_name }};

architecture arch of {{ entity_name }} is
begin
    {{ arch_description }}
end arch;
