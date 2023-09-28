library ieee;
use ieee.std_logic_1164.all;

entity {{ entity_name }} is
port (
    rst:  in  std_logic;
    clk:  in  std_logic;

    tick: out std_logic;
    so:   out std_logic;
    aso:  in  std_logic_vector(?? downto 0);
    rso:  in  std_logic
);
end {{ entity_name }};

architecture arch of {{ entity_name }} is
    -- Simtick
    signal tick: std_logic;

    -- Layers
    {%- for layer in layers %}
    signal so_{{ layer.label }}: std_logic;
    {%- endfor %}
    {% for layer in layers %}
    signal aso_{{ layer.label }}: std_logic_vector({{ layer.logn }} - 1 downto 0);
    {%- endfor %}
    {% for layer in layers %}
    signal rso_{{ layer.label }}: std_logic;
    {%- endfor %}
begin

    -- Simtick
    simtick: entity work.simtick
    port map (
        rst => rst, clk => clk, tick => tick
    )

    -- Layers
    {%- for layer in layers %}
    {{ layer.label }}: entity work.{{ layer.label }}
    port map (
        rst => rst, clk => clk, tick => tick,
        {% if not loop.first %}
        -- Input
        si  =>  so_{{ loop.previtem.label }},
        asi => aso_{{ loop.previtem.label }},
        rsi => rso_{{ loop.previtem.label }},
        {% endif %}
        -- Output
        {%- if not loop.last %}
        so  =>  so_{{ layer.label }},
        aso => aso_{{ layer.label }},
        rso => rso_{{ layer.label }}
        {%- else %}
        so  =>  so,
        aso => aso,
        rso => rso
        {%- endif %}
    )
    {% endfor %}
end arch;
