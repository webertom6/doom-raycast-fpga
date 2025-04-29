library ieee;
use ieee.std_logic_1164.ALL;
use work.shared_types.all;
use ieee.numeric_std.all;

entity game is port
	(
	
	CLK_PLAYER	: buffer std_logic := '0';		
	
	-- SNES controller
	D1			: in std_logic;
	L1			: out std_logic := '0';
	CLK_SNES	: buffer std_logic := '0';		

	-- VGA display
	CLK_50 	: in std_logic;
	RED		: buffer std_logic_vector(3 downto 0);
	GREEN	: buffer std_logic_vector(3 downto 0);  
	BLUE	: buffer std_logic_vector(3 downto 0); 			
	SYNC	: out std_logic_vector(1 downto 0)
	);
end entity game;

-- GAME ARCHITECTURE --
architecture game_arch of game is
	-- SNES SIGNALS 
	signal ctrl1	: std_logic_vector(11 downto 0);

	-- CLOCKS
	signal sclk_snes 		: std_logic := '0';
	signal sclk_player 		: std_logic := '0';
	
	signal CLK_RAYCAST : std_logic := '0';

	--PLAYERS POSITIONS AND DIRECTIONS 
	signal player_x : std_logic_vector(15 downto 0) := std_logic_vector(to_signed(896, 16));-- represent 3.5
	signal player_y : std_logic_vector(15 downto 0) := std_logic_vector(to_signed(896, 16));
	-- état du jeu
	type game_state_type is (menu, game);
	signal game_state : game_state_type := menu;
	signal start_pressed : std_logic :='0';
	signal select_pressed : std_logic :='0';
	signal color : std_logic_vector(11 downto 0) := (others => '0');
	signal menu_active : std_logic :='1';
	signal vga_active : std_logic := '0';
	signal player_active : std_logic :='0';
	signal raycast_active : std_logic := '0';
	signal RED_menu, GREEN_menu, BLUE_menu : std_logic_vector(3 downto 0);
	signal RED_game, GREEN_game, BLUE_game : std_logic_vector(3 downto 0);
	signal SYNC_menu, SYNC_game : std_logic_vector(1 downto 0);
	  
   signal posX  : signed(15 downto 0) := to_signed(896, 16);
	signal posY  : signed(15 downto 0) := to_signed(896, 16);	--raycast
   signal dirX  : signed(15 downto 0) := to_signed(-256, 16);
	signal dirY  : signed(15 downto 0) := to_signed(0, 16);
   signal planeX : signed(15 downto 0) := to_signed(0, 16);
	signal planeY : signed(15 downto 0) := to_signed(167, 16);
	signal rayDirX     : signed_array;
   signal rayDirY     : signed_array;
	signal DrawStart   : int_ray_array;
	signal DrawEnd   : int_ray_array;
	signal HIT         : std_logic_vector(49 downto 0) := (others => '0');
	signal GRID_MAP    : matrix_grid := (
		(1, 1, 1, 1, 1, 1, 1, 1),
		(1, 0, 0, 0, 0, 0, 0, 1),
		(1, 0, 1, 1, 1, 0, 0, 1),
		(1, 0, 1, 0, 1, 0, 0, 1),
		(1, 0, 1, 0, 1, 0, 0, 1),
		(1, 0, 0, 0, 0, 0, 0, 1),
		(1, 1, 1, 1, 1, 1, 1, 1)
    );
	 
	 -- test
		signal ray_index     : integer range 0 to 779 := 0;
		signal ray_busy      : std_logic := '0'; -- indique que le rayon est en cours de traitement


	
	
begin

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
	 
	vga_ent : entity work.vga
		port map( vga_active => vga_active,	
					ray_index => ray_index,
					CLK_50 	=> CLK_50,
					RED 	=> RED_game,
					GREEN 	=> GREEN_game,
					BLUE 	=> BLUE_game,
					SYNC 	=> SYNC_game, 
					CTRL 	=> ctrl1,

					X 	=> posX,
					Y 	=> posY,
					
					DrawStart => DrawStart,
					DrawEnd => DrawEnd
				);

		clocks_ent : entity work.clocks
		port map(	CLK_50 		=> CLK_50,
					CLK_SNES 	=> CLK_SNES,
					CLK_PLAYER 	=> CLK_PLAYER
					);

		ctrl1_ent : entity work.snes
		port map(	CLK		=> CLK_SNES,
					DATA 	=> D1,
					LATCH	=> L1,
					CTRL 	=> ctrl1
					);

--		player_ent : entity work.player
--		port map(	CLK_PLAYER	=> CLK_PLAYER,
--					CTRL 		=> ctrl1,
--					X 			=> player_x,
--					Y 			=> player_y,
--					player_active => player_active,
--					select_pressed => select_pressed
--				);
--				

		player_ent : entity work.player
		port map(	CLK_PLAYER	=> CLK_PLAYER,
					CTRL 		=> ctrl1,
					player_active => player_active,
					select_pressed => select_pressed,
					GRID_MAP  => GRID_MAP,
					posX => posX,
					posY => posY,  
					dirX => dirX,  
					dirY => dirY,  
					planeX => planeX,
					planeY => planeY
				);
--		gen_rays: for i in 0 to 49 generate  --- raycast
--			ray_ent : entity work.raycast
--				port map (
--					CLK_50 	=> CLK_50,
--					raycast_active => raycast_active,
--					GRID_MAP        => GRID_MAP,
--					posX            => posX,
--					posY            => posY,
--					dirX            => dirX,
--					dirY            => dirY,
--					planeX          => planeX,
--					planeY          => planeY,
--					rayDirX         => std_logic_vector(rayDirX(i)),  -- Convert to std_logic_vector
--               rayDirY         => std_logic_vector(rayDirY(i)),  -- Convert to std_logic_vector
--					it 				 => i,
--					DrawStart       => DrawStart(i),
--					DrawEnd         => DrawEnd(i),
--					HIT             => HIT(i)
--			);
--		end generate;

		ray_inst: entity work.raycast
		port map (
			 CLK_50          => CLK_50,
			 raycast_active  => raycast_active,
			 ray_busy			=> ray_busy,
			 GRID_MAP        => GRID_MAP,
			 posX            => posX,
			 posY            => posY,
			 dirX            => dirX,
			 dirY            => dirY,
			 planeX          => planeX,
			 planeY          => planeY,
			 rayDirX         => std_logic_vector(rayDirX(ray_index)),
			 rayDirY         => std_logic_vector(rayDirY(ray_index)),
			 it              => ray_index,
			 DrawStart       => DrawStart(ray_index),
			 DrawEnd         => DrawEnd(ray_index),
			 HIT             => HIT(ray_index)
		);


    -- Activate the menu or game based on the current state
    process(CLK_50)
    begin
	 if rising_edge(CLK_50) then
        case game_state is
		  
				when menu =>
					RED   <= RED_menu;
					GREEN <= GREEN_menu;
					BLUE  <= BLUE_menu;
					SYNC  <= SYNC_menu;
            menu_active <= '1';
				player_active <= '0';
				 vga_active <= '0';
				 raycast_active <= '0';
				if start_pressed = '1' then
					game_state <= game;
				end if;

            when game =>
				RED   <= RED_game;
				GREEN <= GREEN_game;
				BLUE  <= BLUE_game;
				SYNC  <= SYNC_game;
				 menu_active <= '0';
				 player_active <= '1';
				 vga_active <= '1';
				 raycast_active <= '1';
				 
						 -- Passer au rayon suivant
				 if ray_index = 779 then
					  ray_index <= 0;
				 else
					  ray_index <= ray_index + 1;
				 end if;
				 if select_pressed = '1' then
					game_state <= menu;
				end if;

        end case;
	 end if;
    end process;
	 
--	 	process(CLK_Player) --update raycast ?
--		begin
--			if rising_edge(CLK_Player) then
--				for i in 0 to  49 loop
--					rayDirX(i) <= resize(dirX + planeX * to_signed(i*256, 16) * to_signed(11, 16), 16); -- 2*ray_size
--
--					rayDirY(i) <= resize(dirY + planeY * to_signed(i*256, 16) * to_signed(11, 16), 16); -- conversion des entiers en signed donc *256 car Q8.8
--
--				end loop;
--			end if;
--    end process;

		process(CLK_50)
		begin
			 if rising_edge(CLK_50) then
				  rayDirX(ray_index) <= resize(dirX + planeX * to_signed(ray_index * 256, 16) * to_signed(11, 6), 16);
				  rayDirY(ray_index) <= resize(dirY + planeY * to_signed(ray_index * 256, 16) * to_signed(11, 6), 16);
			 end if;
		end process;

end architecture game_arch;