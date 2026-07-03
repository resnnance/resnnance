library ieee;
use ieee.std_logic_1164.all;

entity {{ name }} is
port (
    rst:  in std_logic;
    clk:  in std_logic;
    tick: in std_logic;

    {% with first = layers | first -%}
    ---
    -- Network input
     si: in  std_logic;
    adi: in  std_logic_vector({{ first.logm }}-1 downto 0);
    eni: in  std_logic;
    {%- endwith %}

    {% with last = layers | last -%}
    ---
    -- Network output
     so: out std_logic;
    ado: in  std_logic_vector({{ last.logn }}-1 downto 0);
    eno: in  std_logic
    {%- endwith %}
);
end {{ name }};

architecture arch of {{ name }} is
    ---
    -- Layers
    {%- for layer in layers %}
    
    -- {{ layer.label }}
    signal  si_{{ layer.label }}: std_logic;
    signal adi_{{ layer.label }}: std_logic_vector({{ layer.logm }}-1 downto 0);
    signal eni_{{ layer.label }}: std_logic;
    
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
        -- Input
        si  =>  si_{{ layer.label }},
        adi => adi_{{ layer.label }},
        eni => eni_{{ layer.label }},
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

        ---
        -- Network input
        si => si, adi => adi, eni => eni,
        {% for layer in layers %}
        ---
        -- {{ layer.label }}

        -- Input
         si_{{ layer.label }} =>  si_{{ layer.label }},
        adi_{{ layer.label }} => adi_{{ layer.label }},
        eni_{{ layer.label }} => eni_{{ layer.label }},

        -- Output
         so_{{ layer.label }} =>  so_{{ layer.label }},
        ado_{{ layer.label }} => ado_{{ layer.label }},
        eno_{{ layer.label }} => eno_{{ layer.label }},
        {% endfor %}
        ---
        -- Network output
        so => so, ado => ado, eno => eno
    );

end arch;