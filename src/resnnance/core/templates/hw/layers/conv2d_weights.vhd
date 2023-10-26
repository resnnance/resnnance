library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use ieee.math_real.ALL;

package {{ name }} is

    constant kx: natural := {{ k[1] }};
    constant ky: natural := {{ k[0] }};
    constant kz: natural := {{ k[2] }};
    constant w:  natural := 16;          -- Weight bit width

    ---
    --         #-----------------#
    --         | c00 | c01 | c02 |
    --     #-----------------# --|
    --     | b00 | b01 | b02 | 2 |
    -- #-----------------# --| --|
    -- | a00 | a01 | a02 | 2 | 2 |
    -- |-----|-----|-----| --| --#
    -- | a10 | a11 | a12 | 2 |
    -- |-----|-----|-----| --#
    -- | a20 | a21 | a22 |
    -- #-----------------#
    --
    --          ||  .flatten (z, y)
    --          \/
    --
    -- [a00, b00, c00, a01, b01, c01, ... , a22, b22, c22]
    ---
    type kernel_vector_real_t is array (0 to kx*ky*kz-1) of signed(w-1 downto 0);
    type kernel_vector_real_t is array (0 to kx*ky*kz-1) of signed(w-1 downto 0);

    {% for kernel in weights %}
    constant kernel_{{ loop.index0 }}_vector_real: kernel_vector_real_t :=
    (
        {% for weight in kernel -%}
        {{ weight }},
        {%- endfor %}
    )
    {% endfor %}

end {{ name }};