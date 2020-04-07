library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity freq_counter is
	port(
		clk, reset : in std_logic;
		start, si : in std_logic;
		ready, done_tick : out std_logic;
		freq : out std_logic_vector(19 downto 0)
	);
end freq_counter;

architecture arch of freq_counter is
	constant CLK_S_COUNT : integer := 50000000;
	type state_type is (idle, waite, count, done);
	signal state_reg, state_next : state_type;
	type state_type2 is(idle2, count2);
	signal state_reg2, state_next2 : state_type2;
	signal f_reg, f_next : unsigned(19 downto 0);
	signal n_reg , n_next : unsigned(25 downto 0);
	signal delay_reg : std_logic;
	signal edge : std_logic;
begin
	process(clk, reset)
	begin
		if reset = '1' then
			state_reg <= idle;
			state_reg2 <= idle2;
			f_reg <= (others => '0');
			n_reg <= (others => '0');
			delay_reg <= '0';
		elsif(clk'event and clk = '1') then
			state_reg <= state_next;
			state_reg2 <= state_next2;
			f_reg <= f_next;
			n_reg <= n_next;
			delay_reg <= si;
		end if;
	end process;
	
	edge <= (not delay_reg) and si;
	
	process(start, edge, state_reg, f_reg, f_next, n_reg)
	begin
		ready <= '0';
		done_tick <= '0';
		state_next <= state_reg;
		f_next <= f_reg;
		case state_reg is
			when idle =>
				ready <= '1';
				if(start = '1') then
					state_next <= waite;
					f_next <= (others => '0');
				end if;
			when waite =>
				if(n_reg < CLK_S_COUNT) then
					if(edge = '1') then
						state_next <= count;
					end if;
				else	
					state_next <= done;
				end if;
			when count =>
				f_next <= f_reg + 1;
				state_next <= waite;
			when done =>
				done_tick <= '1';
				state_next <= idle;
			end case;
		end process;
		
		process(start, n_reg, state_reg2)
		begin
			n_next <= n_reg;
			state_next2 <= state_reg2;
			case state_reg2 is
				when idle2 =>
					if start = '1' then
						state_next2 <= count2;
						n_next <= (others => '0');
					end if;
				when count2 =>
					if n_reg >= CLK_S_COUNT then
						state_next2 <= idle2;
					else
						n_next <= n_reg + 1;
					end if;
			end case;
		end process;
	freq <= std_logic_vector(f_reg);
end arch;