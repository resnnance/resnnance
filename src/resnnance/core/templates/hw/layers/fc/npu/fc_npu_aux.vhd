---
-- {{ name }}_npu_aux.vhd
--
-- Fully-connected layer - Neuron Processing Unit functions
--
-- params:
--      'name': self.label
---

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.{{ name }}_config.all;

package {{ name }}_npu_aux is
    ---
    -- Neuron model types
    subtype x_t is signed(15 downto 0);
    subtype w_t is signed(15 downto 0);

    ---
    -- Weight memory types
    type w_mem_t   is array (0 to fc_n-1) of w_t;
    type w_group_t is array (0 to fc_m-1) of w_mem_t;

    ---
    -- NPU function 
    function gv(x: x_t; so: std_logic) return x_t;
    function gi(x: x_t; s: std_logic; w: w_t) return x_t;
    function dyn(xg: x_t) return x_t;
    function h(xs: x_t) return std_logic;

    ---
    -- Neuron weight conversion
    function weight_conv(weights: fc_layer_weights_t) return w_group_t;

end package;

package body {{ name }}_npu_aux is
    ---
    -- (0) Virtual spike processing
    function gv(x: x_t; so: std_logic) return x_t is
        constant urest: x_t := to_signed(-64,  16);
        variable xg:    x_t;
    begin
        -- Default - no spiking
        xg := x;

        -- Virtual synapse
        if so = '1' then
            xg := urest;
        end if;

        return xg;
    end function;

    ---
    -- (1) Input spike processing
    function gi(x: x_t; s: std_logic; w: w_t) return x_t is
        variable xg: x_t;
    begin
        -- Default - no spiking
        xg := x;

        if s = '1' then
            xg := xg + w;
        end if;

        return xg;
    end function;

    ---
    -- (2) Advance neuron dynamics
    function dyn(xg: x_t) return x_t is
        constant urest: x_t := to_signed(-64,  16);
        variable dx:    x_t;
        variable xs:    x_t;
    begin
        xs := xg;
        dx := shift_right(-(xg - urest), 5);    -- d/dt
        xs := xg + dx;                          -- Solver

        return xs;
    end function;

    ---
    -- (3) Generate output spike
    function h(xs: x_t) return std_logic is
        constant uth:   x_t := to_signed(8192, 16);
        variable spike: std_logic;
    begin
        -- Default
        spike := '0';

        if xs > uth then
            spike := '1';
        end if;

        return spike;
    end function;

    ---
    -- Neuron weight conversion
    function weight_conv(weights: fc_layer_weights_t) return w_group_t is
        variable w:  w_t;
        variable wg: w_group_t;
    begin
        for synapse in weights'range loop
            for neuron in weights(synapse)'range loop
                w := to_signed(integer(weights(synapse)(neuron) * 2.0**7), 16);
                wg(synapse)(neuron) := w;
            end loop;
        end loop;

        return wg;
    end function;

end package body;