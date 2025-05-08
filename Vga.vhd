library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_UNSIGNED.ALL;
use ieee.numeric_std.ALL;
use work.SharedTypes.all;

entity Vga is 
port(   
        CLK_50	:	in std_logic;

        CTRL	:	in std_logic_vector(11 downto 0);

        -- Raycasting signals
        wallHeightDraw : in int_array;
        HITDraw : in std_logic_vector(63 downto 0);

        -- TIMER SIGNALS
		SECOND : in integer range 0 to 600; -- 0 to 60 seconds

        --VGA port
        RED		: out std_logic_vector(3 downto 0);
        GREEN	: out std_logic_vector(3 downto 0);
        BLUE	: out std_logic_vector(3 downto 0);
        SYNC	: out std_logic_vector(1 downto 0)
    );
end entity Vga;

architecture VgaArch of Vga is

    --display signals
    signal h_sync 			: std_logic;
    signal v_sync 			: std_logic;

    signal video_en 		: std_logic;
    signal horizontal_en 	: std_logic;
    signal vertical_en 		: std_logic;

    signal color : std_logic_vector(11 downto 0) := (others => '0');

    signal h_cnt : std_logic_vector(10 downto 0) := (others => '0');
    signal v_cnt : std_logic_vector(10 downto 0) := (others => '0');

    constant h_back_porch 	: integer := 64;
    constant h_active 		: integer := 800;
    constant h_front_porch 	: integer := 56;
    constant h_sync_length 	: integer := 120;
    constant h_length 		: integer := 1040;

    constant v_back_porch 	: integer := 23;
    constant v_active 		: integer := 600;
    constant v_front_porch 	: integer := 37;
    constant v_sync_length 	: integer := 6;
    constant v_length 		: integer := 666;	

    signal B , YBT, SLCT, STRT, UP_CROSS, DOWN_CROSS, LEFT_CROSS, RIGHT_CROSS, ABT, XBT, LBT, RBT : std_logic;

    -- Sprite heart dimensions
	constant heart_sprite_width  : integer := 32;
	constant heart_sprite_height : integer := 32;
	
	-- Sprite position
	constant nb_hearts : integer := 3;
	constant heart_sprite_x_start : integer := (h_active - heart_sprite_width * nb_hearts) - 10;
	constant heart_sprite_y_start : integer := (v_active - (80 / 2) - heart_sprite_height);

    -- timer 
	constant nb_digits : integer := 3; -- Number of digits for the timer (MM:SS)
	constant digit_width : integer := 32; -- Width of each digit sprite
	constant digit_height : integer := 32; -- Height of each digit sprite

	constant digit_x_start : integer := (h_active - digit_width) / 2;
	constant digit_y_start : integer := (v_active - (80 / 2) - digit_height);


    -- GUN SPRITE DIMENSIONS
	constant gun_frame_width  : integer := 67;
	constant gun_frame_height : integer := 95;
	constant gun_frame_x_start : integer := (h_active - gun_frame_width) / 2;
	constant gun_frame_y_start : integer := (v_active - 78 - gun_frame_height);

    -- Function to convert std_logic to std_logic_vector
	function std_logic_to_vector(signal_in : std_logic) return std_logic_vector is
    begin
        if signal_in = '1' then
            return "111111111111"; -- White
        else
            return "000000000000"; -- Black
        end if;
    end function;

    -- Timer signal
    type timer_digits_array is array (2 downto 0) of integer range 0 to 9;
	signal timer_digits : timer_digits_array;

	signal old_second : integer range 0 to 600 := 0; -- Previous second value


    -- Memory addresses
	type lut_color_heart_type is array (0 to 28) of std_logic_vector(11 downto 0); 
	constant lut_color_heart : lut_color_heart_type := (
		0 => "111111001100",
		1 => "100101000000",
		2 => "001010000000",
		3 => "101010000000",
		4 => "111100110011",
		5 => "000000000000",
		6 => "001111001000",
		7 => "011100100100",
		8 => "001111000100",
		9 => "111101110111",
	   10 => "100000000000",
	   11 => "111111111111",
	   12 => "111100101100",
	   13 => "111101010101",
	   14 => "011010001000",
	   15 => "010101000000",
	   16 => "011100101100",
	   17 => "111110010001",
	   18 => "101111001100",
	   19 => "101010001000",
	   20 => "101111001000",
	   21 => "111010000000",
	   22 => "101111000100",
	   23 => "010111000000",
	   24 => "110010000000",
	   25 => "110000000000",
	   26 => "111100111101",
	   27 => "001111000000",
	   28 => "110111000000"
	);
	
	type array_adr_heart_type is array (0 to nb_hearts - 1) of std_logic_vector(9 downto 0);
	type array_color_heart_type is array (0 to nb_hearts - 1) of std_logic_vector(4 downto 0);
	signal adr_heart_sprite : array_adr_heart_type := (others => (others => '0'));
	signal color_heart_sprite : array_color_heart_type := (others => (others => '0'));

    type array_adr_digit_type is array (0 to nb_digits - 1) of std_logic_vector(9 downto 0);
	type array_color_digit_type is array (0 to nb_digits - 1) of std_logic_vector(0 downto 0);
	type digits_adr_type is array (0 to 9) of array_adr_digit_type;
	type digits_color_type is array (0 to 9) of array_color_digit_type;

	signal digits_adr : digits_adr_type := (others => (others => (others => '0')));
	signal digits_color : digits_color_type := (others => (others => (others => '0')));

    type lut_color_frame_1_type is array (0 to 87) of std_logic_vector(11 downto 0); 
	constant lut_color_frame_1 : lut_color_frame_1_type := (
		0 => "001101010001",
		1 => "101100011010",
		2 => "110111100010",
		3 => "111110111011",
		4 => "001100011010",
		5 => "111110110011",
		6 => "011111010001",
		7 => "010010000000",
		8 => "010101101100",
		9 => "100000000000",
		10 => "010001000000",
		11 => "001101011001",
		12 => "101100110101",
		13 => "011110110011",
		14 => "110101100010",
		15 => "011110010110",
		16 => "011100011010",
		17 => "001110011110",
		18 => "110111011101",
		19 => "001011001100",
		20 => "100101101100",
		21 => "111101010001",
		22 => "111101011110",
		23 => "001110010110",
		24 => "110011001100",
		25 => "011101111011",
		26 => "111111011001",
		27 => "100010001000",
		28 => "011100111101",
		29 => "111111111111",
		30 => "011110011010",
		31 => "111111110111",
		32 => "111011101110",
		33 => "101101010001",
		34 => "000110101100",
		35 => "101111010101",
		36 => "101100010110",
		37 => "001000100010",
		38 => "111101010110",
		39 => "010001001000",
		40 => "011101010001",
		41 => "010101010101",
		42 => "111110010110",
		43 => "111100111001",
		44 => "001011001000",
		45 => "100010000000",
		46 => "001100010110",
		47 => "111111010001",
		48 => "111111010101",
		49 => "011001100110",
		50 => "011110111011",
		51 => "101011000100",
		52 => "111110011010",
		53 => "110100011110",
		54 => "110001001000",
		55 => "100110011001",
		56 => "101110111011",
		57 => "110011000100",
		58 => "101011001000",
		59 => "001111100010",
		60 => "111110111101",
		61 => "011101011110",
		62 => "001100010010",
		63 => "111100111101",
		64 => "111100110101",
		65 => "101000100100",
		66 => "101111011001",
		67 => "010101100010",
		68 => "010001000100",
		69 => "111000100100",
		70 => "000000000000",
		71 => "111101110111",
		72 => "111010100100",
		73 => "000110100100",
		74 => "001100110011",
		75 => "110100010110",
		76 => "110111101010",
		77 => "111101111011",
		78 => "101110011110",
		79 => "011101110111",
		80 => "100101100010",
		81 => "101100010010",
		82 => "011000100100",
		83 => "100111101010",
		84 => "101010101010",
		85 => "000100010001",
		86 => "001001001000",
		87 => "010111100010"
	);

	signal adr_gun_frame_1 : std_logic_vector(12 downto 0) := (others => '0');
	signal color_gun_frame_1: std_logic_vector(6 downto 0) := (others => '0');

	type lut_color_frame_2_type is array (0 to 170) of std_logic_vector(11 downto 0); 
	constant lut_color_frame_2 : lut_color_frame_2_type := (
		0 => "001101010001",
		1 => "101100011010",
		2 => "110111100010",
		3 => "111110111011",
		4 => "111110110011",
		5 => "001100011010",
		6 => "011111010001",
		7 => "111111011101",
		8 => "010010000000",
		9 => "100000000000",
		10 => "111101000100",
		11 => "101100111101",
		12 => "101100000000",
		13 => "110110101010",
		14 => "010001000000",
		15 => "101100110101",
		16 => "001100010001",
		17 => "111110110110",
		18 => "100100000000",
		19 => "001100100010",
		20 => "111100100010",
		21 => "011110110011",
		22 => "101010100010",
		23 => "111101110110",
		24 => "101101011001",
		25 => "011100000000",
		26 => "011110010110",
		27 => "111101011001",
		28 => "110101100010",
		29 => "101111011101",
		30 => "011100011010",
		31 => "011101000100",
		32 => "001011000100",
		33 => "001110011110",
		34 => "110111011101",
		35 => "011100110011",
		36 => "111101010001",
		37 => "100101101100",
		38 => "111111001100",
		39 => "111101100110",
		40 => "110100000000",
		41 => "111101011110",
		42 => "001111101110",
		43 => "110011001100",
		44 => "011101111011",
		45 => "000100100010",
		46 => "111111011001",
		47 => "101100011110",
		48 => "100010001000",
		49 => "111111111111",
		50 => "110100100010",
		51 => "111101010101",
		52 => "011110011010",
		53 => "111111110111",
		54 => "111011101110",
		55 => "000110101100",
		56 => "101101010001",
		57 => "101110001000",
		58 => "101111010101",
		59 => "011111011001",
		60 => "101100010110",
		61 => "010101000100",
		62 => "100111100010",
		63 => "111111111010",
		64 => "111100010001",
		65 => "111110010001",
		66 => "001000100010",
		67 => "111111101110",
		68 => "010001001000",
		69 => "111101010110",
		70 => "011110001000",
		71 => "111110101010",
		72 => "101110010110",
		73 => "010101010010",
		74 => "111100000000",
		75 => "011101010001",
		76 => "001101100110",
		77 => "010101010101",
		78 => "111110010110",
		79 => "001110010001",
		80 => "111100111001",
		81 => "111011101010",
		82 => "111110011001",
		83 => "111100110011",
		84 => "011100100010",
		85 => "001011001000",
		86 => "110101010110",
		87 => "100010000000",
		88 => "111011001100",
		89 => "011010101010",
		90 => "110101000100",
		91 => "101110011001",
		92 => "111100101100",
		93 => "111111010001",
		94 => "010100010110",
		95 => "111111010101",
		96 => "011001100110",
		97 => "001100000000",
		98 => "000110101010",
		99 => "011110111011",
		100 => "101011000100",
		101 => "010110001000",
		102 => "111110011010",
		103 => "110100011110",
		104 => "001101000100",
		105 => "111110001000",
		106 => "010100011010",
		107 => "110001001000",
		108 => "110111001100",
		109 => "100110011001",
		110 => "011111011101",
		111 => "101011001000",
		112 => "001111100010",
		113 => "000101100110",
		114 => "011011000100",
		115 => "011101011110",
		116 => "111110111101",
		117 => "010100000000",
		118 => "001100010010",
		119 => "000100010010",
		120 => "011110011110",
		121 => "111100111101",
		122 => "111100110101",
		123 => "101000100100",
		124 => "110100010001",
		125 => "001111101010",
		126 => "101111011001",
		127 => "010101100010",
		128 => "111100011010",
		129 => "010001000100",
		130 => "011001101010",
		131 => "110110001000",
		132 => "111000100010",
		133 => "111000100100",
		134 => "011101100110",
		135 => "000000000000",
		136 => "111101110111",
		137 => "111010100100",
		138 => "011111011010",
		139 => "000110100100",
		140 => "111100111110",
		141 => "101110111010",
		142 => "001100110011",
		143 => "100110101010",
		144 => "110111101110",
		145 => "100110101100",
		146 => "110100010110",
		147 => "110111101010",
		148 => "111101111011",
		149 => "101110011110",
		150 => "011101110111",
		151 => "011100010001",
		152 => "101111001100",
		153 => "111010100010",
		154 => "011110101010",
		155 => "111101110011",
		156 => "100101100010",
		157 => "101000101000",
		158 => "001111010101",
		159 => "001111001100",
		160 => "010111101010",
		161 => "101100010010",
		162 => "011000100100",
		163 => "100111101010",
		164 => "101010101010",
		165 => "100110011010",
		166 => "000100010001",
		167 => "111100111010",
		168 => "001100110110",
		169 => "001001001000",
		170 => "010111100010"
	);

	signal adr_gun_frame_2 : std_logic_vector(12 downto 0) := (others => '0');
	signal color_gun_frame_2: std_logic_vector(7 downto 0) := (others => '0');


begin
    video_en <= horizontal_en AND vertical_en;

    -- ROM instance
	gen_heart_sprite : for i in 0 to nb_hearts - 1 generate
        ROM_heart : entity work.ROM_COMP_HEART port map (
            address => adr_heart_sprite(i),
            clock => CLK_50,
            q => color_heart_sprite(i)
        );
    end generate;

    gen_digit_sprite : for i in 0 to nb_digits - 1 generate
        ROM_digit0 : entity work.ROMP_COMP_NB0 port map (
            address => digits_adr(0)(i),
            clock => CLK_50,
            q => digits_color(0)(i)
        );

        ROM_digit1 : entity work.ROMP_COMP_NB1 port map (
            address => digits_adr(1)(i),
            clock => CLK_50,
            q => digits_color(1)(i)
        );

        ROM_digit2 : entity work.ROMP_COMP_NB2 port map (
            address => digits_adr(2)(i),
            clock => CLK_50,
            q => digits_color(2)(i)
        );

        ROM_digit3 : entity work.ROMP_COMP_NB3 port map (
            address => digits_adr(3)(i),
            clock => CLK_50,
            q => digits_color(3)(i)
        );

        ROM_digit4 : entity work.ROMP_COMP_NB4 port map (
            address => digits_adr(4)(i),
            clock => CLK_50,
            q => digits_color(4)(i)
        );

        ROM_digit5 : entity work.ROMP_COMP_NB5 port map (
            address => digits_adr(5)(i),
            clock => CLK_50,
            q => digits_color(5)(i)
        );

        ROM_digit6 : entity work.ROMP_COMP_NB6 port map (
            address => digits_adr(6)(i),
            clock => CLK_50,
            q => digits_color(6)(i)
        );

        ROM_digit7 : entity work.ROMP_COMP_NB7 port map (
            address => digits_adr(7)(i),
            clock => CLK_50,
            q => digits_color(7)(i)
        );

        ROM_digit8 : entity work.ROMP_COMP_NB8 port map (
            address => digits_adr(8)(i),
            clock => CLK_50,
            q => digits_color(8)(i)
        );

        ROM_digit9 : entity work.ROMP_COMP_NB9 port map (
            address => digits_adr(9)(i),
            clock => CLK_50,
            q => digits_color(9)(i)
        );
    end generate;


    ROM_gun_frame_1 : entity work.ROM_COMP_FRAME_1 port map (
		address => adr_gun_frame_1,
		clock => CLK_50,
		q => color_gun_frame_1
	);
	ROM_gun_frame_2 : entity work.ROM_COMP_FRAME_2 port map (
		address => adr_gun_frame_2,
		clock => CLK_50,
		q => color_gun_frame_2
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

    update_timer_digits : process (SECOND)
	begin
		-- Convert the seconds to MM:SS format
		timer_digits(2) <= SECOND mod 10; -- Units of seconds
		timer_digits(1) <= (SECOND / 10) mod 6; -- Tens of seconds
		timer_digits(0) <= (SECOND / 60) mod 10; -- Units of minutes
		old_second <= SECOND; -- Update the old second value
	end process update_timer_digits;

    draw: process(CLK_50)
        variable i              : integer := 0;
        variable region_start   : integer := 0;
        variable region_end     : integer := 0;
        variable v_center       : integer := 0;
        variable v_top          : integer := 0;
        variable v_bottom       : integer := 0;
    begin

        if rising_edge(CLK_50) then
            ----- VGA COMMUNICATION -----

            color <= "011001100110";
                
            ----- GIVE COLOR TO THE PIXEL -----
            if (v_cnt >= v_back_porch + 10) and (v_cnt <= v_back_porch + 512 + 10) and (h_cnt >= h_back_porch + 10) and (h_cnt <= h_back_porch + h_active - 10) then
                i := to_integer(unsigned(h_cnt - h_back_porch)) / ((h_active-20) / 64);
                if (i >= 0) and (i < 64) then
                    region_start := h_back_porch + i * ((h_active-20) / 64);
                    region_end := region_start + ((h_active-20) / 64);
                    if (h_cnt >= region_start) and (h_cnt < region_end) then
                        v_center := v_back_porch + 10 + 256;
                        v_top := v_center - wallHeightDraw(i)/2;
                        v_bottom := v_center + wallHeightDraw(i)/2;
                        if v_cnt < v_top then
                            color <= "000000001111"; -- Top region
                        elsif v_cnt < v_bottom then
                            if HITDraw(i) = '0' then
                                color <= "000011110000"; -- Wall body
                            else
                                color <= "000011000000";
                            end if;
                        else
                            color <= "000000000000"; -- Bottom region
                        end if;
                    end if;
                end if;
            end if;


			if (RBT = '1') then
				if ( v_cnt >= v_back_porch + gun_frame_y_start AND v_cnt < v_back_porch + gun_frame_y_start + gun_frame_height
				AND h_cnt >= h_back_porch + gun_frame_x_start AND h_cnt < h_back_porch + gun_frame_x_start + gun_frame_width) then
			
					if color_gun_frame_2 /= "00110001" then
						color <= lut_color_frame_2(to_integer(unsigned(color_gun_frame_2)));
					end if;
					adr_gun_frame_2 <= adr_gun_frame_2 + 1;
				end if;
--				count_frame <= 0;


			else 
				if ( v_cnt >= v_back_porch + gun_frame_y_start AND v_cnt < v_back_porch + gun_frame_y_start + gun_frame_height
				AND h_cnt >= h_back_porch + gun_frame_x_start AND h_cnt < h_back_porch + gun_frame_x_start + gun_frame_width) then
			
					if color_gun_frame_1 /= "0011101" then
						color <= lut_color_frame_1(to_integer(unsigned(color_gun_frame_1)));
					end if;
					adr_gun_frame_1 <= adr_gun_frame_1 + 1;
				
				end if;
--				count_frame <= 0;

			end if;

            -- Draw the timer digits
			if old_second = SECOND then
				for i in 0 to nb_digits - 1 loop
					if (v_cnt >= v_back_porch + digit_y_start and v_cnt < v_back_porch + digit_y_start + digit_height and
						h_cnt >= h_back_porch + digit_x_start + i * (digit_width + 10) and h_cnt < h_back_porch + digit_x_start + i * (digit_width + 10) + digit_width) then
						
							
						-- Update the address for the digit sprite
						color <= std_logic_to_vector(digits_color(timer_digits(i))(i)(0)); -- Assign color based on the digit value

						digits_adr(timer_digits(i))(i) <= digits_adr(timer_digits(i))(i) + 1;
					end if;
				end loop;
			end if;

            -- Draw the hearts
			for i in 0 to nb_hearts - 1 loop
				if (v_cnt >= v_back_porch + heart_sprite_y_start and v_cnt < v_back_porch + heart_sprite_y_start + heart_sprite_height 
					and	h_cnt >= h_back_porch + heart_sprite_x_start + i * (heart_sprite_width + 0) 
					and h_cnt < h_back_porch + heart_sprite_x_start + i * (heart_sprite_width + 0) + heart_sprite_width) then
					
					color <= lut_color_heart(to_integer(unsigned(color_heart_sprite(i))));

					adr_heart_sprite(i) <= adr_heart_sprite(i) + 1;

				end if;
			end loop;
            
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

				for i in 0 to nb_hearts - 1 loop
					adr_heart_sprite(i) <= "0000000000";
				end loop;
				for i in 0 to nb_digits - 1 loop
					for j in 0 to 1 loop
						digits_adr(j)(i) <= "0000000000";
					end loop;
				end loop;
				adr_gun_frame_1 <= "0000000000000";
				adr_gun_frame_2 <= "0000000000000";
				-- adr_gun_frame_10 <= "0000000000000";
				-- adr_gun_frame_11 <= "0000000000000";
				-- adr_gun_frame_12 <= "0000000000000";
--				adr_gun_frame_13 <= "0000000000000";
--				adr_gun_frame_14 <= "0000000000000";
--				adr_gun_frame_15 <= "0000000000000";
			end if;
        end if;
    end process draw;
end architecture VgaArch;