library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

entity menu is port
	(
		CLK_50 	: in std_logic;		       
		CTRL      : in std_logic_vector(11 downto 0);              
		color_menu     : out std_logic_vector(11 downto 0);
		actif       : in std_logic;
		start_pressed : out std_logic;
		RED: out std_logic_vector(3 downto 0);
		GREEN: out std_logic_vector(3 downto 0);  
		BLUE: out std_logic_vector(3 downto 0); 			
		SYNC: out std_logic_vector(1 downto 0)
		);
end entity menu;

architecture Behavioral of menu is

   signal color : std_logic_vector(11 downto 0) := "000000000000";
	signal prev_start : std_logic := '0';
	signal h_sync : std_logic;
   signal v_sync : std_logic;
	signal h_cnt : unsigned(10 downto 0) := (others => '0');
   signal v_cnt : unsigned(10 downto 0) := (others => '0');

    constant h_back_porch : integer := 64;
    constant h_active : integer := 800;
    constant h_front_porch : integer := 56;
    constant h_sync_length : integer := 120;
    constant h_length : integer := 1040;

    constant v_back_porch : integer := 23;
    constant v_active : integer := 600;
    constant v_front_porch : integer := 37;
    constant v_sync_length : integer := 6;
    constant v_length : integer := 666;

    signal video_en : std_logic;
    signal horizontal_en : std_logic;
    signal vertical_en : std_logic;

    constant CHAR_WIDTH : integer := 8;
    constant CHAR_HEIGHT : integer := 8;
    constant CHAR_SPACING : integer := 2;

    type char_line is array(0 to 7) of std_logic_vector(7 downto 0);
    type font_rom_type is array(0 to 14) of char_line;
    constant font_rom : font_rom_type := (
        ("11110000", "10001000", "10000100", "10000100", "10000100", "10001000", "11110000", "00000000"), --D 0
        ("01110000", "10001000", "10000100", "10000100", "10000100", "10001000", "01110000", "00000000"), --O 1
        ("10000010", "11000110", "10101010", "10010010", "10000010", "10000010", "10000010", "00000000"), --M  2
        ("00000000", "00000000", "00110000", "00110000", "00000000", "00110000", "00110000", "00000000"), -- : 3
        ("01110000", "10001000", "10000000", "01110000", "00001000", "10001000", "01110000", "00000000"), --S  4
        ("11111000", "00100000", "00100000", "00100000", "00100000", "00100000", "00100000", "00000000"), --T  5
        ("01100000", "10010000", "10010000", "11110000", "10010000", "10010000", "10010000", "00000000"), --A  6
        ("11100000", "10010000", "10010000", "11100000", "10100000", "10010000", "10001000", "00000000"), --R  7
        ("10000000", "10000000", "10000000", "10000000", "10000000", "10000000", "11111000", "00000000"), --L  8
        ("11111000", "10000000", "10000000", "11110000", "10000000", "10000000", "11111000", "00000000"), --E  9
        ("00000000", "00000000", "00000000", "00000000", "00000000", "00000000", "00000000", "00000000"), -- espace  10
        ("11110000", "10001000", "10001000", "11110000", "10000000", "10000000", "10000000", "00000000"), --P  11
        ("10001000", "10001000", "01010000", "00100000", "00100000", "00100000", "00100000", "00000000"), --Y  12
        ("01110000", "10001000", "10000000", "10000000", "10000000", "10001000", "01110000", "00000000"), --C  13
		  ("00011000", "00011000", "00011000", "00011000", "00011000", "00011000", "10011000", "01111100") --J  14
    );

    type string_array is array(natural range <>) of integer;
    constant line1 : string_array := (11, 7, 9, 4, 4, 10, 4, 5, 6, 7, 5, 10, 5, 1, 10, 11, 8, 6, 12); -- PRESS START TO PLAY
  
    procedure draw_text(
        constant str : in string_array;
        constant x_offset : in integer;
        constant y_offset : in integer;
		  constant SCALE : in integer;
        constant color_val : in std_logic_vector(11 downto 0);
        signal color : out std_logic_vector(11 downto 0)
    ) is
    begin
        for i in 0 to str'length - 1 loop
            for row in 0 to 7 loop
                for col in 0 to 7 loop
                    for sx in 0 to SCALE - 1 loop
                        for sy in 0 to SCALE - 1 loop
                            if (h_cnt = x_offset + i * (CHAR_WIDTH * SCALE + CHAR_SPACING) + col * SCALE + sx) and
                               (v_cnt = y_offset + row * SCALE + sy) then
                                if font_rom(str(i))(row)(7 - col) = '1' then
                                    color <= color_val;
                                end if;
                            end if;
                        end loop;
                    end loop;
                end loop;
            end loop;
        end loop;
    end procedure;

begin

process(CLK_50)
begin
    if rising_edge(CLK_50) then
        if (actif = '1') then
			video_en <= horizontal_en AND vertical_en;
			color <= "011001100110";

            draw_text(line1, 170, 300, 3, "000001111100", color);

			if (h_cnt <= h_length-1) AND (h_cnt >= h_length - h_sync_length) then
				h_sync <= '0';
			else
				h_sync <= '1';
			end if;

			if (v_cnt <= v_length-1) AND (v_cnt >= v_length - v_sync_length) then
				v_sync <= '0';
			else
				v_sync <= '1';
			end if;

			if (h_cnt = h_length - 1) then
				h_cnt <= "00000000000";
			else
				h_cnt <= h_cnt + 1;
			end if;

			if (v_cnt = v_length - 1) AND (h_cnt = h_length - 1) then
				v_cnt <= "00000000000";
			elsif (h_cnt = h_length - 1) then
				v_cnt <= v_cnt + 1;
			else
				v_cnt <= v_cnt;
			end if;

			if (h_cnt >= 63 AND h_cnt <= 863) then
				horizontal_en <= '1';
			else
				horizontal_en <= '0';
			end if;

			if (v_cnt >= 24 AND v_cnt <= 623) then
				vertical_en <= '1';
			else
				vertical_en <= '0';
			end if;

			RED(0) <= color(8) AND video_en;
			RED(1) <= color(9) AND video_en;
			RED(2) <= color(10) AND video_en;
			RED(3) <= color(11) AND video_en;
			GREEN(0) <= color(4) AND video_en;
			GREEN(1) <= color(5) AND video_en;
			GREEN(2) <= color(6) AND video_en;
			GREEN(3) <= color(7) AND video_en;
			BLUE(0) <= color(0) AND video_en;
			BLUE(1) <= color(1) AND video_en;
			BLUE(2) <= color(2) AND video_en;
			BLUE(3) <= color(3) AND video_en;
			SYNC(1) <= h_sync;
			SYNC(0) <= v_sync;

           if (CTRL(3) = '1' and prev_start = '0') then
                start_pressed <= '1';
            else
                start_pressed <= '0';
					 prev_start <= CTRL(3);
            end if;
        else
            start_pressed <= '0';
        end if;
    end if;
end process;

end Behavioral;
