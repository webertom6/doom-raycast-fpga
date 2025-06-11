library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_ARITH.ALL;
use ieee.std_logic_UNSIGNED.ALL;

entity Timer is 
generic(

		s0 : integer range 0 to 600 -- 0 to 60 seconds
		);
port(
		CLK_TIMER	: in std_logic; --Clock
		WIN : in std_logic;
		game_active : in std_logic;
		
		SECOND 	: out integer range 0 to 600 
	);
end entity Timer;

architecture timer_arch of Timer is
	--variables : 
	signal s : integer range 0 to 600 := 0; -- 0 to 60 seconds
    signal timer_cnt : integer range 0 to 50000000 := 0;
begin
		
	timer : process ( CLK_TIMER )
	begin
		
		if ( falling_edge( CLK_TIMER ) ) then 
			if game_active = '1' then 
				if(s = 600) then
					s <= 0;
				else 
					s <= s + 1;
				end if;
			else 
				s <= 0;
			end if;
		end if;

		SECOND <= s;
	end process timer;


end timer_arch;