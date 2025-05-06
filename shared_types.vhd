library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package shared_types is
    type matrix_grid is array (0 to 6, 0 to 7) of integer range 0 to 1;
    -- type sin_cos_lut is array(0 to 1023) of real;
    --     -- Fixed-point type
    -- subtype fixed is signed(15 downto 0);  -- Q8.8 format
end package;

package body shared_types is
end package body;