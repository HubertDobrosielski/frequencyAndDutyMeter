library ieee;
library generics;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use generics.components.all;

entity testbench is
end testbench;

architecture behavior of testbench is

	component miernik
		port (
			ck : in std_logic;
			in_signal : in std_logic;
			freq : out std_logic_vector(16 downto 0);
			-- count_in_out : out std_logic_vector(6 downto 0);
			-- count_ck_out : out std_logic_vector(13 downto 0);
			duty : out std_logic_vector(6 downto 0)
		);
	end component;

	signal ck : std_logic;
	signal in_signal : std_logic;
	signal freq : std_logic_vector(16 downto 0);
	-- signal count_in_out : std_logic_vector(6 downto 0);
	-- signal count_ck_out : std_logic_vector(13 downto 0);
	signal duty : std_logic_vector(6 downto 0);

	constant ck_period : time := 100 ns;
	constant test_length : natural := 10000;

	constant switch_syg_time : time := ck_period * test_length * 3;

	signal ck_p : time := 20 us;
	signal ck_n : time := 80 us;
begin

	uut : miernik port map(
		ck => ck,
		in_signal => in_signal,
		freq => freq,
		-- count_in_out => count_in_out,
		-- count_ck_out => count_ck_out,
		duty => duty
	);
	-- *** Test Bench - User Defined Section ***
	tb : process
	begin
		wait for 120 ms;
		wait; -- will wait forever
	end process;

	clock : process
	begin
		ck <= '0';
		loop
			wait for ck_period/2;
			ck <= not ck;
		end loop;
	end process;

	clock2 : process
	begin
		loop
			in_signal <= '0';
			wait for ck_n;
			in_signal <= '1';
			wait for ck_p;
		end loop;
	end process;

	--

	dfg : process
		variable t : time;
		variable d : natural;
	begin

		-- f = 10 kHz   d = 60%
		ck_n <= 40 us;
		ck_p <= 60 us;
		wait for switch_syg_time;

		-- f = 100 kHz   d = 30%
		ck_n <= 7 us;
		ck_p <= 3 us;
		wait for switch_syg_time;

		-- f = 1 kHz   d = 20%
		ck_n <= 800 us;
		ck_p <= 200 us;
		wait for switch_syg_time;

		-- f = 20 kHz   d = 90%
		ck_n <= 5 us;
		ck_p <= 45 us;
		wait for switch_syg_time;

	end process;
end;