library ieee;
use ieee.std_logic_1164.all;

entity {{ name }} is
port (
    rst:  in  std_logic;
    clk:  in  std_logic;
    tick: out std_logic;

    so:   out std_logic;
    {%- with last = layers | last %}
    ado:  in  std_logic_vector({{ last.logn }}-1 downto 0);
    {%- endwith %}
    eno:  in  std_logic
);
end {{ name }};

architecture arch of {{ name }} is
    -- Simtick
    signal tick: std_logic;

    -- Layers
    {%- for layer in layers %}
    signal so_{{ layer.label }}: std_logic;
    {%- endfor %}
    {% for layer in layers %}
    signal ado_{{ layer.label }}: std_logic_vector({{ layer.logn }}-1 downto 0);
    {%- endfor %}
    {% for layer in layers %}
    signal eno_{{ layer.label }}: std_logic;
    {%- endfor %}
begin

    -- Simtick
    simtick: entity work.simtick
    port map (
        rst => rst, clk => clk, tick => tick
    )

    -- Layers
    {%- for layer in layers %}
    {{ layer.label }}: entity work.{{ layer.label }}_core
    port map (
        rst => rst, clk => clk, tick => tick,
        {% if not loop.first %}
        -- Input
        si  =>  so_{{ loop.previtem.label }},
        adi => ado_{{ loop.previtem.label }},
        eni => eno{{ loop.previtem.label }},
        {% endif %}
        -- Output
        {%- if not loop.last %}
        so  =>  so_{{ layer.label }},
        ado => ado_{{ layer.label }},
        eno => eno_{{ layer.label }}
        {%- else %}
        so  =>  so,
        ado => ado,
        eno => eno
        {%- endif %}
    )
    {% endfor %}
end arch;
