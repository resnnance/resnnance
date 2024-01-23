---
-- {{ name }}_config.vhd
--
-- Convolutional 2D layer - Configuration package
--
-- params:
--      'name': self.label,
--      'm': self.input_shape,
--      'k': self.kernel_shape,
--      'n': self.__get_output_shape(),
--      'weights': self.__flatten_zy()
---

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package {{ name }}_config is

    constant conv2D_mx: natural := {{ m[1] }};
    constant conv2D_my: natural := {{ m[0] }};
    constant conv2D_kx: natural := {{ k[1] }};
    constant conv2D_ky: natural := {{ k[0] }};
    constant conv2D_kz: natural := {{ k[2] }};
    constant conv2D_f:  natural := {{ k[3] }};

    constant conv2D_nx: natural := conv2D_mx - conv2D_kx + 1;
    constant conv2D_ny: natural := conv2D_my - conv2D_ky + 1;

    constant conv2D_m:  natural := conv2D_mx * conv2D_my * conv2D_kz;
    constant conv2D_n:  natural := conv2D_nx * conv2D_ny * conv2D_f;

    constant conv2D_k:  natural := conv2D_kx * conv2D_ky * conv2D_kz;

    type conv2D_kernel_weights_t is array (0 to conv2D_k-1) of real;                    -- Kernel
    type conv2D_layer_weights_t  is array (0 to conv2D_f-1) of conv2D_kernel_weights_t; -- Layer

    {% for kernel in weights -%}
    constant kernel_{{ loop.index0 }}: conv2D_kernel_weights_t :=
    (
        {% for weight in kernel -%}
        {{ weight }}{% if not loop.last %}, {% endif %}{%- endfor %}
    );

    {% endfor -%}

    constant conv2D_w: conv2D_layer_weights_t := (
        {% for kernel in weights -%}
        {{ loop.index0 }} => kernel_{{ loop.index0 }}{% if not loop.last %},
        {% endif %}{%- endfor %}
    );

    constant conv2D_logmx: natural := integer(ceil(log2(real(conv2D_mx))));
    constant conv2D_logmy: natural := integer(ceil(log2(real(conv2D_my))));
    constant conv2D_logkz: natural := integer(ceil(log2(real(conv2D_kz))));

    constant conv2D_logm:  natural := integer(ceil(log2(real(conv2D_m))));
    constant conv2D_logn:  natural := integer(ceil(log2(real(conv2D_n))));
    constant conv2D_logf:  natural := integer(ceil(log2(real(conv2D_f))));

end package;