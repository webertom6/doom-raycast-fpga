library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_ARITH.ALL;
use ieee.std_logic_UNSIGNED.ALL;
use work.shared_types.all;


entity vga1 is port
	(
	
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

	--PLAYERS POSITIONS AND DIRECTIONS 
	constant x0 			: integer range 0 to 80 := 35;
	constant y0 			: integer range 0 to 70 := 35;
	signal player_x 		: integer range 0 to 80 := x0;
	signal player_y 		: integer range 0 to 70 := y0;

	-- MAP
	constant map_size 		: integer range 0 to 250 := 200;
	constant cell_size 	: integer range 0 to 100 := 28;

	signal grid : matrix_grid := (
		(1, 1, 1, 1, 1, 1, 1, 1),
		(1, 0, 0, 0, 0, 0, 0, 1),
		(1, 0, 1, 0, 1, 0, 0, 1),
		(1, 0, 1, 0, 1, 0, 0, 1),
		(1, 0, 1, 0, 1, 0, 0, 1),
		(1, 0, 0, 0, 0, 0, 0, 1),
		(1, 1, 1, 1, 1, 1, 1, 1)
    );

	-- SCREEN
	constant screen_width 	: integer range 0 to 800 := 800;
	constant screen_height 	: integer range 0 to 600 := 600;
	signal start_screen : matrix_screen := (others => (others => 0));
	signal updated_screen : matrix_screen := (others => (others => 0));
begin
	
	
	clocks_ent : entity work.clocks
	port map(	CLK_50 		=> CLK_50,
	CLK_SNES 	=> CLK_SNES,
	CLK_PLAYER 	=> CLK_PLAYER
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

	screen_ent : entity work.screen
	generic map(	SCREEN_WIDTH 	=> screen_width,
					SCREEN_HEIGHT 	=> screen_height,
					MAP_SIZE 		=> map_size,
					CELL_SIZE 		=> cell_size
				)
	port map(	CLK_50 	=> CLK_50,

				INPUT_MATRIX_MAP => grid,
				INPUT_MATRIX_SCREEN => start_screen,
				OUTPUT_MATRIX_SCREEN => updated_screen,

				X 			=> player_x,
				Y 			=> player_y
			);
	
	vga_ent : entity work.game1
	port map(	CLK_50 	=> CLK_50,
				RED 	=> RED,
                GREEN 	=> GREEN,
                BLUE 	=> BLUE,
                SYNC 	=> SYNC, 
				CTRL 	=> ctrl1,

				INPUT_MATRIX_SCREEN => updated_screen
			);
end architecture game_arch;