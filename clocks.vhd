library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

entity clocks is port
	(
		CLK_50 					: in std_logic;
		
		CLK_SNES 				: out std_logic := '0'
	);
end entity clocks;

architecture clocks_arch of clocks is
	signal sclk_snes : std_logic := '0';
begin
clocks: process
	variable snes_cnt : integer range 0 to 300 := 0;
begin
	wait until falling_edge(CLK_50);
	if (snes_cnt >= 299) then
		snes_cnt := 0;
		sclk_snes <= NOT sclk_snes;
	end if;
	snes_cnt := snes_cnt + 1;
end process clocks;
	CLK_SNES <= sclk_snes;
end architecture clocks_arch;