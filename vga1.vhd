library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_ARITH.ALL;
use ieee.std_logic_UNSIGNED.ALL;

entity vga1 is port
	(
	D1			: in std_logic;
	L1			: out std_logic := '0';
	CLK_SNES	: buffer std_logic := '0';		-- SNES clock);

	-- VGA display
	CLK_50 	: in std_logic;
	RED		: buffer std_logic_vector(3 downto 0);
	GREEN	: buffer std_logic_vector(3 downto 0);  
	BLUE	: buffer std_logic_vector(3 downto 0); 			
	SYNC	: out std_logic_vector(1 downto 0)
	);
end entity vga1;

-- GAME ARCHITECTURE --
architecture game_arch of vga1 is

	signal ctrl1	: std_logic_vector(11 downto 0);

	
begin
	
	vga_ent : entity work.game1
	port map(	CLK_50 	=> CLK_50,
				RED 	=> RED,
                GREEN 	=> GREEN,
                BLUE 	=> BLUE,
                SYNC 	=> SYNC, 
				CTRL 	=> ctrl1

			);

	clocks_ent : entity work.clocks
	port map(	CLK_50 		=> CLK_50,
				CLK_SNES 	=> CLK_SNES
				);

	ctrl1_ent : entity work.snes
	port map(	CLK		=> CLK_SNES,
				DATA 	=> D1,
				LATCH	=> L1,
				CTRL 	=> ctrl1
				);

end architecture game_arch;