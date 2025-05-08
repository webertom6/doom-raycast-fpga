library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

package SharedTypes is
    type matrix_grid is array (0 to 6, 0 to 7) of integer range 0 to 1;
	 type signed_array is array (0 to 63) of signed(31 downto 0);
	 type int_array  is array (0 to 63) of integer range 0 to 512;
	 
	 pure function fixedPointMul(a, b: signed(31 downto 0)) return signed;
	 pure function toFixedPoint(a: integer) return signed;
end package;

package body SharedTypes is
	pure function fixedPointMul(a, b: signed(31 downto 0)) return signed is
        variable result: signed(63 downto 0);
    begin
        result := a * b;
        return result(47 downto 16);
    end;

	pure function toFixedPoint(a: integer) return signed is
		variable result: signed(31 downto 0);
	begin
		result := to_signed(a, 32);
		result := shift_left(result, 16);
		return result;
	end;
end package body;
