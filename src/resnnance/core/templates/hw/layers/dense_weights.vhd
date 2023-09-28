library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use ieee.math_real.ALL;

package {{ name }} is

    constant m: integer := {{ m }};     -- Synapses per neuron
    constant n: integer := {{ n }};     -- Neurons

    constant w: natural := 16;          -- Weight bit width
    type synapse_vector_t is array (0 to m-1) of signed(w-1 downto 0);
    type synapse_matrix_t is array (0 to n-1) of synapse_vector_t;

    type synapse_vector_real_t is array (0 to m-1) of real;
    type synapse_matrix_real_t is array (0 to n-1) of synapse_vector_real_;

    function weight_conversion(matrix: synapse_matrix_real_t) return synapse_matrix_t;

    constant {{ name }}_matrix: synapse_matrix_t := weight_conversion({{ name }}_matrix_real);
    constant {{ name }}_matrix_real: synapse_matrix_real_t :=
    (
        {% for synapse in weights -%}
        ({% for weight in synapse -%}
        {{ weight }}{% if not loop.last %}, {% endif %}
        {%- endfor %}){% if not loop.last %},
        {% endif %}{%- endfor %}
    );

end {{ name }};

package body {{ name }} is

    function weight_conversion(rmatrix: synapse_matrix_real_t)
    return synapse_matrix_t is
        variable weight: integer;
        variable matrix: synapse_matrix_t;
    begin
        for synapse in matrix loop
            for neuron in synapse loop
                weight := integer(rmatrix(synapse)(neuron) * 2.0**(w-3-1));
                matrix(synapse)(neuron) := to_signed(weight, w);
            end loop;
        end loop;

        return matrix;
    end function;

end {{ name }};