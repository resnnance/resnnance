---
-- {{ name }}_config.vhd
--
-- Fully-connected layer - Configuration package
--
-- params:
--      'name': self.label
--      'weights': self.weights,
--      'm': self.weights.shape[0],
--      'n': self.weights.shape[1]
---

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package {{ name }}_config is

    constant fc_m: natural := {{ m }};
    constant fc_n: natural := {{ n }};

    type fc_synapse_weights_t is array (0 to fc_n-1) of real;                  -- Neuron
    type fc_layer_weights_t   is array (0 to fc_m-1) of fc_synapse_weights_t;  -- Layer
    constant fc_w: fc_layer_weights_t :=
    (
        {% for synapse in weights -%}
        ({% for weight in synapse -%}
        {{ weight }}{% if not loop.last %}, {% endif %}
        {%- endfor %}){% if not loop.last %},
        {% endif %}{%- endfor %}
    );

    constant fc_logm: natural := integer(ceil(log2(real(fc_m))));
    constant fc_logn: natural := integer(ceil(log2(real(fc_n))));

end package;