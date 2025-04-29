library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
use work.shared_types.all;


--entity player is port
--	(
--		CLK_PLAYER	: in std_logic; --Clock
--		CTRL 		: in std_logic_vector(11 downto 0); -- SNES commands
--		
--		X	: out integer range 0 to 80 := 35; -- Player X position
--		Y	: out integer range 0 to 70 := 35; -- Player Y position
--		player_active : in std_logic;
--		select_pressed : out std_logic
--	);
--end entity player;
--
--architecture player_arch of player is
--	--variables : 
--	signal B , YBT, SLCT, STRT, UP_CROSS, DOWN_CROSS, LEFT_CROSS, RIGHT_CROSS, ABT, XBT, LBT, RBT : std_logic;
--	signal player_x : integer range 0 to 80 := 35; -- Scaled by 10 to represent 3.5
--	signal player_y : integer range 0 to 70 := 35; -- Scaled by 10 to represent 3.5
--	signal prev_select : std_logic := '0';
--
--begin
--	B 		<=	CTRL(0);
--	YBT		<=	CTRL(1);
--	SLCT	<=	CTRL(2);
--	STRT	<=	CTRL(3);
--	UP_CROSS		<=	CTRL(4);
--	DOWN_CROSS 	<=	CTRL(5);
--	LEFT_CROSS	<=	CTRL(6);
--	RIGHT_CROSS	<=	CTRL(7);
--	ABT		<=	CTRL(8);
--	XBT		<=	CTRL(9);
--	LBT		<=	CTRL(10);
--	RBT		<=	CTRL(11);
--	
--	player : process
--		-- Removed variable declarations as they are now signals
--		-- variable player_x : integer range 0 to 80 := 35; -- Scaled by 10 to represent 3.5
--		-- variable player_y : integer range 0 to 70 := 35; -- Scaled by 10 to represent 3.5
--		-- variable player_angle : real range 0.0 to 360.0 := 0.0;
--
--		begin
--
--			wait until falling_edge(CLK_PLAYER);
--			if (player_active = '1') then 
--			
--				if(UP_CROSS = '1') then
--					player_y <= player_y - 1; -- Adjusted for scaling
--				end if;
--
--				if(DOWN_CROSS = '1') then
--					player_y <= player_y + 1; -- Adjusted for scaling
--				end if;
--
--				if(LEFT_CROSS = '1') then
--					player_x <= player_x - 1; -- Adjusted for scaling
--				end if;
--				if(RIGHT_CROSS = '1') then
--					player_x <= player_x + 1; -- Adjusted for scaling
--				end if;
--				if(SLCT = '1' and prev_select = '0') then
--					select_pressed <= '1';
--				else
--					select_pressed <= '0';
--				end if;
--			end if;
--	end process player;
--
--	X <= player_x; -- Output the player's X position
--	Y <= player_y; -- Output the player's Y position


--entity player is port
--	(
--		CLK_PLAYER	: in std_logic; --Clock
--		CTRL 		: in std_logic_vector(11 downto 0); -- SNES commands
--		GRID_MAP  : in matrix_grid;
--		
--		player_active : in std_logic;
--		select_pressed : out std_logic;
--		
--		X	: buffer std_logic_vector(15 downto 0); -- Player X position
--		Y	: buffer std_logic_vector(15 downto 0); -- Player Y position
--		
--		
--		posX   : out signed(15 downto 0);
--		posY   : out signed(15 downto 0);
--		dirX   : out signed(15 downto 0);
--		dirY   : out signed(15 downto 0);
--		planeX : out signed(15 downto 0);
--		planeY : out signed(15 downto 0)
--		
--	);
--end entity player;
--
--architecture player_arch of player is
--	--variables : 
--	signal B , YBT, SLCT, STRT, UP_CROSS, DOWN_CROSS, LEFT_CROSS, RIGHT_CROSS, ABT, XBT, LBT, RBT : std_logic;
--	signal prev_select : std_logic := '0';
--	
--	signal positionX: signed(15 downto 0) := to_signed(15360, 16); -- real converted in signed fixed point Q8.8
--	signal positionY: signed(15 downto 0) := to_signed(8960, 16);
--	signal directionX: signed(15 downto 0) := to_signed(-256, 16); -- -1 en Q8.8
--	signal directionY: signed(15 downto 0) := to_signed(0, 16);
--	signal planX: signed(15 downto 0) := to_signed(0, 16);
--	signal planY: signed(15 downto 0) := to_signed(169, 16); -- 0.66 converted to signed Q8.8
--
--begin
--	B 		<=	CTRL(0);
--	YBT		<=	CTRL(1);
--	SLCT	<=	CTRL(2);
--	STRT	<=	CTRL(3);
--	UP_CROSS		<=	CTRL(4);
--	DOWN_CROSS 	<=	CTRL(5);
--	LEFT_CROSS	<=	CTRL(6);
--	RIGHT_CROSS	<=	CTRL(7);
--	ABT		<=	CTRL(8);
--	XBT		<=	CTRL(9);
--	LBT		<=	CTRL(10);
--	RBT		<=	CTRL(11);
--	
--	player : process	
--		variable oldDirX : signed(15 downto 0) := to_signed(0, 16);
--		variable oldPlaneX : signed(15 downto 0) := to_signed(0, 16);
--		variable player_x : signed(15 downto 0) := to_signed(15360, 16); -- Scaled by 10 to represent 3.5
--		variable player_y : signed(15 downto 0) := to_signed(8960, 16); -- Scaled by 10 to represent 3.5
--		constant sin : signed(15 downto 0) := to_signed(13, 16);
--		constant cos : signed(15 downto 0) := to_signed(255, 16);
--		variable x_conv : std_logic_vector(15 downto 0) := (others => '0');
--		variable y_conv : std_logic_vector(15 downto 0) := (others => '0');
--		begin
--		
--			x_conv := X;
--			y_conv := Y;
--		
--			player_x := signed(x_conv); -- Get the player's X position from the player entity
--			player_y := signed(y_conv); -- Get the player's Y position from the player entity
--
--			wait until falling_edge(CLK_PLAYER);
--			if (player_active = '1') then 
--			
--				if(UP_CROSS = '1') then
--					if GRID_MAP(to_integer(positionX + directionX * to_signed(26, 16))/256, to_integer(positionY + directionY * to_signed(26, 16))/256) = 0 then
--						player_y := player_y - to_signed(256, 16); -- Adjusted for scaling
--						positionX <= positionX + resize(directionX * to_signed(26, 16), 16);
--						positionY <= positionY + resize(directionY * to_signed(26, 16), 16);
--					end if;
--				end if;
--
--				
--				if(DOWN_CROSS = '1') then
--					if GRID_MAP(to_integer(positionX - directionX * to_signed(26, 16))/256, to_integer(positionY - directionY * to_signed(26, 16))/256) = 0 then
--						player_y := player_y + to_signed(256, 16); -- Adjusted for scaling
--						positionX <= positionX - resize(directionX * to_signed(26, 16), 16);
--						positionY <= positionY - resize(directionY * to_signed(26, 16), 16);
--					end if;
--				end if;
--
--				
--				if(LEFT_CROSS = '1') then
--					player_x := player_x - to_signed(256, 16); -- Adjusted for scaling
--					oldDirX := DirectionX;
--					DirectionX <= resize(DirectionX * cos - DirectionY * (-sin), 16);
--					DirectionY <= resize(oldDirX *(-sin) - DirectionY * cos, 16);
--					
--					oldPlaneX := PlanX;
--					planX <= resize(planX * cos - planY * (-sin), 16);
--					planY <= resize(oldPlaneX * (-sin) - planY * cos, 16);
--					
--				end if;
--				
--				
--				if(RIGHT_CROSS = '1') then
--					player_x := player_x + to_signed(256, 16); -- Adjusted for scaling
--					oldDirX := DirectionX;
--					DirectionX <= resize(DirectionX * cos - DirectionY * sin, 16);
--					DirectionY <= resize(oldDirX *sin - DirectionY * cos, 16);
--					
--					oldPlaneX := PlanX;
--					planX <= resize(planX * cos - planY * sin, 16);
--					planY <= resize(oldPlaneX * sin - planY * cos, 16);
--				end if;
--				
--				
--				if(SLCT = '1' and prev_select = '0') then
--					select_pressed <= '1';
--				else
--					select_pressed <= '0';
--				end if;
--			end if;
--			X <= std_logic_vector(player_x); -- Output the player's X position
--			Y <= std_logic_vector(player_y); -- Output the player's Y position
--	end process player;
--
--	
--	posX   <= positionX;
--	posY   <= positionY;
--	dirX   <= directionX;
--	dirY   <= directionY;
--	planeX <= planX;
--	planeY <= planY;
--
--
--end player_arch;

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
use work.shared_types.all;

entity Player is port
	(
		player_active : in std_logic;
		select_pressed : out std_logic;
		CLK_PLAYER	: in std_logic;
		CTRL 			: in std_logic_vector(11 downto 0);
		GRID_MAP    : in matrix_grid;
		
		posX   : buffer signed(15 downto 0);
		posY   : buffer signed(15 downto 0);
		dirX   : buffer signed(15 downto 0);
		dirY   : buffer signed(15 downto 0);
		planeX : buffer signed(15 downto 0);
		planeY : buffer signed(15 downto 0)
		
	);
end entity Player;

architecture PlayerArch of Player is

    function fixedPointMul(a, b: signed(15 downto 0)) return signed is
        variable result: signed(31 downto 0);
    begin
        result := a * b;
        return result(23 downto 8);
    end;
	 
	 function getGridIndexPlus(a, b: signed(15 downto 0)) return signed is
        variable result: signed(15 downto 0);
    begin
        result := a + shift_right(b, 3);
        return result(15 downto 8);
    end;

	 function getGridIndexMinus(a, b: signed(15 downto 0)) return signed is
        variable result: signed(15 downto 0);
    begin
        result := a - shift_right(b, 3);
        return result(15 downto 8);
    end;
	 
	 signal prev_select : std_logic := '0';

	 
begin
	player: process(CLK_PLAYER)
		variable UP_CROSS, DOWN_CROSS, LEFT_CROSS, RIGHT_CROSS, SLCT : std_logic;
		variable oldDirX   : signed(15 downto 0) := "0000000000000000";
		variable oldPlaneX : signed(15 downto 0) := "0000000000000000";
		variable pX			 : signed(7 downto 0)  := "00000000";
		variable pY        : signed(7 downto 0)  := "00000000";
		constant sin 		 : signed(15 downto 0) := "0000000000001101"; --/!\ TRANSFORM 0.0499792  to Q8.8
		constant cos 		 : signed(15 downto 0) := "0000000011111111"; --/!\ TRANSFORM 0.99875026 to Q8.8
	begin
		if(rising_edge(CLK_PLAYER)) then
			if (player_active ='1') then 
				UP_CROSS		:=	CTRL(4);
				DOWN_CROSS 	:=	CTRL(5);
				LEFT_CROSS	:=	CTRL(6);
				RIGHT_CROSS	:=	CTRL(7);
				SLCT			:= CTRL(2);
				
				if(UP_CROSS ='1') then
					pX := getGridIndexPlus(posX, dirX);
					pY := getGridIndexPlus(posY, dirY);
					if(GRID_MAP(to_integer(pX), to_integer(pY)) = 0 ) then
						posX <= posX + shift_right(dirX, 3); --same as posX <= posX + dirX * 0.125
						posY <= posY + shift_right(dirY, 3);
					end if;
				end if;
				
				if(DOWN_CROSS ='1') then
					pX := getGridIndexMinus(posX, dirX);
					pY := getGridIndexMinus(posY, dirY);
					if(GRID_MAP(to_integer(pX), to_integer(pY)) = 0) then
						posX <= posX - shift_right(dirX, 3); --same as posX <= posX - dirX * 0.125
						posY <= posY - shift_right(dirY, 3);
					end if;
				end if;
				
				if(LEFT_CROSS ='1') then
					oldDirX   := dirX;
					dirX   <= fixedPointMul(dirX, cos) + fixedPointMul(dirY, sin);
					dirY   <= -(fixedPointMul(oldDirX, sin)) - fixedPointMul(dirY, cos);
						 
					oldPlaneX := planeX;
					planeX <= fixedPointMul(planeX, cos) + fixedPointMul(planeY, sin);
					planeY <= -(fixedPointMul(oldPlaneX, sin)) - fixedPointMul(planeY, cos);	 
				end if;
				
				if(RIGHT_CROSS ='1') then
					oldDirX   := dirX;
					dirX   <= fixedPointMul(dirX, cos) - fixedPointMul(dirY, sin);
					dirY   <= fixedPointMul(oldDirX, sin) - fixedPointMul(dirY, cos);
						 
					oldPlaneX := planeX;
					planeX <= fixedPointMul(planeX, cos) - fixedPointMul(planeY, sin);
					planeY <= fixedPointMul(oldPlaneX, sin) - fixedPointMul(planeY, cos);
				end if;
				if(SLCT = '1' and prev_select = '0') then
					select_pressed <= '1';
				else
					select_pressed <= '0';
				end if;
				prev_select <= SLCT;
			end if;
		end if;
	end process player;

end architecture PlayerArch;