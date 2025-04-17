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

		INPUT_MATRIX_GRID  : in  matrix_grid;
        INPUT_MATRIX_SCREEN : in matrix_screen;
        OUTPUT_MATRIX_SCREEN : out matrix_screen := (others => (others => 0));

		-- PLAYER SIGNALS
		X	: in integer range 0 to 80;
		Y	: in integer range 0 to 70
	);
end entity screen;

architecture screen_arch of screen is
	--variables : 
	
	begin
		
		
	update_map : process
		variable screen : matrix_screen := INPUT_MATRIX_SCREEN;
	
	begin
		
		wait until falling_edge(CLK_50);

		for i in 0 to SCREEN_HEIGHT - 1 loop
			for j in 0 to SCREEN_WIDTH - 1 loop
				screen(i, j) := 3;
			end loop;
		end loop;

		-- for row in 0 to 6 loop  -- INPUT_MATRIX_GRID has 7 rows
		-- 	for col in 0 to 7 loop  -- INPUT_MATRIX_GRID has 8 columns
		-- 		-- Calculate the starting pixel position in the screen matrix
		-- 		for i in 0 to CELL_SIZE - 1 loop
		-- 			for j in 0 to CELL_SIZE - 1 loop
		-- 				screen(row * CELL_SIZE + i, col * CELL_SIZE + j) <= INPUT_MATRIX_GRID(row, col);
		-- 			end loop;
		-- 		end loop;
		-- 	end loop;
		-- end loop;



		OUTPUT_MATRIX_SCREEN <= screen;

	end process update_map;

end screen_arch;