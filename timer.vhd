library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_ARITH.ALL;
use ieee.std_logic_UNSIGNED.ALL;

entity timer is 
generic(

		s0 : integer range 0 to 600 -- 0 to 60 seconds
		);
port(
		CLK_TIMER	: in std_logic; --Clock
		
		SECOND 	: out integer range 0 to 600 
	);
end entity timer;

architecture timer_arch of timer is
	--variables : 
	signal s : integer range 0 to 600 := 0; -- 0 to 60 seconds
begin
		
	timer : process ( CLK_TIMER )
	begin
		
		if ( falling_edge( CLK_TIMER ) ) then 
			if(s = 600) then
				s <= 0;
			else 
				s <= s + 1;
			end if; 
		end if;

		SECOND <= s;
	end process timer;


end timer_arch;