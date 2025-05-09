library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

entity Clocks is port
	(
		CLK_50 					: in std_logic;
		CLK_SNES   				: out std_logic := '0';
		CLK_TIMER				: out std_logic := '0'
	);
end entity Clocks;

architecture clocks_arch of Clocks is
	signal sclk_snes : std_logic := '0';
	signal sclk_timer : std_logic := '0';

	begin
		clocks: process
		variable snes_cnt : integer range 0 to 300 := 0;
		variable timer_cnt : integer range 0 to 166667 := 0;
	begin
		wait until falling_edge(CLK_50);

		-- reset
		if (snes_cnt >= 299) then

			-- Timer clock
			if (timer_cnt = 0) then 
				sclk_timer	<= NOT sclk_timer;
			end if;

			timer_cnt := timer_cnt + 1;

			-- SNES clock
			snes_cnt := 0;
			sclk_snes <= NOT sclk_snes;

		end if;
		snes_cnt := snes_cnt + 1;

	end process clocks;

	CLK_SNES <= sclk_snes;
	CLK_TIMER <= sclk_timer;
end architecture clocks_arch;