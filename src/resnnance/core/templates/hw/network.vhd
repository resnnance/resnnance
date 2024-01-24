library ieee;
use ieee.std_logic_1164.all;

entity {{ name }} is
port (
    rst:  in std_logic;
    clk:  in std_logic;
    tick: in std_logic;

    {% with last = layers | last -%}
    ---
    -- Network output
     si: out std_logic;
    adi: in  std_logic_vector({{ last.logn }}-1 downto 0);
    eni: in  std_logic
    {%- endwith %}
);
end {{ name }};

architecture arch of {{ name }} is
    ---
    -- Layers
    {%- for layer in layers %}
    
    -- {{ layer.label }}
    {%- if not loop.first %}
    signal  si_{{ layer.label }}: std_logic;
    signal adi_{{ layer.label }}: std_logic_vector({{ loop.previtem.logn }}-1 downto 0);
    signal eni_{{ layer.label }}: std_logic;
    {% endif %}
    signal  so_{{ layer.label }}: std_logic;
    signal ado_{{ layer.label }}: std_logic_vector({{ layer.logn }}-1 downto 0);
    signal eno_{{ layer.label }}: std_logic;
    {%- endfor %}
begin

    -- Layers
    {%- for layer in layers %}
    {{ layer.label }}: entity work.{{ layer.label }}_core
    port map (
        rst => rst, clk => clk, tick => tick,
        {% if not loop.first %}
        -- Input
        si  =>  si_{{ layer.label }},
        adi => adi_{{ layer.label }},
        eni => eni_{{ layer.label }},
        {% endif %}
        -- Output
        so  =>  so_{{ layer.label }},
        ado => ado_{{ layer.label }},
        eno => eno_{{ layer.label }}
    );
    {% endfor %}

    -- Memory
    mem: entity work.memory
    port map (
        clk => clk,
        {%- for layer in layers %}
        
        ---
        -- {{ layer.label }}
        {% if not loop.first %}
        -- Input
         si_{{ layer.label }} =>  si_{{ layer.label }},
        adi_{{ layer.label }} => adi_{{ layer.label }},
        eni_{{ layer.label }} => eni_{{ layer.label }},
        {% endif %}
        -- Output
         so_{{ layer.label }} =>  so_{{ layer.label }},
        ado_{{ layer.label }} => ado_{{ layer.label }},
        eno_{{ layer.label }} => eno_{{ layer.label }},
        {%- endfor %}
        si => si, adi => adi, eni => eni
    );

end arch;