library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package {{ name }}_aux is

    constant n: natural := {{ n }};

    -- Input data width
    constant w: natural := 8;

    type mem_t is array (natural range <>) of unsigned(w-1 downto 0);
    impure function numpy2vhd(path: string; size: natural) return mem_t;

    constant logn: natural := integer(ceil(log2(real(n))));
end package;

package body {{ name }}_aux is

    impure function numpy2vhd(path: string; size: natural) return mem_t is
        use std.textio.all;

        file     f:       text;
        variable fstatus: file_open_status;
        variable fline:   line;
        variable fint:    integer;

        variable mem: mem_t(0 to size-1);
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