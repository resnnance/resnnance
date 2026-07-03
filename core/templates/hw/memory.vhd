library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity {{ name }} is
port (
    clk: in std_logic;

    {% with first = layers | first -%}
    ---
    -- Network input
     si: in  std_logic;
    adi: in  std_logic_vector({{ first.logm }}-1 downto 0);
    eni: in  std_logic;
    {%- endwith %}

    {%- for layer in layers %}

    ---
    -- {{ layer.label }}

    -- Input
     si_{{ layer.label }}: out std_logic;
    adi_{{ layer.label }}: in  std_logic_vector({{ layer.logm }}-1 downto 0);
    eni_{{ layer.label }}: in  std_logic;

    -- Output
     so_{{ layer.label }}: in  std_logic;
    ado_{{ layer.label }}: in  std_logic_vector({{ layer.logn }}-1 downto 0);
    eno_{{ layer.label }}: in  std_logic;
    {%- endfor %}

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
    -- Memories

    {% with first = layers | first -%}
    -- Input
    type smem_input_t is array (0 to 2**{{ first.logm }}-1) of std_logic;
    signal smem_input: smem_input_t;
    {% endwith %}

    {%- for layer in layers %}
    -- {{ layer.label }}
    type smem_{{ layer.label }}_t is array (0 to 2**{{ layer.logn }}-1) of std_logic;
    signal smem_{{ layer.label }}: smem_{{ layer.label }}_t;
    {% endfor %}
begin
    {% with first = layers | first %}
    -- Input --> {{ first.label }}
    mem_input: process (clk)
    begin
        if rising_edge(clk) then
            -- Write
            if eni = '1' then
                smem_input(to_integer(unsigned(adi))) <= si;
            end if;
            -- Read
            if eni_{{ first.label }} = '1' then
                si_{{ first.label }} <= smem_input(to_integer(unsigned(adi_{{ first.label }})));
            end if;
        end if;
    end process;
    {%- endwith %}

    {%- for layer in layers %}
    {%- if not loop.first %}
    -- {{ loop.previtem.label }} --> {{ layer.label }}
    mem_{{ loop.previtem.label }}: process (clk)
    begin
        if rising_edge(clk) then
            -- Write
            if eno_{{ loop.previtem.label }} = '1' then
                smem_{{ loop.previtem.label }}(to_integer(unsigned(ado_{{ loop.previtem.label }}))) <= so_{{ loop.previtem.label }};
            end if;
            -- Read
            if eni_{{ layer.label }} = '1' then
                si_{{ layer.label }} <= smem_{{ loop.previtem.label }}(to_integer(unsigned(adi_{{ layer.label }})));
            end if;
        end if;
    end process;
    {%- endif %}
    {% endfor %}

    {%- with last = layers | last %}
    -- {{ last.label }} --> Output
    mem_{{ last.label }}: process (clk)
    begin
        if rising_edge(clk) then
            -- Write
            if eno_{{ last.label }} = '1' then
                smem_{{ last.label }}(to_integer(unsigned(ado_{{ last.label }}))) <= so_{{ last.label }};
            end if;
            -- Read
            if eno = '1' then
                so <= smem_{{ last.label }}(to_integer(unsigned(ado)));
            end if;
        end if;
    end process;
    {%- endwith %}

end arch;
