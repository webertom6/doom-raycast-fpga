library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_ARITH.ALL;
use ieee.std_logic_UNSIGNED.ALL;

entity player is port
	(
		CLK_PLAYER	: in std_logic; --Clock
		CTRL 		: in std_logic_vector(11 downto 0); -- SNES commands
		
		X	: out integer range 0 to 80 := 35; -- Player X position
		Y	: out integer range 0 to 70 := 35 -- Player Y position
	);
end entity player;

architecture player_arch of player is
	--variables : 
	signal B , YBT, SLCT, STRT, UP_CROSS, DOWN_CROSS, LEFT_CROSS, RIGHT_CROSS, ABT, XBT, LBT, RBT : std_logic;
	signal player_x : integer range 0 to 80 := 35; -- Scaled by 10 to represent 3.5
	signal player_y : integer range 0 to 70 := 35; -- Scaled by 10 to represent 3.5

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
	
	player : process
		-- Removed variable declarations as they are now signals
		-- variable player_x : integer range 0 to 80 := 35; -- Scaled by 10 to represent 3.5
		-- variable player_y : integer range 0 to 70 := 35; -- Scaled by 10 to represent 3.5
		-- variable player_angle : real range 0.0 to 360.0 := 0.0;

		begin

			wait until falling_edge(CLK_PLAYER);
			if(UP_CROSS = '1') then
				player_y <= player_y - 1; -- Adjusted for scaling
			end if;

			if(DOWN_CROSS = '1') then
				player_y <= player_y + 1; -- Adjusted for scaling
			end if;

			if(LEFT_CROSS = '1') then
				player_x <= player_x - 1; -- Adjusted for scaling
			end if;
			if(RIGHT_CROSS = '1') then
				player_x <= player_x + 1; -- Adjusted for scaling
			end if;

	end process player;

	X <= player_x; -- Output the player's X position
	Y <= player_y; -- Output the player's Y position

end player_arch;