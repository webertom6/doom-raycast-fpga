library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.SharedTypes.all;

entity raycast is port
	(
		CLK  					  : in std_logic;
      GRID_MAP     		  : in matrix_grid;   --matrix representing the map (1 = wall, 0 = free)
      posX         		  : in signed(31 downto 0); -- x coordinate of the player
		posY     	 		  : in signed(31 downto 0); -- y coordinate of the player
      rayDirX      		  : in signed(31 downto 0); -- x coordinate of the direction_ray_unity_vector
      rayDirY      		  : in signed(31 downto 0); -- y coordinate of the direction_ray_unity_vector
      wallHeight   		  : out integer range 0 to 512;  -- Percieved height of the wall in pixels
      HIT          		  : out std_logic; -- determine the orientation of the wall
		computationFinished : out std_logic; -- flag to copy the wall height value
		wakeUp		        : in std_logic -- flag to begin the raycast process
    );
end entity;

architecture RaycastArch of raycast is
	constant HEIGHT : signed(31 downto 0) := "00000001111101000000000000000000"; --500
	
	-- state machine of the raycast process to compute the percieved wallHeight
	type state_type is (IDLE, INIT, DDA, CHECK, FINISH, CALCRAY1_INIT, CALCRAY1_WAIT, CALCRAY2_INIT, CALCRAY2_WAIT, PERPWALLDIV_INIT, PERPWALLDIV_WAIT);
	
	-- state machine begin's with IDLE state
	signal state        : state_type := IDLE;
	
	signal sideDistX    : signed(31 downto 0); -- length of the ray from the player until the next "x line"
	signal sideDistY    : signed(31 downto 0); -- length of the ray from the player until the next "y line"
	signal deltaDistX   : signed(31 downto 0); -- length of the ray between two "x lines"
	signal deltaDistY   : signed(31 downto 0); -- length of the ray between two "y lines"
	signal perpWallDist : signed(31 downto 0); -- distance between the camera plan and the wall
	signal stepX 	     : integer;  -- direction to step in x (1 or -1)
	signal stepY 	     : integer; -- direction to step in y (1 or -1)
	-- mapX and mapY determine in wich "box" of the map we are in
	signal mapX 	     : integer; -- x coordinate of the box
	signal mapY 	     : integer; -- y coordinate of the box
	signal sideHit 	  : std_logic; -- signal to determine if the wall we see is in front or on the side of us
	signal invRayDirX   : signed(31 downto 0); -- inverse of the ray direction x coord
	signal invRayDirY   : signed(31 downto 0); -- inverse of the ray direction y coord

	
	-- signals taking part in the division are initialized on 64 bits to keep precision
	signal denom  	 : STD_LOGIC_VECTOR (63 DOWNTO 0); -- denominator of the division in LPM_DIVIDE
	constant numer  : STD_LOGIC_VECTOR (63 DOWNTO 0) := x"0000000100000000"; -- numerator of the division in LPM_DIVIDE
	signal quotient : STD_LOGIC_VECTOR (63 DOWNTO 0); -- quotient of the division in LPM_DIVIDE
	signal remain   : STD_LOGIC_VECTOR (63 DOWNTO 0); -- remain of the division in LPM_DIVIDE
	signal counter  : integer :=0; -- counter for the divison
	
	signal temporary : signed(31 downto 0); -- intermidiate signal taking the result of the division
	
begin

	-- instanciation of the LPM_DIVIDE division
	DivEntity1: entity work.Division
	port map(
				 clock		=> CLK,
				 denom		=> denom,
				 numer		=> numer,
				 quotient	=> quotient,
				 remain		=> remain
			  );
	
	-- Raycsat process :
	
	-- Because the process needs to perform accurate computation of several values, 
	-- we use signed number on 32 bits with a fixed point on the 16th (Q16.16).
	
	raycast: process(CLK)
		variable temp : signed(31 downto 0) := (others => '0');
	begin
		if(rising_edge(CLK)) then
			case state is 
			-- State IDLE : initialize the signals then switch on the next state if the flag "wakeUp" is on.
				when IDLE =>
					computationFinished <= '0';
					sideDistX <= (others => '0');
					sideDistY <= (others => '0');
					deltaDistX <= (others => '0');
					deltaDistY <= (others => '0');
					perpWallDist <= (others => '0');
					temporary <= (others => '0');
					stepX <= 0;
					stepY <= 0;
					sideHit <= '0';
					mapX <= to_integer(posX(31 downto 16)); -- taking the bits from the 31th to the 16th because we only need the integer part of the number
					mapY <= to_integer(posY(31 downto 16)); 
						
					if wakeUp = '1' then
						state <= CALCRAY1_INIT;
					end if;
				
				-- State CALCRAY1_INIT : Assign rayDirX as the denomitator of the division compute in the next state
				when CALCRAY1_INIT =>
					denom <= std_logic_vector(resize(abs(rayDirX), 64));
					state <= CALCRAY1_WAIT;
				
				-- State CALCRAY1_WAIT : Assign the result of the divison after 20 clock cycles 
				-- 								to be sure to obtain the good result and not a truncated one.
				when CALCRAY1_WAIT =>
					if counter >= 20 then
						invRayDirX <= resize(signed(quotient), 32); -- resize the result of the division to perform next operations on 32 bits
						counter <= 0;
						state <= CALCRAY2_INIT;
					else
						counter <= counter + 1;
					end if;
				
				-- State CALCRAY2_INIT : Assign RayDirY as the denomitator of the division compute in the next state
				when CALCRAY2_INIT =>
					denom <= std_logic_vector(resize(abs(rayDirY), 64));
					state <= CALCRAY2_WAIT;
				
				-- State CALCRAY1_WAIT : Assign the result of the divison after 20 clock cycles 
				-- 								to be sure to obtain the good result and not a truncated one.
				when CALCRAY2_WAIT =>
					if counter >= 20 then
						invRayDirY <= resize(signed(quotient), 32); -- resize the result of the division to perform next operations on 32 bits
						counter <= 0;
						state <= INIT;
					else
						counter <= counter + 1;
					end if;
				
				-- State INIT : noyau de l'algo mais aller revoir pour expliquer correctement
				when INIT =>
					if rayDirX < 0 then
						deltaDistX <= invRayDirX;
						stepX <= -1;
						temp := posX - toFixedPoint(mapX);
						sideDistX <= fixedPointMul(temp, invRayDirX);
					else
						deltaDistX <= invRayDirX;
						stepX <= 1;
						temp := toFixedPoint(mapX + 1) - posX;
						sideDistX <= fixedPointMul(temp, invRayDirX);
					end if;
						
					if rayDirY < 0 then
						deltaDistY <= invRayDirY;
						stepY <= -1;
						temp := posY - toFixedPoint(mapY);
						sideDistY <= fixedPointMul(temp, invRayDirY);
					else
						deltaDistY <= invRayDirY;
						stepY <= 1;
						temp := toFixedPoint(mapY+1) - posY;
						sideDistY <= fixedPointMul(temp, invRayDirY);
					end if;
					state <= DDA;
				
				
				-- State DDA : pareil qu'au dessus
				when DDA =>
					if sideDistX < sideDistY then
						sideDistX <= sideDistX + deltaDistX;
						mapX <= mapX + stepX;
						sideHit <= '0';
					else
						sideDistY <= sideDistY + deltaDistY;
						mapY <= mapY + stepY;
						sideHit <= '1';
					end if;
					state <= CHECK;
				
				-- State CHECK : check if a colision occurs between the player and a wall
				when CHECK =>
					if GRID_MAP(mapX, mapY) > 0 then
							if sideHit = '0' then
								perpWallDist <= sideDistX - deltaDistX;
							else
								perpWallDist <= sideDistY - deltaDistY;
							end if;
							state <= PERPWALLDIV_INIT;
					else
						state <= DDA;
					end if;
				
			  -- State PERPWALLDIV_INIT : assign perpWallDist as the denominator of the division compute in the next state	
				when PERPWALLDIV_INIT =>
					if perpWallDist < 65536 then
--						wallHeight <= 512; -- inutile on le fait dans le state suivant
						state <= FINISH;
					else
						denom <= std_logic_vector(resize(perpWallDist, 64));
						state <= PERPWALLDIV_WAIT;
					end if;
				
				-- State PERPWALLDIV_WAIT : Assign the result of the divison after 20 clock cycles 
				-- 								to be sure to obtain the good result and not a truncated one.
				when PERPWALLDIV_WAIT =>
					if counter >= 20 then
						temporary <= shift_left(resize(signed(quotient), 32), 9);
						counter <= 0;
						state <= FINISH;
					else
						counter <= counter + 1;
					end if;
				
				-- State Finish : Assign the result of the division to WallHeight
				when FINISH =>
					if perpWallDist < 65536 then -- If the distance between the wall and player is smaller than 1, the height of the wall is maximal
						wallHeight <= 512;
					else -- if not, the height of the wall is inversely proportionnal to distance between the player and the wall
						wallHeight <= to_integer(temporary(31 downto 16));
					end if;
					HIT <= sideHit;
					computationFinished <= '1';
					state <= IDLE;
			end case;
		end if;
	end process raycast;

end architecture RaycastArch;
