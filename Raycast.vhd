library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.SharedTypes.all;

entity Raycast is port
	(
		CLK  				: in std_logic;
		GRID_MAP     		: in matrix_grid;   --matrix representing the map (1 = wall, 0 = free)
		
		posX         		: in signed(31 downto 0); -- player position on axis x
		posY     	 		: in signed(31 downto 0); -- player position on axis y

		rayDirX      		: in signed(31 downto 0); -- x coordinate of the ray
		rayDirY      		: in signed(31 downto 0); -- y coordinate of the ray
		wallHeight   		: out integer range 0 to 512;  -- Percieved height of the wall in pixels
		HIT          		: out std_logic; -- determine the orientation of the wall
		computationFinished : out std_logic; -- flag
		wakeUp		        : in std_logic -- flag to begin the raycast process
	);
end entity;

architecture RaycastArch of Raycast is
	constant HEIGHT : signed(31 downto 0) := "00000001111101000000000000000000"; --500
	
	-- state machine of the raycast process to compute the percieved wallHeight
	type state_type is (IDLE, INIT, DDA, CHECK, COMPLETE, CALCRAY1_INIT, CALCRAY1_WAIT, CALCRAY2_INIT, CALCRAY2_WAIT, PERPWALLDIV_INIT, PERPWALLDIV_WAIT);
	signal state        : state_type := IDLE;
	
	signal sideDistX    : signed(31 downto 0);
	signal sideDistY    : signed(31 downto 0);
	signal deltaDistX   : signed(31 downto 0);
	signal deltaDistY   : signed(31 downto 0);
	signal perpWallDist : signed(31 downto 0);	
	signal stepX 	     : integer;
	signal stepY 	     : integer;
	signal mapX 	     : integer;
	signal mapY 	     : integer;	
	signal sideHit 	  : std_logic;
	signal invRayDirX   : signed(31 downto 0); -- inverse of the ray direction x coord
	signal invRayDirY   : signed(31 downto 0); -- inverse of the ray direction y coord
	
	signal clken    : std_logic := '0';

	-- signals taking part in the division are initialized on 64 bits to keep precision
	signal denom  	 : STD_LOGIC_VECTOR (63 DOWNTO 0);
	constant numer  : STD_LOGIC_VECTOR (63 DOWNTO 0) := x"0000000100000000";
	signal quotient : STD_LOGIC_VECTOR (63 DOWNTO 0);
	signal remain   : STD_LOGIC_VECTOR (63 DOWNTO 0);
	signal counter  : integer :=0;
	-- intermidiate signal taking the result of the division
	signal temporary : signed(31 downto 0);
	
begin
	DivEntity1: entity work.Division
	port map(
				 clock		=> CLK,
				 denom		=> denom,
				 numer		=> numer,
				 quotient	=> quotient,
				 remain		=> remain
			  );
			  
	raycast: process(CLK)
		variable temp : signed(31 downto 0) := (others => '0');
	begin
		if(rising_edge(CLK)) then
			case state is 
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
					mapX <= to_integer(posX(31 downto 16));
					mapY <= to_integer(posY(31 downto 16));
						
					if wakeUp = '1' then
						state <= CALCRAY1_INIT;
					end if;
					
				when CALCRAY1_INIT =>
					clken <= '1';
					denom <= std_logic_vector(resize(abs(rayDirX), 64));
					state <= CALCRAY1_WAIT;
				
				when CALCRAY1_WAIT =>
					if counter >= 20 then
						invRayDirX <= resize(signed(quotient), 32);
						counter <= 0;
						clken <= '0';
						state <= CALCRAY2_INIT;
					else
						counter <= counter + 1;
					end if;
					
				when CALCRAY2_INIT =>
					clken <= '1';
					denom <= std_logic_vector(resize(abs(rayDirY), 64));
					state <= CALCRAY2_WAIT;
				
				when CALCRAY2_WAIT =>
					if counter >= 20 then
						invRayDirY <= resize(signed(quotient), 32);
						counter <= 0;
						clken <= '0';
						state <= INIT;
					else
						counter <= counter + 1;
					end if;
					
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
					
				when PERPWALLDIV_INIT =>
					if perpWallDist < 65536 then
						wallHeight <= 512;
						state <= COMPLETE;
					else
						clken <= '1';
						denom <= std_logic_vector(resize(perpWallDist, 64));
						state <= PERPWALLDIV_WAIT;
					end if;
				
				when PERPWALLDIV_WAIT =>
					if counter >= 20 then
						temporary <= shift_left(resize(signed(quotient), 32), 9);
						counter <= 0;
						clken <= '0';
						state <= COMPLETE;
					else
						counter <= counter + 1;
					end if;
				
				when COMPLETE =>
					if perpWallDist < 65536 then
						wallHeight <= 512;
					else
						wallHeight <= to_integer(temporary(31 downto 16));
					end if;
					HIT <= sideHit;
					computationFinished <= '1';
					state <= IDLE;
			end case;
		end if;
	end process raycast;

end architecture RaycastArch;
