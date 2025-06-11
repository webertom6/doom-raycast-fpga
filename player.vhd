library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
use work.SharedTypes.all;

entity Player is port
(
	CLK_50	: in std_logic;
	CTRL	: in std_logic_vector(11 downto 0);
	GRID_MAP : in matrix_grid;
	player_active : in std_logic;

	position_x 	: out signed(31 downto 0);
	position_Y 	: out signed(31 downto 0);
	direction_x 	: out signed(31 downto 0);
	direction_y 	: out signed(31 downto 0);
	plane_x 	: out signed(31 downto 0);
	plane_y 	: out signed(31 downto 0);
	
	select_pressed : out std_logic;
	WIN : out std_logic
);
end entity Player;

architecture PlayerArch of Player is

	 function getGridIndexPlus(a, b: signed(31 downto 0)) return signed is
        variable result: signed(31 downto 0);
    begin
        result := a + shift_right(b, 3) + to_signed(6536, 32); -- last term = hitbox
        return result(31 downto 16); -- returns the integer part, i.e the next index of the grid
    end;

	 function getGridIndexMinus(a, b: signed(31 downto 0)) return signed is
        variable result: signed(31 downto 0);
    begin
        result := a - shift_right(b, 3) - to_signed(6536, 32);
        return result(31 downto 16); -- returns the integer part, i.e the previous index of the grid
    end;
--
	--controller signals : 
	signal B , YBT, SLCT, STRT, UP_CROSS, DOWN_CROSS, LEFT_CROSS, RIGHT_CROSS, ABT, XBT, LBT, RBT : std_logic;
	
	-- counter signals
	signal play_counter : integer range 0 to 5000000 := 0;

	constant speed : signed(31 downto 0) := to_signed(13106, 32); -- speed = 0.25

	constant sinus : signed(31 downto 0) := to_signed(3275, 32);
	constant cosinus : signed(31 downto 0) := to_signed(65454, 32);
	
	signal prev_select : std_logic := '0';

	begin

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
		
		player : process (CLK_50)
			variable position_x_update : signed(31 downto 0) := to_signed(229376, 32);
			variable position_y_update : signed(31 downto 0) := to_signed(360448, 32);
			
			variable direction_x_update : signed(31 downto 0) := to_signed(65536, 32); -- =  1.0
			variable direction_y_update : signed(31 downto 0) := to_signed(0, 32); -- =  0.0

			variable plane_x_update : signed(31 downto 0) := to_signed(0, 32); -- =  0.0
			variable plane_y_update : signed(31 downto 0) := to_signed(-65536, 32); -- =  0.0

			variable old_direction_x : signed(31 downto 0) := to_signed(0, 32);
			variable old_plane_x : signed(31 downto 0) := to_signed(0, 32);
			
			variable pX			 : signed(15 downto 0)  := "0000000000000000";
			variable pY        : signed(15 downto 0)  := "0000000000000000";

		begin
			if (rising_edge(CLK_50)) then
			   if (player_active = '1') then
					if (play_counter >= 5000000 - 1) then
						play_counter <= 0;

						-- GOING FORWARD IN FRONT OF THE PLAYER
						if (UP_CROSS = '1') then
							pX := getGridIndexPlus(position_x_update, direction_x_update);
							pY := getGridIndexPlus(position_y_update, direction_y_update);
							if (to_integer(pX) = 10 and to_integer(pY) = 5) then 
								WIN <= '1';
							else 
								WIN <= '0';
							end if;
							if(GRID_MAP(to_integer(pX), to_integer(pY)) = 0) then
									position_x_update := position_x_update + fixedPointMul(direction_x_update, speed);
									position_y_update := position_y_update + fixedPointMul(direction_y_update, speed);
							end if;
						end if;

						-- GOING BACKWARDS IN FRONT OF THE PLAYER
						if (DOWN_CROSS = '1') then
							pX := getGridIndexMinus(position_x_update, direction_x_update);
							pY := getGridIndexMinus(position_y_update, direction_y_update);
							if (to_integer(pX) = 10 and to_integer(pY) = 5) then 
								WIN <= '1';
							else 
								WIN <= '0';
							end if;
							if(GRID_MAP(to_integer(pX), to_integer(pY)) = 0) then
								position_x_update := position_x_update - fixedPointMul(direction_x_update, speed);
								position_y_update := position_y_update - fixedPointMul(direction_y_update, speed);
							end if;
						end if;
						
						-- ROTATING THE PLAYER RIGHT
						if (ABT = '1') then
							old_direction_x := direction_x_update;
							old_plane_x := plane_x_update;

							direction_x_update := fixedPointMul(direction_x_update, cosinus) + fixedPointMul(direction_y_update, sinus);
							direction_y_update := fixedPointMul(direction_y_update, cosinus) - fixedPointMul(old_direction_x, sinus);

							plane_x_update := fixedPointMul(plane_x_update, cosinus) + fixedPointMul(plane_y_update, sinus);
							plane_y_update := fixedPointMul(plane_y_update, cosinus) - fixedPointMul(old_plane_x, sinus);
						end if;
						
						-- ROTATING THE PLAYER LEFT
						if (YBT = '1') then
							old_direction_x := direction_x_update;
							old_plane_x := plane_x_update;

							direction_x_update := fixedPointMul(direction_x_update, cosinus) - fixedPointMul(direction_y_update, sinus);
							direction_y_update := fixedPointMul(direction_y_update, cosinus) + fixedPointMul(old_direction_x, sinus);

							plane_x_update := fixedPointMul(plane_x_update, cosinus) - fixedPointMul(plane_y_update, sinus);
							plane_y_update := fixedPointMul(plane_y_update, cosinus) + fixedPointMul(old_plane_x, sinus);
						end if;

					else
						play_counter <= play_counter + 1;
					end if;
						
				
				position_x <= position_x_update;
				position_Y <= position_y_update;
				direction_x <= direction_x_update;
				direction_y <= direction_y_update;
				plane_x <= plane_x_update;
				plane_y <= plane_y_update;
				
				else
					position_x_update  := to_signed(229376, 32);
					position_y_update := to_signed(360448, 32);
					direction_x_update := to_signed(65536, 32);  -- 1.0
					direction_y_update := to_signed(0, 32);      -- 0.0
					plane_x_update     := to_signed(0, 32);      -- 0.0
					plane_y_update     := to_signed(-65536, 32); -- -1.0
					old_direction_x  := to_signed(0, 32);
					old_plane_x  := to_signed(0, 32);
					pX	:= "0000000000000000";
					pY := "0000000000000000";
					
					WIN <= '0';
					position_x <= position_x_update;
					position_Y <= position_y_update;
					direction_x <= direction_x_update;
					direction_y <= direction_y_update;
					plane_x <= plane_x_update;
					plane_y <= plane_y_update;
				
				end if;
			end if;
		end process player;

end architecture PlayerArch;
