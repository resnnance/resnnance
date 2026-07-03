library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package {{ name }}_aux is

    constant n:    natural := {{ n }};
    constant logn: natural := integer(ceil(log2(real(n))));

    -- Input data width
    constant w: natural := 8;

    type data_t is array (0 to n-1) of real;
    type mem_t  is array (0 to n-1) of unsigned(w-1 downto 0);

    constant data: data_t :=
    (
        {% for pixel in data -%}
        {{ pixel }}{% if not loop.last %},
        {% endif %}{%- endfor %}
    );

    ---
    -- Memory data conversion
    function data_conv(data: data_t) return mem_t;
    impure function numpy2vhd(path: string; size: natural) return mem_t;
end package;

package body {{ name }}_aux is

    function data_conv(data: data_t) return mem_t is
        variable w:   unsigned(w-1 downto 0);
        variable mem: mem_t;
    begin
        for pixel in data'range loop
            w          := to_unsigned(integer(data(pixel) * 2.0**8), 8);
            mem(pixel) := w;
        end loop;

        return mem;
    end function;

    impure function numpy2vhd(path: string; size: natural) return mem_t is
        use std.textio.all;

        file     f:       text;
        variable fstatus: file_open_status;
        variable fline:   line;
        variable fint:    integer;

        variable mem: mem_t;
        variable i:   integer;
    begin
        file_open(fstatus, f, path, read_mode);

        if fstatus /= open_ok then
            report "File error: " & file_open_status'image(fstatus) severity failure;
        end if;

        i := 0;
        while not endfile(f) loop
            readline(f, fline);
            --report fline.all;

            read(fline, fint);
            mem(i) := to_unsigned(fint, w);
            i := i + 1;
        end loop;

        file_close(f);
        return mem;

    end function;

end package body;
