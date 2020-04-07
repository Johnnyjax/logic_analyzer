library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sampler is
	port(
		clk                : in std_logic;
		in1, in2, in3, in4 : in std_logic;
		trig               : in std_logic;
		screen_addr 		 : out std_logic_vector(10 downto 0);
		screen_data        : out std_logic_vector(1 downto 0);
		screen_we          : out std_logic
	);
end sampler;

architecture arch of sampler is
	type state_type is(idle, start, wr1, wr2, wr3, wr4, wr1_wait, wr2_wait, 
							 wr3_wait, wr4_wait);
	signal state_reg, state_next : state_type;
	constant SAMPLE_RATE : integer := 250;
	signal sample_count_reg, sample_count_next : unsigned(6 downto 0);
	signal cur_x_reg, cur_x_next : unsigned(6 downto 0);
	signal cur_y_reg, cur_y_next : unsigned(3 downto 0);
	signal sample_tick : std_logic;
	signal we_reg, we_next : std_logic;
	signal rate_reg, rate_next : unsigned(7 downto 0);
	signal in1_reg, in1_next : std_logic_vector(1 downto 0);
	signal in2_reg, in2_next : std_logic_vector(1 downto 0);
	signal in3_reg, in3_next : std_logic_vector(1 downto 0);
	signal in4_reg, in4_next : std_logic_vector(1 downto 0);
	signal in1_pos_reg, in1_pos_next : unsigned(6 downto 0);
	signal in2_pos_reg, in2_pos_next : unsigned(6 downto 0);
	signal in3_pos_reg, in3_pos_next : unsigned(6 downto 0);
	signal in4_pos_reg, in4_pos_next : unsigned(6 downto 0);
	signal screen_data_reg, screen_data_next : std_logic_vector(1 downto 0);
begin
	process(clk) 
	begin
		if(clk'event and clk = '1') then
			rate_reg <= rate_next;
			state_reg <= state_next;
			in1_reg <= in1_next;
			in2_reg <= in2_next;
			in3_reg <= in3_next;
			in4_reg <= in4_next;
			in1_pos_reg <= in1_pos_next;
			in2_pos_reg <= in2_pos_next;
			in3_pos_reg <= in3_pos_next;
			in4_pos_reg <= in4_pos_next;
			screen_data_reg <= screen_data_next;
			cur_y_reg <= cur_y_next;
			cur_x_reg <= cur_x_next;
			we_reg <= we_next;
			sample_count_reg <= sample_count_next;
		end if;
	end process;
	 rate_next <= (others => '0') when rate_reg = SAMPLE_RATE else
					 rate_reg + 1;
	sample_tick <= '1' when rate_reg = SAMPLE_RATE else
					 '0';
	process(state_reg, sample_tick, in1_reg, in2_reg, in3_reg, in4_reg, trig,
				in1_pos_reg, in2_pos_reg, in3_pos_reg, in4_pos_reg, in1, in2,
				in3, in4, screen_data_reg, cur_x_reg, cur_y_reg, we_reg, sample_count_reg)
	begin
		state_next <= state_reg;
		in1_next <= in1_reg;
		in2_next <= in2_reg;
		in3_next <= in3_reg;
		in4_next <= in4_reg;
		in1_pos_next <= in1_pos_reg;
		in2_pos_next <= in2_pos_reg;
		in3_pos_next <= in3_pos_reg;
		in4_pos_next <= in4_pos_reg;
		screen_data_next <= screen_data_reg;
		sample_count_next <= sample_count_reg;
		cur_x_next <= cur_x_reg;
		cur_y_next <= cur_y_reg;
		we_next <= we_reg;
		case state_reg is
			when idle => 
				if trig = '1' then
					state_next <= start;
					in1_pos_next <= (others => '0');
					in2_pos_next <= (others => '0');
					in3_pos_next <= (others => '0');
					in4_pos_next <= (others => '0');
					in1_next <= (others => '0');
					in2_next <= (others => '0');
					in3_next <= (others => '0');
					in4_next <= (others => '0');
					cur_x_next <= (others => '0');
					cur_y_next <= (others => '0');
				end if;
			when start =>
				if(sample_tick = '1') then
					in1_next <= in1_reg(0) & in1;
					in2_next <= in2_reg(0) & in2;
					in3_next <= in3_reg(0) & in3;
					in4_next <= in4_reg(0) & in4;	
					state_next <= wr1;
				end if;
			when wr1 =>
				cur_x_next <= in1_pos_reg;
				cur_y_next <= "0100";
				screen_data_next <= in1_reg;
				we_next    <= '1';
				state_next <= wr1_wait;
			when wr1_wait =>
				state_next <= wr2;
			when wr2 =>
				in1_pos_next <= in1_pos_reg + 1;
				cur_x_next <= in2_pos_reg;
				cur_y_next <= "0110";
				screen_data_next <= in2_reg;
				we_next <= '1';
				state_next <= wr2_wait;
			when wr2_wait =>
				state_next <= wr3;
			when wr3 =>
				in2_pos_next <= in2_pos_reg + 1;
				cur_x_next <= in3_pos_reg;
				cur_y_next <= "1000";
				screen_data_next <= in3_reg;
				we_next    <= '1';
				state_next <= wr3_wait;
			when wr3_wait =>
				state_next <= wr4;
			when wr4 =>
				in3_pos_next <= in3_pos_reg + 1;
				cur_x_next <= in4_pos_reg;
				cur_y_next <= "1010";
				screen_data_next <= in4_reg;
				we_next <= '1';
				state_next <= wr4_wait;
			when wr4_wait =>
				if (sample_count_reg <= 79) then
					state_next <= start;
					sample_count_next <= sample_count_reg + 1;
				else 
					sample_count_next <= (others => '0');
					state_next <= idle;
				end if;
				in4_pos_next <= in4_pos_reg + 1;
		end case;
	end process;
	screen_addr <= std_logic_vector(cur_y_reg & cur_x_reg);
	screen_data <= screen_data_reg;
	screen_we <= we_reg;
end arch;