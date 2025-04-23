library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_ARITH.ALL;
use ieee.std_logic_UNSIGNED.ALL;
use work.shared_types.all;

entity game1 is 
generic (
		-- GRID SIZE CELL SIZE
		ROWS          : integer range 0 to 7;
		COLS          : integer range 0 to 8;
		GRID_SIZE      : integer range 0 to 250;
		CELL_SIZE     : integer range 0 to 100;
		-- SCREEN SIZE
		SPACE_BORDER   : integer range 0 to 100; -- 10px border
		INFO_HEIGHT    : integer range 0 to 100
	);
port ( 
		-- DISPLAY SIGNALS
		CLK_50 : in std_logic;	
		RED: out std_logic_vector(3 downto 0);
		GREEN: out std_logic_vector(3 downto 0);  
		BLUE: out std_logic_vector(3 downto 0); 			
		SYNC: out std_logic_vector(1 downto 0);

		-- SNES CONTROLLER SIGNALS
		CTRL : in std_logic_vector(11 downto 0);

		INPUT_MATRIX_GRID  : in  matrix_grid;

		-- PLAYER SIGNALS
		X	: in integer range 0 to 80;
		Y	: in integer range 0 to 70
	);
end game1;

architecture Behavioral of game1 is    

	------------------ VGA COMMUNICATION ------------------
    -- Sync Signals
    -- h_sync and v_sync: Signals that synchronize the monitor's scanning process.
    signal h_sync : std_logic;
    signal v_sync : std_logic;
    
    -- Video Enables
    signal video_en : std_logic;
    -- horizontal_en: Indicates whether the current pixel is in the active visible area of the screen (horizontally).
    signal horizontal_en : std_logic;
    -- vertical_en: Indicates whether the current pixel is in the active visible area of the screen (vertically).
    signal vertical_en : std_logic;
    
    
    -- Sync Counters
    -- h_cnt (Horizontal Counter): Keeps track of the horizontal position of the pixel being drawn.
    signal h_cnt : std_logic_vector(10 downto 0) := (others => '0');
    -- v_cnt (Vertical Counter): Keeps track of the vertical position of the pixel being drawn.
    signal v_cnt : std_logic_vector(10 downto 0) := (others => '0');
    
    -- Horizontal timing constants
    constant h_back_porch : integer := 64;
    constant h_active : integer := 800;
    constant h_front_porch : integer := 56;
    -- h_sync_length (120): The number of pixels that the horizontal sync pulse is active (low).
    constant h_sync_length : integer := 120;
    -- h_length (1040): Total number of pixels per horizontal line, including visible pixels and blanking periods.
    constant h_length : integer := 1040;
    
    -- Vertical timing constants
    constant v_back_porch : integer := 23;
    constant v_active : integer := 600;
    constant v_front_porch : integer := 37;
    constant v_sync_length : integer := 6;
    -- v_length (666): Total number of lines per frame, including visible lines and blanking periods.
    constant v_length : integer := 666;
	----------------------------------------------------------------------
	
	signal B , YBT, SLCT, STRT, UP_CROSS, DOWN_CROSS, LEFT_CROSS, RIGHT_CROSS, ABT, XBT, LBT, RBT : std_logic;
	
    -- Color Signals
    signal color : std_logic_vector(11 downto 0) := (others => '0');

	type color_lut_type is array (0 to 4) of std_logic_vector(11 downto 0);
	constant color_lut : color_lut_type := (
		0  => "000000000000", -- Black
		1  => "111111111111", -- White
		2  => "111100000000", -- Red
		3  => "000011110000", -- Green
		4  => "000000001111" -- Blue
		-- 3  => "000011111111", -- Cyan
		-- 5  => "111100001111", -- Magenta
		-- 6  => "111111110000", -- Yellow
		-- 8  => "100000000000", -- Dark Red
		-- 9  => "000010000000", -- Dark Green
		-- 10 => "000000001000", -- Dark Blue
		-- 11 => "111111000000", -- Orange
		-- 12 => "001111111000", -- Light Cyan
		-- 13 => "100010000100", -- Pink
		-- 14 => "000111100111", -- Teal
		-- 15 => "011001100110"  -- Gray
	);
	
	-- Sprite heart dimensions
	constant heart_sprite_width  : integer := 32;
	constant heart_sprite_height : integer := 32;
	constant nb2_sprite_width  : integer := 32;
	constant nb2_sprite_height : integer := 32;

	-- Sprite position
	constant nb_hearts : integer := 3;
	constant heart_sprite_x_start : integer := (h_active - heart_sprite_width * nb_hearts) - 10;
	constant heart_sprite_y_start : integer := (v_active - (INFO_HEIGHT / 2) - heart_sprite_height);

	constant nb2_sprite_x_start : integer := (h_active - nb2_sprite_width) / 2;
	constant nb2_sprite_y_start : integer := (v_active - (INFO_HEIGHT / 2) - nb2_sprite_height);

	signal heart_sprite_width_idx : integer range 0 to 32 := 0;

	-- Memory addresses
	signal adr_heart_sprite_save : std_logic_vector(9 downto 0) := (others => '0');
	signal adr_heart_sprite : std_logic_vector(9 downto 0) := (others => '0');
	signal color_heart_sprite : std_logic_vector(11 downto 0) := (others => '0');

	signal adr_nb2_sprite : std_logic_vector(9 downto 0) := (others => '0');
	signal color_nb2_sprite : std_logic_vector(11 downto 0) := (others => '0');


begin
	video_en <= horizontal_en AND vertical_en;

	-- ROM instance
	ROM_heart : entity work.ROM_COMP_HEART port map (
		address => adr_heart_sprite,
		clock => CLK_50,
		q => color_heart_sprite
	);

	ROM_nb2 : entity work.ROM_COMP_NB2 port map (
		address => adr_nb2_sprite,
		clock => CLK_50,
		q => color_nb2_sprite
	);

	B 		<=	CTRL(0);
	YBT		<=	CTRL(1);
	SLCT	<=	CTRL(2);
	STRT	<=	CTRL(3);
	UP_CROSS		<=	CTRL(4);
	DOWN_CROSS 	<=	CTRL(5);
	LEFT_CROSS	<=	CTRL(6);
	RIGHT_CROSS	<=	CTRL(7);
	ABT		<=	CTRL(8);
	XBT		<=	CTRL(9);
	LBT		<=	CTRL(10);
	RBT		<=	CTRL(11);
	
	vga_square: process

	variable player_x : integer range 0 to 800 := 35; -- Scaled by 10 to represent 3.5
	variable player_y : integer range 0 to 700 := 35; -- Scaled by 10 to represent 3.5


	begin
		wait until rising_edge(CLK_50);

			color <= "000000001111"; -- background color

			player_x := X; -- Get the player's X position from the player entity
			player_y := Y; -- Get the player's Y position from the player entity

			-- raycast screen placeholder
			if ( (v_cnt >= v_back_porch + SPACE_BORDER) AND (v_cnt <= v_back_porch + 500 - SPACE_BORDER)
				AND (h_cnt >= h_back_porch + SPACE_BORDER) AND (h_cnt <= h_back_porch + h_active - SPACE_BORDER)) then
				color <= "111100000000"; -- square color
			end if;

			-- Display sprite nb2 at the center of the screen
			if (v_cnt >= v_back_porch + nb2_sprite_y_start and v_cnt < v_back_porch + nb2_sprite_y_start + nb2_sprite_height and
				h_cnt >= h_back_porch + nb2_sprite_x_start and h_cnt < h_back_porch + nb2_sprite_x_start + nb2_sprite_width) then
				
				color <= color_nb2_sprite;

				adr_nb2_sprite <= adr_nb2_sprite + 1;

			end if;

			
			-- Draw the hearts
			if ( (v_cnt >= v_back_porch + heart_sprite_y_start) AND (v_cnt <= v_back_porch + heart_sprite_y_start + heart_sprite_height - 1)
				AND (h_cnt >= h_back_porch + heart_sprite_x_start) 
				AND (h_cnt <= h_back_porch + heart_sprite_x_start + nb_hearts * heart_sprite_width - 1)) then

					
				if (heart_sprite_width_idx >= heart_sprite_width - 1) then
					heart_sprite_width_idx <= 0;
					adr_heart_sprite <= adr_heart_sprite_save;
				end if;
				if (heart_sprite_width_idx = 0) then
					adr_heart_sprite_save <= adr_heart_sprite;
				end if;

				color <= color_heart_sprite;

				adr_heart_sprite <= adr_heart_sprite + 1;

				heart_sprite_width_idx <= heart_sprite_width_idx + 1;
	
			end if;

			-- for heart_index in 0 to nb_hearts - 1 loop

			-- 	if ( (v_cnt >= v_back_porch + heart_sprite_y_start) AND (v_cnt <= v_back_porch + heart_sprite_y_start + heart_sprite_height - 1)
			-- 		AND (h_cnt >= h_back_porch + heart_sprite_x_start + 0 * heart_sprite_width) 
			-- 		AND (h_cnt <= h_back_porch + heart_sprite_x_start + nb_hearts * heart_sprite_width - 1)) then

			-- 		adr_heart_sprite_save <= adr_heart_sprite;
					
			-- 		for idx_heart_sprite_width in 0 to heart_sprite_width - 1 loop
			-- 			color <= color_heart_sprite;

			-- 			adr_heart_sprite <= adr_heart_sprite + 1;
			-- 		end loop;
			-- 		adr_heart_sprite <= adr_heart_sprite_save;
			-- 	end if;

			-- end loop;


			for i in 0 to ROWS - 1 loop
				
				for j in 0 to COLS - 1 loop
						--Generate square
						-- v_cnt >= v_back_porch + x : starting vertical equals x pixels after the back porch, back porch is the "inactive" area before the active display area.
						-- v_cnt <= v_back_porch + y : ending vertical equals y pixels after the back porch.
						-- h_cnt >= h_back_porch + x : starting horizontal equals x pixels after the back porch.
						-- h_cnt <= h_back_porch + y : ending horizontal equals y pixels after the back porch.
						-- The square is drawn in the active display area, which is between 64 and 863 pixels horizontally and 24 and 623 pixels vertically.
						if ( (v_cnt >= v_back_porch + 500 + i * CELL_SIZE) AND (v_cnt <= v_back_porch + 500 + CELL_SIZE  + i * CELL_SIZE)
						AND (h_cnt >= h_back_porch + SPACE_BORDER + j * CELL_SIZE ) AND (h_cnt <= h_back_porch + SPACE_BORDER + CELL_SIZE + j * CELL_SIZE)) then

							color <= color_lut(INPUT_MATRIX_GRID(i,j)); -- Assign color based on the matrix value

							-- Draw the player as a green circle
							if ( (v_cnt >= v_back_porch + 500 + (player_y * CELL_SIZE) / 10 - CELL_SIZE / 2) AND 
								 (v_cnt <= v_back_porch + 500 + (player_y * CELL_SIZE) / 10 + CELL_SIZE / 2) AND 
								 (h_cnt >= h_back_porch + (player_x * CELL_SIZE) / 10 - CELL_SIZE / 2) AND 
								 (h_cnt <= h_back_porch + (player_x * CELL_SIZE) / 10 + CELL_SIZE / 2) ) then
								color <= "000011110000"; -- green
							end if;
						end if;
					
					end loop;
				
			end loop ; -- 	


			-------------------------- VGA COMMUNICATION --------------------------

			--Generate Horizontal Sync
			-- h_length - h_sync_length = 1040 - 120 = 920, so when h_cnt is between 920 and 1039, h_sync is low (0).
			if (h_cnt <= h_length-1) AND (h_cnt >= h_length - h_sync_length) then
				h_sync <= '0';
			else
				h_sync <= '1';
			end if;

			--Generate Vertical Sync
			-- v_length - v_sync_length = 666 - 6 = 660, so when v_cnt is between 660 and 665, v_sync is low (0).
			if (v_cnt <= v_length-1) AND (v_cnt >= v_length - v_sync_length) then
				v_sync <= '0';
			else
				v_sync <= '1';
			end if;

			--Reset Horizontal Counter
			-- The horizontal counter resets when it reaches 1039 (h_length - 1), meaning a new scanline begins
			if (h_cnt = h_length - 1) then
				h_cnt <= "00000000000";
			else
				h_cnt <= h_cnt + 1;
			end if;

			--Reset Vertical Counter
			-- When both h_cnt and v_cnt reach their maximum values (1039 and 665, respectively), the frame resets (v_cnt = 0).
			-- If only h_cnt reaches its max, it increments v_cnt to move to the next row.
			if (v_cnt = v_length - 1) AND (h_cnt = h_length - 1) then
				v_cnt <= "00000000000";
			elsif (h_cnt = h_length - 1) then
				v_cnt <= v_cnt + 1;
			end if;

			--Generate Horizontal Data
			-- The active display area horizontally starts at pixel 63 and ends at 863.
			-- When h_cnt is in this range, horizontal_en = '1', meaning pixels in this region are visible.
			if (h_cnt >= 63 AND h_cnt <= 863) then
				horizontal_en <= '1';
			else
				horizontal_en <= '0';
			end if;

			--Generate Vertical Data
			-- The active display area horizontally starts at pixel 63 and ends at 863.
			-- When h_cnt is in this range, horizontal_en = '1', meaning pixels in this region are visible.
			if (v_cnt >= 24 AND v_cnt <= 623) then
				vertical_en <= '1';
			else
				vertical_en <= '0';
			end if;

			--Assign pins to color VGA
			RED(0) <= color(8) AND video_en;   --Red LSB
			RED(1) <= color(9) AND video_en;
			RED(2) <= color(10) AND video_en;
			RED(3) <= color(11) AND video_en;  --Red MSB
			GREEN(0) <= color(4) AND video_en; --Green LSB
			GREEN(1) <= color(5) AND video_en;
			GREEN(2) <= color(6) AND video_en;
			GREEN(3) <= color(7) AND video_en; --Green MSB
			BLUE(0) <= color(0) AND video_en;  --Blue LSB
			BLUE(1) <= color(1) AND video_en;
			BLUE(2) <= color(2) AND video_en;
			BLUE(3) <= color(3) AND video_en;  --Blue MSB

			--Synchro
			SYNC(1) <= h_sync;
			SYNC(0) <= v_sync;

			-- reset adr when h_cnt and v_cnt at end of screen
			if (h_cnt >= h_length - 1) AND (v_cnt >= v_length - 1) then
				adr_heart_sprite <= "0000000000";
			end if;
	end process vga_square;	
end Behavioral;