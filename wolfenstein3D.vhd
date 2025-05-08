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
	signal posX 	: signed(31 downto 0) := to_signed(229376, 32); -- =  3.5
	signal posY 	: signed(31 downto 0) := to_signed(229376, 32); -- =  5.5
	signal dirX     : signed(31 downto 0) := to_signed(65536, 32); -- =  1.0
	signal dirY     : signed(31 downto 0) := to_signed(0, 32); -- =  0.0
	signal planeX 	: signed(31 downto 0) := to_signed(0, 32); -- =  0.0
	signal planeY 	: signed(31 downto 0) := to_signed(-65536, 32); -- = -1.0

	-- SNES SIGNALS 
	signal ctrl1	: std_logic_vector(11 downto 0);
	
	--declaration of the map
	constant GRID_MAP    : matrix_grid := (
		(1, 1, 1, 1, 1, 1, 1, 1),
		(1, 0, 0, 0, 0, 0, 0, 1),
		(1, 0, 1, 1, 1, 0, 0, 1),
		(1, 0, 1, 0, 1, 0, 0, 1),
		(1, 0, 1, 0, 1, 0, 0, 1),
		(1, 0, 0, 0, 0, 0, 0, 1),
		(1, 1, 1, 1, 1, 1, 1, 1)
    );

	-- TIMER SIGNALS
	constant s0 			: integer range 0 to 600 := 0; -- 0 to 60 seconds
	signal second 			: integer range 0 to 600 := s0;
	 
	 --signals for drawing
    signal wallHeight  : int_array;
	signal HIT         : std_logic_vector(63 downto 0);
	
	signal wallHeightDraw  : int_array;
	signal HITDraw         : std_logic_vector(63 downto 0);
	
	signal wallHeightInd : integer range 0 to 512;
	signal HITInd : std_logic;
	
	 
	signal counter 		: integer range 0 to 694445 := 0;
	signal isCalculing 	: std_logic := '0';
	signal ray 			: integer range 0 to 63 := 0;
	signal rayDirX 		: signed_array;
	signal rayDirY 		: signed_array;
	
	type stateRay_type is (START, COMPUTE, COPY);
	signal stateRay : stateRay_type := START;
	
	type state_type is (IDLE, PROCESS_INPUT, COMPUTE_DIRECTION, COMPUTE_RAY);
	signal state : state_type := IDLE;
	
	signal rayX  : signed(31 downto 0);
	signal rayY  : signed(31 downto 0);
	signal computationFinished : std_logic := '0';
	signal wakeUp : std_logic := '0';
	
	signal rayCounter : integer := 0;
	signal computeRayDir : std_logic := '0';
	signal tmp : signed(31 downto 0);
begin

	clocks_ent : entity work.clocks
	port map(	CLK_50 		=> CLK_50,
				CLK_SNES 	=> CLK_SNES,
				CLK_TIMER 	=> CLK_TIMER
				);

	timer_ent : entity work.Timer
	generic map (
		s0 => s0
	)
	port map(	CLK_TIMER 	=> CLK_TIMER,
				SECOND 		=> second
			);

	--instanciation of the entity
	ControllerEntity : entity work.Snes
	port map(	CLK		=> CLK_SNES,
				DATA 	=> D1,
				LATCH	=> L1,
				CTRL 	=> ctrl1
				);
				
	PlayerEntity : entity work.Player
	port map( 	CLK_50 	        => CLK_50,
				CTRL			=> ctrl1,
				position_x		=> posX,
				position_y		=> posY,
				direction_x		=> dirX,
				direction_y		=> dirY,
				plane_x		=> planeX,
				plane_y		=> planeY
			  );
			  
	RayEntity: entity work.Raycast
	port map( 	CLK         => CLK_50,

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
	port map( 	CLK_50			=> CLK_50,

				CTRL			=> ctrl1,

				wallHeightDraw 	=> wallHeightDraw,
				HITDraw 	   	=> HITDraw,

				SECOND 		=> second,

				RED				=> RED,
				GREEN			=> GREEN,
				BLUE			=> BLUE,
				SYNC			=> SYNC
			  );
		
	finite_state_machine: process(CLK_50)
		variable camX : signed(31 downto 0);
	begin
		if(rising_edge(CLK_50)) then
			case state is
				when IDLE =>
					wallHeightDraw <= wallHeight;
					HITDraw <= HIT;
					
				when PROCESS_INPUT =>
--					playerEnable <= '1';
--					if playerCompleted = '1' then
--						playerEnable <= '0';
--						state <= COMPUTE_DIRECTION;
--					end if;

					state <= COMPUTE_DIRECTION;
					
				when COMPUTE_DIRECTION =>

					camX := to_signed(((2 * rayCounter * 65536) / 64) - 65536, 32); --/!\ modify 10 by the number of ray
					rayDirX(rayCounter) <= dirX + fixedPointMul(planeX, camX);
					rayDirY(rayCounter) <= dirY + fixedPointMul(planeY, camX);
					if rayCounter >= 63 then
						rayCounter <= 0;
						state <= COMPUTE_RAY;
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
							if rayCounter >= 63 then
								rayCounter <= 0;
								state <= IDLE;
							else
								rayCounter <= rayCounter + 1;
							end if;
							stateRay <= START;
					end case;
			end case;
			
			if counter >= 694445 then
				counter <= 0;
				state <= PROCESS_INPUT;
			else
				counter <= counter + 1;
			end if;
		
		end if;
	end process finite_state_machine;
end architecture wolfenstein3DArch;
