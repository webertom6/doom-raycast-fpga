library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_ARITH.ALL;
use ieee.std_logic_UNSIGNED.ALL;
use work.shared_types.all;


entity screen is 
generic (
		-- SCREEN SIZE
		SCREEN_WIDTH  : integer range 0 to 800;
		SCREEN_HEIGHT : integer range 0 to 600;
		-- MAP SIZE
		MAP_SIZE      : integer range 0 to 250;
		-- CELL SIZE
		CELL_SIZE     : integer range 0 to 100
	);
port	(
		-- DISPLAY SIGNALS
		CLK_50 : in std_logic;	

		INPUT_MATRIX_MAP  : in  matrix_grid;
        INPUT_MATRIX_SCREEN : in matrix_screen;
        OUTPUT_MATRIX_SCREEN : out matrix_screen := (others => (others => 0));

		-- PLAYER SIGNALS
		X	: in integer range 0 to 80;
		Y	: in integer range 0 to 70
	);
end entity screen;

architecture screen_arch of screen is
	--variables : 
	signal screen : matrix_screen := (others => (others => 0));

begin

	
	update_map : process

		begin

		wait until falling_edge(CLK_50);


		screen <= INPUT_MATRIX_SCREEN;

		OUTPUT_MATRIX_SCREEN <= screen;

	end process update_map;

end screen_arch;