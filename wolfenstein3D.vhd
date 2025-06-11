library ieee;
use IEEE.std_logic_1164.all;
use ieee.std_logic_UNSIGNED.ALL;
use ieee.numeric_std.all;
use work.SharedTypes.all;

entity wolfenstein3D is port
	(
		CLK_TIMER	: buffer std_logic;
		-- SNES controller
		D1			: in std_logic;
		L1			: out std_logic := '0';
		CLK_SNES	: buffer std_logic := '0';	
		
		--VGA port
		CLK_50	:	in std_logic;
		RED		: out std_logic_vector(3 downto 0);
		GREEN	: out std_logic_vector(3 downto 0);
		BLUE	: out std_logic_vector(3 downto 0);
		SYNC	: out std_logic_vector(1 downto 0)
	);
end entity wolfenstein3D;

architecture wolfenstein3DArch of wolfenstein3D is

	--player signals
	signal posX 	: signed(31 downto 0) := to_signed(229376, 32); -- 3,5
	signal posY 	: signed(31 downto 0) := to_signed(229376, 32); -- 3,5 
	signal dirX     : signed(31 downto 0) := to_signed(65536, 32); -- =  1.0
	signal dirY     : signed(31 downto 0) := to_signed(0, 32); -- =  0.0
	signal planeX 	: signed(31 downto 0) := to_signed(0, 32); -- =  0.0
	signal planeY 	: signed(31 downto 0) := to_signed(-65536, 32); -- = -1.0

	-- SNES SIGNALS 
	signal ctrl1	: std_logic_vector(11 downto 0);
	
	--declaration of the map
	constant GRID_MAP    : matrix_grid := (
	 (1, 1, 1, 1, 1, 1, 1, 1, 1, 1),
    (1, 0, 0, 0, 1, 0, 0, 0, 0, 1),
    (1, 0, 0, 0, 1, 0, 1, 1, 0, 1),
    (1, 0, 1, 0, 0, 0, 1, 0, 0, 1),
    (1, 0, 1, 1, 1, 0, 1, 0, 1, 1),
    (1, 0, 0, 0, 0, 0, 0, 0, 0, 1),
    (1, 1, 1, 0, 1, 1, 1, 1, 0, 1),
    (1, 0, 0, 0, 1, 0, 0, 1, 0, 1),
    (1, 0, 0, 0, 0, 0, 0, 0, 0, 1),
    (1, 1, 1, 1, 1, 1, 1, 1, 0, 1),
	 (1, 1, 1, 1, 1, 0, 0, 0, 0, 1),
	 (1, 1, 1, 1, 1, 1, 0, 0, 0, 1),
	 (1, 1, 1, 1, 1, 1, 1, 1, 1, 1)
    );
	 
	 -- TIMER SIGNALS
	constant s0 			: integer range 0 to 600 := 0; -- 0 to 60 seconds
	signal second 			: integer range 0 to 600 := s0;
	 
	 --signals for drawing
	constant NB_RAY : integer := 256; 
   signal wallHeight  : int_array;
	signal HIT         : std_logic_vector(NB_RAY downto 0);
	
	signal wallHeightDraw  : int_array;
	signal HITDraw         : std_logic_vector(NB_RAY downto 0);
	
	signal wallHeightInd : integer range 0 to 512;
	signal HITInd : std_logic;
	
	signal counter 		: integer range 0 to 694445 := 0;
	signal isCalculing 	: std_logic := '0';
	signal rayDirX 		: signed_array;
	signal rayDirY 		: signed_array;
	
	type stateRay_type is (START, COMPUTE, COPY);
	signal stateRay : stateRay_type := START;
	
	type state_playing_type is (IDLE, COMPUTE_DIRECTION, COMPUTE_RAY);
	signal state_playing : state_playing_type := IDLE;
	
	type game_state_type is (MENU, GAME);
	signal game_state : game_state_type := MENU;
	
	signal rayX  : signed(31 downto 0);
	signal rayY  : signed(31 downto 0);
	signal computationFinished : std_logic := '0';
	signal wakeUp : std_logic := '0';
	
	signal rayCounter : integer := 0;
	signal computeRayDir : std_logic := '0';
	signal tmp : signed(31 downto 0);
	
	-- signal for the state of the game
	signal color : std_logic_vector(11 downto 0) := (others => '0');
	signal start_pressed : std_logic :='0';
	signal select_pressed : std_logic :='0';
	signal RED_menu, GREEN_menu, BLUE_menu : std_logic_vector(3 downto 0);
	signal RED_game, GREEN_game, BLUE_game : std_logic_vector(3 downto 0);
	signal SYNC_menu, SYNC_game : std_logic_vector(1 downto 0);
	signal menu_active : std_logic :='1';
	signal game_active : std_logic :='0';
	signal WIN : std_logic := '0';
	signal counter_win : integer := 0;
	
	
begin

	clocks_ent : entity work.clocks
	port map(	CLK_50 	=> CLK_50,
				CLK_SNES 	=> CLK_SNES,
				CLK_TIMER 	=> CLK_TIMER
				);
				
	timer_ent : entity work.Timer
	generic map (
		s0 => s0
	)
	port map(	CLK_TIMER 	=> CLK_TIMER,
				SECOND 		=> second,
				game_active => game_active,
				WIN => WIN
			);
			
	menu_ent : entity work.menu
	port map( CLK_50  => CLK_50,
				  CTRL 	=> ctrl1,
				  color_menu => color,
				  actif        => menu_active,
				  start_pressed => start_pressed,
				  RED 	=> RED_menu,
				  GREEN 	=> GREEN_menu,
				  BLUE 	=> BLUE_menu,
				  SYNC 	=> SYNC_menu
    );

	--instanciation of the entity
	ControllerEntity : entity work.Snes
	port map(CLK		=> CLK_SNES,
				DATA 	=> D1,
				LATCH	=> L1,
				CTRL 	=> ctrl1
				);
				
	PlayerEntity : entity work.Player
	port map( 	CLK_50 	        => CLK_50,
				CTRL			=> ctrl1,
				GRID_MAP  => GRID_MAP,
				player_active  => game_active,
				position_x		=> posX,
				position_y		=> posY,
				direction_x		=> dirX,
				direction_y		=> dirY,
				plane_x		=> planeX,
				plane_y		=> planeY,
				WIN        => WIN
			  );
			  
	RayEntity: entity work.Raycast
	port map( CLK         => CLK_50,

				GRID_MAP    => GRID_MAP,

				posX        => posX,
				posY        => posY,

				rayDirX     => rayX,
				rayDirY     => rayY,
				wallHeight  => wallHeightInd,
				HIT         => HITInd,
				computationFinished => computationFinished,
				wakeUp		 => wakeUp
			  );

	VgaEntity: entity work.Vga
	generic map (
					nb_ray => NB_RAY
			)
	port map( 	CLK_50			=> CLK_50,
				CTRL			=> ctrl1,
				wallHeightDraw 	=> wallHeightDraw,
				HITDraw 	   	=> HITDraw,
				SECOND 		=> second,
				RED				=> RED_game,
				GREEN			=> GREEN_game,
				BLUE			=> BLUE_game,
				SYNC			=> SYNC_game,
				vga_active  => game_active,
				WIN         => WIN
				
			  );
		
	main_process: process(CLK_50)
		variable camX : signed(31 downto 0);
	begin
		if(rising_edge(CLK_50)) then
			case game_state is
			
				when MENU =>
					RED   <= RED_menu;
					GREEN <= GREEN_menu;
					BLUE  <= BLUE_menu;
					SYNC  <= SYNC_menu;
					menu_active <= '1';
					game_active <= '0';
					if (start_pressed = '1') then
						game_state <= GAME;
					end if;
					
				when GAME =>
					RED   <= RED_game;
					GREEN <= GREEN_game;
					BLUE  <= BLUE_game;
					SYNC  <= SYNC_game;
					menu_active <= '0';
					game_active <= '1';
					case state_playing is
						when IDLE =>
							wallHeightDraw <= wallHeight;
							HITDraw <= HIT;
							
						-- State COMPUTE_DIRECTION : compute the coordinates of all NB_RAY rays	
						when COMPUTE_DIRECTION =>
							camX := to_signed(((2 * rayCounter * 65536) / nb_ray) - 65536, 32); 
							rayDirX(rayCounter) <= dirX + fixedPointMul(planeX, camX);
							rayDirY(rayCounter) <= dirY + fixedPointMul(planeY, camX);
							if rayCounter >= nb_ray then
								rayCounter <= 0;
								state_playing <= COMPUTE_RAY;
							else
								rayCounter <= rayCounter + 1;
							end if;
						when COMPUTE_RAY =>
							case stateRay is
								when START =>
									rayX <= rayDirX(rayCounter);
									rayY <= rayDirY(rayCounter);
									wakeUp <= '1';
									stateRay <= COMPUTE;
								when COMPUTE =>
									wakeUp <= '0';
									if computationFinished = '1' then
										stateRay <= COPY;
									end if;
								when COPY =>
									wallHeight(rayCounter) <= wallHeightInd;
									HIT(rayCounter) <= HitInd;
									if rayCounter >= nb_ray then
										rayCounter <= 0;
										state_playing <= IDLE;
									else
										rayCounter <= rayCounter + 1;
									end if;
									stateRay <= START;
							end case;
					end case;
				
					if counter >= 694445 then
						counter <= 0;
						state_playing <= COMPUTE_DIRECTION;
					else
						counter <= counter + 1;
					end if;
					
					if (WIN = '1') then
						if counter_win >= 30000000 then
							game_state <= MENU;
							counter_win <= 0;
						else 
							counter_win <= counter_win + 1;
						end if;
				   end if;
					
			end case;
		end if;
	end process main_process;
end architecture wolfenstein3DArch;
