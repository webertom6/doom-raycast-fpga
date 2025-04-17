library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_ARITH.ALL;
use ieee.std_logic_UNSIGNED.ALL;

entity player is 
generic(

		x0 : integer range 0 to 80;
		y0 : integer range 0 to 70
		);
port(
		CLK_PLAYER	: in std_logic; --Clock
		CTRL 		: in std_logic_vector(11 downto 0); -- SNES commands
		
		X	: out integer range 0 to 80; -- := 35; -- Player X position
		Y	: out integer range 0 to 70 -- := 35 -- Player Y position
	);
end entity player;

architecture player_arch of player is
	--variables : 
	signal B , YBT, SLCT, STRT, UP_CROSS, DOWN_CROSS, LEFT_CROSS, RIGHT_CROSS, ABT, XBT, LBT, RBT : std_logic;
	
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
			variable player_x_update : integer range 0 to 80 := x0; -- Scaled by 10 to represent 3.5
			variable player_y_update : integer range 0 to 70 := y0; -- Scaled by 10 to represent 3.5
		-- Removed variable declarations as they are now signals
		-- variable player_x_update : integer range 0 to 80 := 35; -- Scaled by 10 to represent 3.5
		-- variable player_y_update : integer range 0 to 70 := 35; -- Scaled by 10 to represent 3.5
		-- variable player_angle : real range 0.0 to 360.0 := 0.0;

		begin

			wait until falling_edge(CLK_PLAYER);
			if(UP_CROSS = '1') then
				player_y_update := player_y_update - 1; -- Adjusted for scaling
			end if;

			if(DOWN_CROSS = '1') then
				player_y_update := player_y_update + 1; -- Adjusted for scaling
			end if;

			if(LEFT_CROSS = '1') then
				player_x_update := player_x_update - 1; -- Adjusted for scaling
			end if;
			if(RIGHT_CROSS = '1') then
				player_x_update := player_x_update + 1; -- Adjusted for scaling
			end if;

			X <= player_x_update; -- Output the player's X position
			Y <= player_y_update; -- Output the player's Y position
	end process player;


end player_arch;