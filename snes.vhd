library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

entity snes is port
	(
	CLK		: in std_logic;
	DATA		: in std_logic;
	
	LATCH		: out std_logic := '0';
	CTRL 	: out std_logic_vector(11 downto 0) := "000000000000"
	);
end entity snes;

-- SNES ARCHITECTURE --
architecture snes_arch of snes is

	signal cnt : integer range 0 to 15 := 0;
	
begin
process
begin 
	wait until falling_edge(CLK);
		
		if (cnt = 15) then
			LATCH <= '1';
		else
			LATCH <= '0';
		end if;
		if (cnt <= 11)then
			CTRL(cnt) <= NOT DATA;
		end if;
		cnt <= cnt + 1;
end process snes;
end architecture snes_arch;