--library ieee;
--use ieee.std_logic_1164.ALL;
--use ieee.numeric_std.all;
--use work.shared_types.all;
--
--
--entity raycast is port 
--	( 
--		CLK_PLAYER       : in std_logic;
--
--      -- Game map (assumed 2D array of integers)
--      GRID_MAP  : in matrix_grid;
--
--      -- Raycasting input values
--      posX, posY      : in signed(15 downto 0);
--      dirX, dirY      : in signed(15 downto 0);
--      planeX, planeY  : in signed(15 downto 0);
--      rayDirX, rayDirY : in std_logic_vector(15 downto 0);  -- Use std_logic_vector
--		it : in integer;
--		DrawStart : buffer integer;
--		DrawEnd : buffer integer;
--		HIT : out std_logic
--	);
--end raycast;
--
--architecture Behavioral of raycast is
--	constant HEIGHT : integer := 690;--690 en signed virgule fixe Q8.8 (10*69)
--	
--begin   -- problème : tourne à l'infini dans le process ? en tout cas j'ai arreté à 37min de compilation
--	raycast: process(CLK_PLAYER)
--		--signal
--		variable sideDistX : signed(31 downto 0) := to_signed(0, 32);
--		variable sideDistY : signed(31 downto 0) := to_signed(0, 32);
--		variable deltaDistX : signed(15 downto 0) := to_signed(0, 16);
--		variable deltaDistY : signed(15 downto 0) := to_signed(0, 16);
--		variable perpWallDist : signed(31 downto 0) := to_signed(0, 32);
--		
--		variable rayDirX_signed : signed(15 downto 0) := to_signed(0, 16);
--		variable rayDirY_signed : signed(15 downto 0) := to_signed(0, 16);
--		
--		variable stepX : integer := 0;
--		variable stepY : integer := 0;
--		variable mapX : integer := 0;
--		variable mapY : integer := 0;
--		
--		variable hit : std_logic := '0';
--		variable sideHit : std_logic := '0';
--		variable wallHeight : integer := 0;
--
--		begin
--			if(rising_edge(CLK_PLAYER)) then
--				rayDirX_signed := signed(rayDirX);
--				rayDirY_signed := signed(rayDirY);
--				mapX := to_integer(posX(15 downto 8));
--				mapY := to_integer(posY(15 downto 8));
--			
--				if rayDirX_signed = to_signed(0, 16) then
--					deltaDistX := to_signed(32767, 16); --nombre le plus grand en signed Q8.8
--				else
--					deltaDistX := to_signed(abs(256/to_integer(rayDirX_signed)), 16);
--				end if;
--
--				if rayDirY_signed = to_signed(0, 16) then
--					deltaDistY := to_signed(32767, 16);
--				else
--					deltaDistY := to_signed(abs(256/to_integer(rayDirY_signed)), 16);
--				end if;
--			
--			
--			
--				if rayDirX_signed < to_signed(0, 16) then
--					stepX := -1; 
--					sideDistX := resize(((posX - to_signed(mapX*256,16)) * deltaDistX) srl 8, 32);
--
--				else
--					stepX := 1;
--					sideDistX := resize(((to_signed((mapX+1)*256,16)) * deltaDistX) srl 8, 32);
--
--				end if;
--			
--				if rayDirY_signed < to_signed(0, 16) then
--					stepY := -1;
--					sideDistY := resize(((posY - to_signed(mapY*256,16)) * deltaDistY) srl 8, 32);
--
--				else
--					stepY := 1;
--					sideDistY := resize(((to_signed((mapY+1)*256,16)) * deltaDistY) srl 8, 32);
--
--				end if;
--				
--				hit := '0'; -- Reset hit
--			
--			
--				for i in 0 to 10 loop
--					if sideDistX < sideDistY then
--						sideDistX := sideDistX + resize(deltaDistX, 32);
--						mapX := mapX + stepX;
--						sideHit := '0';
--					else
--						sideDistY := sideDistY + resize(deltaDistY, 32);
--						mapY := mapY + stepY;
--						sideHit := '1';
--					end if;
--				
--					if mapX >= 0 and mapX < 7 and mapY >= 0 and mapY < 8 then
--						if GRID_MAP(mapX, mapY) > 0 then
--							hit := '1';
--							exit;
--						end if;
--					end if;
--				end loop;
--			
--				if sideHit = '0' then
--					perpWallDist := sideDistX - resize(deltaDistX, 32);
--				else
--					perpWallDist := sideDistY - resize(deltaDistY, 32);
--				end if;				
--			
--				wallHeight := HEIGHT / to_integer(perpWallDist srl 16);
--				
--				
--				drawStart <= - wallHeight / 2 + HEIGHT/2;
--			   if drawStart < 0 then
--					drawStart <= 0;
--				end if;
--				
--			   drawEnd <= wallHeight / 2 + HEIGHT/2;
--			   if drawEnd >= HEIGHT then
--					drawEnd <= HEIGHT - 1;
--				end if;	
--
--				HIT := hit;
--			end if;
--		end process raycast;	
--end architecture Behavioral;

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
use work.shared_types.all;

entity raycast is
    port (
        CLK_50 : in std_logic;
		  raycast_active : in std_logic;
		  ray_busy : out std_logic;
        -- Game map (assumed 2D array of integers)
        GRID_MAP : in matrix_grid;

        -- Raycasting input values
        posX, posY : in signed(15 downto 0);
        dirX, dirY : in signed(15 downto 0);
        planeX, planeY : in signed(15 downto 0);
        rayDirX, rayDirY : in std_logic_vector(15 downto 0);

        it : in integer; -- (non utilisé ici mais tu peux l'adapter)
        DrawStart : buffer integer;
        DrawEnd : buffer integer;
        HIT : out std_logic
    );
end raycast;

architecture Behavioral of raycast is

    constant HEIGHT : integer := 500;

    type state_type is (IDLE, INIT, STEP_DDA, CHECK_HIT, CALC_WALL, DONE);
    signal state : state_type := IDLE;
	 signal busy : std_logic := '0';


    signal rayDirX_signed, rayDirY_signed : signed(15 downto 0);
    signal sideDistX, sideDistY : signed(31 downto 0);
    signal deltaDistX, deltaDistY : signed(15 downto 0);
    signal perpWallDist : signed(31 downto 0);
    signal mapX, mapY : integer;
    signal stepX, stepY : integer;
    signal sideHit : std_logic := '0';
    signal hit1 : std_logic := '0';
    signal ray_step : integer := 0;
    signal wallHeight : integer;

begin

    process(CLK_50)
    begin
        if rising_edge(CLK_50) then
				ray_busy <= busy;

				if (raycast_active = '1') then 
					case state is

						 when IDLE =>
							  HIT <= '0';
							  busy <= '0';
							  if (it >= 0 AND raycast_active = '1') then
									-- Nouvelle demande de raycast
									busy <= '1';
									rayDirX_signed <= signed(rayDirX);
									rayDirY_signed <= signed(rayDirY);
									state <= INIT;
							  end if;

						 when INIT =>
							  -- Initialisation du rayon
							  mapX <= to_integer(posX(15 downto 8));
							  mapY <= to_integer(posY(15 downto 8));

							  if rayDirX_signed = to_signed(0, 16) then
									deltaDistX <= to_signed(32767, 16);
							  else
									deltaDistX <= to_signed(abs(256 / to_integer(rayDirX_signed)), 16);
							  end if;

							  if rayDirY_signed = to_signed(0, 16) then
									deltaDistY <= to_signed(32767, 16);
							  else
									deltaDistY <= to_signed(abs(256 / to_integer(rayDirY_signed)), 16);
							  end if;

							  if rayDirX_signed < to_signed(0, 16) then
									stepX <= -1;
									sideDistX <= resize(((posX - to_signed(mapX * 256, 16)) * deltaDistX), 32);
							  else
									stepX <= 1;
									sideDistX <= resize(((to_signed((mapX + 1) * 256, 16) - posX) * deltaDistX), 32);
							  end if;

							  if rayDirY_signed < to_signed(0, 16) then
									stepY <= -1;
									sideDistY <= resize(((posY - to_signed(mapY * 256, 16)) * deltaDistY), 32);
							  else
									stepY <= 1;
									sideDistY <= resize(((to_signed((mapY + 1) * 256, 16) - posY) * deltaDistY), 32);
							  end if;

							  hit1 <= '0';
							  ray_step <= 0;
							  state <= STEP_DDA;

						 when STEP_DDA =>
							  if sideDistX < sideDistY then
									sideDistX <= sideDistX + resize(deltaDistX, 32);
									mapX <= mapX + stepX;
									sideHit <= '0';
							  else
									sideDistY <= sideDistY + resize(deltaDistY, 32);
									mapY <= mapY + stepY;
									sideHit <= '1';
							  end if;
							  state <= CHECK_HIT;

						 when CHECK_HIT =>
							  if (mapX >= 0 and mapX < 7 and mapY >= 0 and mapY < 8) then
									if GRID_MAP(mapX, mapY) > 0 then
										 hit1 <= '1';
										 state <= CALC_WALL;
									else
--										 ray_step <= ray_step + 1;
--										 if ray_step < 20 then
--											  state <= STEP_DDA;
--										 else
											  state <= DONE;
--										 end if;
									end if;
							  else
									-- en dehors de la map
									state <= DONE;
							  end if;

						when CALC_WALL =>
						 if sideHit = '0' then
							  perpWallDist <= sideDistX - resize(deltaDistX, 32);
						 else
							  perpWallDist <= sideDistY - resize(deltaDistY, 32);
						 end if;

						 -- Calcul sécurisé de wallHeight
						 if to_integer(perpWallDist(31 downto 16)) > 0 then
							  wallHeight <= (HEIGHT * 256) / to_integer(perpWallDist(31 downto 16));
							  if wallHeight > HEIGHT then
									wallHeight <= HEIGHT;
							  end if;
						 else
							  wallHeight <= 0; 
						 end if;

						 
						 DrawStart <= (HEIGHT / 2) - (wallHeight / 2);
						 if DrawStart < 0 then
							  DrawStart <= 0;
						 end if;

						 DrawEnd <= (HEIGHT / 2) + (wallHeight / 2);
						 if DrawEnd >= HEIGHT then
							  DrawEnd <= HEIGHT - 1;
						 end if;

						 state <= DONE;


						 when DONE =>
							  HIT <= hit1;
							  busy <= '0';
							  state <= IDLE;
							  

						 when others =>
							  state <= IDLE;

					end case;
				end if;
        end if;
    end process;

end architecture Behavioral;
