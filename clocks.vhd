library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

entity clocks is port
	(
		CLK_50 					: in std_logic;
		CLK_SNES 				: out std_logic := '0';
		CLK_PLAYER 				: out std_logic := '0'
	);
end entity clocks;

architecture clocks_arch of clocks is
	signal sclk_snes : std_logic := '0';
	signal sclk_player : std_logic := '0';
begin
clocks: process
	variable snes_cnt : integer range 0 to 300 := 0;
	variable player_cnt : integer range 0 to 1000 := 0;
begin
	wait until falling_edge(CLK_50);
	if (snes_cnt >= 299) then

		--Player clock
		if (player_cnt = 0) then
			sclk_player  <= NOT sclk_player;
		end if;
		
		player_cnt := player_cnt +1;

		-- SNES clock
		snes_cnt := 0;
		sclk_snes <= NOT sclk_snes;

	end if;
	snes_cnt := snes_cnt + 1;
end process clocks;
	CLK_SNES <= sclk_snes;
	CLK_PLAYER <= sclk_player;
end architecture clocks_arch;