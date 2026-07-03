---
-- {{ name }}_config.vhd
--
-- Pooling layer - Configuration package
--
-- params:
--      'name': self.label,
--      'm': self.input_shape,
--      'p': self.pool,
--      'n': self.__get_output_shape(),
--      'weight': self.__get_weight()
---

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package {{ name }}_config is

    constant pool_mx: natural := {{ m[1] }};
    constant pool_my: natural := {{ m[0] }};
    constant pool_mz: natural := {{ m[2] }};
    constant pool_px: natural := {{ p[1] }};
    constant pool_py: natural := {{ p[0] }};

    constant pool_nx: natural := pool_mx / pool_px;
    constant pool_ny: natural := pool_my / pool_py;

    constant pool_m:  natural := pool_mx * pool_my * pool_mz;
    constant pool_n:  natural := pool_nx * pool_ny * pool_mz;

    constant pool_p:  natural := pool_px * pool_py;

    constant pool_w:  real := {{ weight }};

    constant pool_logm: natural := integer(ceil(log2(real(pool_m))));
    constant pool_logn: natural := integer(ceil(log2(real(pool_n))));

    constant pool_logmx: natural := integer(ceil(log2(real(pool_mx))));
    constant pool_logmy: natural := integer(ceil(log2(real(pool_my))));
    constant pool_logmz: natural := integer(ceil(log2(real(pool_mz))));

    constant pool_logpx: natural := integer(ceil(log2(real(pool_px))));
    constant pool_logpy: natural := integer(ceil(log2(real(pool_py))));

end package;