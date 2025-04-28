library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_ARITH.ALL;
use ieee.std_logic_UNSIGNED.ALL;
use work.shared_types.all;

entity vga1 is port
	(

	CLK_TIMER	: buffer std_logic;
	
	CLK_PLAYER	: buffer std_logic := '0';		
	
	-- SNES controller
	D1			: in std_logic;
	L1			: out std_logic := '0';
	CLK_SNES	: buffer std_logic := '0';		

	-- VGA display
	CLK_50 	: in std_logic;
	RED		: buffer std_logic_vector(3 downto 0);
	GREEN	: buffer std_logic_vector(3 downto 0);  
	BLUE	: buffer std_logic_vector(3 downto 0); 			
	SYNC	: out std_logic_vector(1 downto 0)
	);
end entity vga1;

-- GAME ARCHITECTURE --
architecture game_arch of vga1 is
	-- SNES SIGNALS 
	signal ctrl1	: std_logic_vector(11 downto 0);

	-- CLOCKS
	signal sclk_snes 		: std_logic := '0';
	signal sclk_player 		: std_logic := '0';
	signal sclk_timer 		: std_logic := '0';

	--PLAYERS POSITIONS AND DIRECTIONS 
	constant x0 			: integer range 0 to 80 := 35;
	constant y0 			: integer range 0 to 70 := 35;
	signal player_x 		: integer range 0 to 80 := x0;
	signal player_y 		: integer range 0 to 70 := y0;

	-- TIMER SIGNALS
	constant s0 			: integer range 0 to 600 := 0; -- 0 to 60 seconds
	signal second 			: integer range 0 to 600 := s0;

    -- GRID SIZE AND CELL SIZE
    constant rows           : integer range 0 to 7 := 7;
    constant cols           : integer range 0 to 8 := 8;
	constant grid_size 		: integer range 0 to 250 := 100;
	constant cell_size 	    : integer range 0 to 100 := grid_size / rows;
	-- Creates a row=7xcol=8 array for grid
	signal grid : matrix_grid := (
		(1, 1, 1, 1, 1, 1, 1, 1),
		(1, 0, 0, 0, 0, 0, 0, 1),
		(1, 0, 1, 0, 1, 0, 0, 1),
		(1, 0, 1, 0, 1, 0, 0, 1),
		(1, 0, 1, 0, 1, 0, 0, 1),
		(1, 0, 0, 0, 0, 0, 0, 1),
		(1, 1, 1, 1, 1, 1, 1, 1)
    );

    -- SCREEN SIZE
    constant space_border : integer range 0 to 100 := 10; -- 10px border
    constant info_height : integer range 0 to 100 := 100; -- 10px info bar
	
begin
	
	vga_ent : entity work.game1
	generic map(	
                ROWS 			=> rows,
                COLS 			=> cols,
				GRID_SIZE 		=> grid_size,
				CELL_SIZE 		=> cell_size,
                SPACE_BORDER 	=> space_border,
                INFO_HEIGHT 	=> info_height
			)
	port map(	CLK_50 	=> CLK_50,
				RED 	=> RED,
                GREEN 	=> GREEN,
                BLUE 	=> BLUE,
                SYNC 	=> SYNC, 
				CTRL 	=> ctrl1,

				INPUT_MATRIX_GRID => grid,

				SECOND 		=> second,

				X 			=> player_x,
				Y 			=> player_y
			);

	clocks_ent : entity work.clocks
	port map(	CLK_50 		=> CLK_50,
				CLK_SNES 	=> CLK_SNES,
				CLK_PLAYER 	=> CLK_PLAYER,
				CLK_TIMER 	=> CLK_TIMER
				);

	ctrl1_ent : entity work.snes
	port map(	CLK		=> CLK_SNES,
				DATA 	=> D1,
				LATCH	=> L1,
				CTRL 	=> ctrl1
				);

	player_ent : entity work.player
	generic map (
		x0 => x0,
		y0 => y0
	)
	port map(	CLK_PLAYER	=> CLK_PLAYER,
				CTRL 		=> ctrl1,
				X 			=> player_x,
				Y 			=> player_y
			);

	timer_ent : entity work.timer
	generic map (
		s0 => s0
	)
	port map(	CLK_TIMER 	=> CLK_TIMER,
				SECOND 		=> second
			);


end architecture game_arch;