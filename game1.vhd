library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_ARITH.ALL;
use ieee.std_logic_UNSIGNED.ALL;

entity game1 is port 
	( 
		CLK_50 : in std_logic;	
		RED: out std_logic_vector(3 downto 0);
		GREEN: out std_logic_vector(3 downto 0);  
		BLUE: out std_logic_vector(3 downto 0); 			
		SYNC: out std_logic_vector(1 downto 0);

		CTRL 				: in std_logic_vector(11 downto 0)

	);
end game1;

architecture Behavioral of game1 is    
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
    
    -- Color Signals
    signal color : std_logic_vector(11 downto 0) := (others => '0');
    
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

	signal B , YBT, SLCT, STRT, UP_CROSS, DOWN_CROSS, LEFT_CROSS, RIGHT_CROSS, ABT, XBT, LBT, RBT : std_logic;

	-- Creates a row=7xcol=8 array for a number pad
	type matrix_type is array (0 to 6, 0 to 7) of integer range 0 to 1;
    signal my_matrix : matrix_type := (
		(1, 1, 1, 1, 1, 1, 1, 1),
		(1, 0, 0, 0, 0, 0, 0, 1),
		(1, 0, 1, 1, 1, 0, 0, 1),
		(1, 0, 1, 0, 1, 0, 0, 1),
		(1, 0, 1, 0, 1, 0, 0, 1),
		(1, 0, 0, 0, 0, 0, 0, 1),
		(1, 1, 1, 1, 1, 1, 1, 1)
    );

begin
	video_en <= horizontal_en AND vertical_en;

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

	-- matrix printing variables
	variable idx_row : integer range 0 to 4 := 0;
	variable idx_col : integer range 0 to 3 := 0;
	variable step_row : integer range 0 to 100 := 50;

	variable map_size : integer range 0 to 250 := 200;
	variable cell_size : integer range 0 to 100 := 28;

	variable value_matrix : integer range 0 to 1 := 0;

	-- player variables
	variable player_x : integer range 0 to 80 := 35; -- Scaled by 10 to represent 3.5
	variable player_y : integer range 0 to 70 := 35; -- Scaled by 10 to represent 3.5
	variable player_angle : real range 0.0 to 360.0 := 0.0;

	begin
		wait until rising_edge(CLK_50);

			-- case state is
			-- 	when draw_background =>
			-- 		color <= "000000001111"; -- Background color
			-- 		if ( (v_cnt >= v_back_porch + 200) AND (v_cnt <= v_back_porch + 400) AND 
			-- 			(h_cnt >= h_back_porch + 300) AND (h_cnt <= h_back_porch + 500) ) then
			-- 			state <= draw_square;
			-- 		end if;
					
			-- 	when draw_square =>
			-- 		color <= "111100000000"; -- Square color
			-- 		state <= draw_background; -- Transition back to background
			-- end case;

			color <= "000000001111"; -- background color


			if(UP_CROSS = '1') then
				player_y := player_y - 1; -- Adjusted for scaling
			end if;

			if(DOWN_CROSS = '1') then
				player_y := player_y + 1; -- Adjusted for scaling
			end if;

			if(LEFT_CROSS = '1') then
				player_x := player_x - 1; -- Adjusted for scaling
			end if;
			if(RIGHT_CROSS = '1') then
				player_x := player_x + 1; -- Adjusted for scaling
			end if;

			--color <= "000000000000"; -- background color
			-- color <= "111111111111"; -- background color


			for i in 0 to 6 loop
				
				for j in 0 to 7 loop
						--Generate square
						-- v_cnt >= v_back_porch + x : starting vertical equals x pixels after the back porch, back porch is the "inactive" area before the active display area.
						-- v_cnt <= v_back_porch + y : ending vertical equals y pixels after the back porch.
						-- h_cnt >= h_back_porch + x : starting horizontal equals x pixels after the back porch.
						-- h_cnt <= h_back_porch + y : ending horizontal equals y pixels after the back porch.
						-- The square is drawn in the active display area, which is between 64 and 863 pixels horizontally and 24 and 623 pixels vertically.
						if ( (v_cnt >= v_back_porch + 0 + i * cell_size) AND (v_cnt <= v_back_porch + cell_size  + i * cell_size)
						AND (h_cnt >= h_back_porch + 0 + j * cell_size ) AND (h_cnt <= h_back_porch + cell_size + j * cell_size)) then
							-- Assign the value of the matrix to the variable value_matrix
							-- value_matrix := my_matrix(i,j);
							-- if (value_matrix = 1) then
							if (my_matrix(i,j) = 0) then
								color <= "000000000000"; -- red
								else
								color <= "111111111111"; -- green
							end if;

							-- Draw the player as a green circle
							if ( (v_cnt >= v_back_porch + (player_y * cell_size) / 10 - cell_size / 2) AND 
								 (v_cnt <= v_back_porch + (player_y * cell_size) / 10 + cell_size / 2) AND 
								 (h_cnt >= h_back_porch + (player_x * cell_size) / 10 - cell_size / 2) AND 
								 (h_cnt <= h_back_porch + (player_x * cell_size) / 10 + cell_size / 2) ) then
								color <= "000011110000"; -- green
							end if;
						end if;
					
					end loop;
				
			end loop ; -- 	



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
	end process vga_square;	
end Behavioral;