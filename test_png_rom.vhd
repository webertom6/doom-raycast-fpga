library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_ARITH.ALL;
use ieee.std_logic_UNSIGNED.ALL;

entity test_png_rom is port 
	( 
		CLK_50 : in std_logic;	
		RED: out std_logic_vector(3 downto 0);
		GREEN: out std_logic_vector(3 downto 0);  
		BLUE: out std_logic_vector(3 downto 0); 			
		SYNC: out std_logic_vector(1 downto 0) 
	);
end test_png_rom;

architecture Behavioral of test_png_rom is
	-- Sync Signals
	signal h_sync : std_logic;
	signal v_sync : std_logic;

	-- Video Enables
	signal video_en : std_logic;
	signal horizontal_en : std_logic;
	signal vertical_en : std_logic;

	-- Color Signals
	signal color : std_logic_vector(11 downto 0) := (others => '0');

	-- Sync Counters
	signal h_cnt : std_logic_vector(10 downto 0) := (others => '0');
	signal v_cnt : std_logic_vector(10 downto 0) := (others => '0');

	-- Constants for screen dimensions
	constant h_back_porch  : integer := 64;
	constant h_active      : integer := 800;
	constant h_front_porch : integer := 56;
	constant h_sync_length : integer := 120;
	constant h_length      : integer := 1040;

	constant v_back_porch  : integer := 23;
	constant v_active      : integer := 600;
	constant v_front_porch : integer := 37;
	constant v_sync_length : integer := 6;
	constant v_length      : integer := 666;

	-- Sprite dimensions
	constant sprite_width  : integer := 128;
	constant sprite_height : integer := 128;

	-- Sprite position (centered on screen)
	constant sprite_x_start : integer := (h_active - sprite_width) / 2;
	constant sprite_y_start : integer := (v_active - sprite_height) / 2;

	-- Memory addresses
	signal adr_nb_1 : std_logic_vector(13 downto 0) := (others => '0');
	signal color_nb_1 : std_logic_vector(11 downto 0) := (others => '0');

begin
	video_en <= horizontal_en AND vertical_en;

	-- ROM instance
	ROM_p1 : entity work.ROM_COMP_1 port map (
		address => adr_nb_1,
		clock => CLK_50,
		q => color_nb_1
	);

	vga_square: process
	begin
		wait until rising_edge(CLK_50);

		-- Default color (black)
		color <= "000000000000";

		-- Display sprite at the center of the screen
		if (v_cnt >= v_back_porch + sprite_y_start and v_cnt < v_back_porch + sprite_y_start + sprite_height and
			h_cnt >= h_back_porch + sprite_x_start and h_cnt < h_back_porch + sprite_x_start + sprite_width) then
			color <= color_nb_1;

				adr_nb_1 <= adr_nb_1 + 1;

		end if;

		-- Generate Horizontal Sync
		if (h_cnt <= h_length-1) and (h_cnt >= h_length - h_sync_length) then
			h_sync <= '0';
		else
			h_sync <= '1';
		end if;

		-- Generate Vertical Sync
		if (v_cnt <= v_length-1) and (v_cnt >= v_length - v_sync_length) then
			v_sync <= '0';
		else
			v_sync <= '1';
		end if;

		-- Reset Horizontal Counter
		if (h_cnt = h_length - 1) then
			h_cnt <= (others => '0');
		else
			h_cnt <= h_cnt + 1;
		end if;

		-- Reset Vertical Counter
		if (v_cnt = v_length - 1) and (h_cnt = h_length - 1) then
			v_cnt <= (others => '0');
		elsif (h_cnt = h_length - 1) then
			v_cnt <= v_cnt + 1;
		end if;

		-- Generate Horizontal Data
		if (h_cnt >= h_back_porch and h_cnt < h_back_porch + h_active) then
			horizontal_en <= '1';
		else
			horizontal_en <= '0';
		end if;

		-- Generate Vertical Data
		if (v_cnt >= v_back_porch and v_cnt < v_back_porch + v_active) then
			vertical_en <= '1';
		else
			vertical_en <= '0';
		end if;

		-- Assign pins to color VGA
		RED(0) <= color(8) and video_en;   -- Red LSB
		RED(1) <= color(9) and video_en;
		RED(2) <= color(10) and video_en;
		RED(3) <= color(11) and video_en;  -- Red MSB
		GREEN(0) <= color(4) and video_en; -- Green LSB
		GREEN(1) <= color(5) and video_en;
		GREEN(2) <= color(6) and video_en;
		GREEN(3) <= color(7) and video_en; -- Green MSB
		BLUE(0) <= color(0) and video_en;  -- Blue LSB
		BLUE(1) <= color(1) and video_en;
		BLUE(2) <= color(2) and video_en;
		BLUE(3) <= color(3) and video_en;  -- Blue MSB

		-- Sync signals
		SYNC(1) <= h_sync;
		SYNC(0) <= v_sync;

		-- reset adr when h_cnt and v_cnt at end of screen
		if (h_cnt >= h_length - 1) AND (v_cnt >= v_length - 1) then
			adr_nb_1 <= "00000000000000";
		end if;
	end process vga_square;
end Behavioral;
