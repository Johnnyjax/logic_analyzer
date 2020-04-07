library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity logic_analyzer is
	port(
		clk, reset : std_logic;
		video_on : in std_logic;
		pixel_x, pixel_y : in std_logic_vector(9 downto 0);
		trig : in std_logic;
		in1, in2, in3, in4 : in std_logic;
		ledr : out std_logic_vector(9 downto 0);
		text_rgb : out std_logic_vector(2 downto 0)
	);
end logic_analyzer;

architecture arch of logic_analyzer is
	signal pix_x, pix_y : unsigned(9 downto 0);
	signal char_addr : std_logic_vector(1 downto 0);
	signal rom_addr : std_logic_vector(6 downto 0);
	signal row_addr : std_logic_vector(4 downto 0);
	signal bit_addr : unsigned(2 downto 0);
	signal font_word : std_logic_vector(7 downto 0);
	signal font_bit : std_logic;
	
	signal char_addr_text, char_addr0, char_addr1, char_addr2, char_addr3,
			 char_addr_title, char_addr_fq1, char_addr_fq2, 
			 char_addr_fq3, char_addr_fq0 : std_logic_vector(6 downto 0);
	
	signal row_addr0, row_addr1, row_addr2, row_addr3,
			 row_addr_title, row_addr_fq1, row_addr_fq2, 
			 row_addr_fq3, row_addr_fq0 : std_logic_vector(3 downto 0);
			 
	signal bit_addr0, bit_addr1, bit_addr2, bit_addr3,
			 bit_addr_title, bit_addr_fq1, bit_addr_fq2, 
			 bit_addr_fq3, bit_addr_fq0 : std_logic_vector(2 downto 0);
			 

	signal char_rom_addr  : std_logic_vector(10 downto 0);
	signal char_font_word : std_logic_vector(7 downto 0);
	signal char_row_addr  : std_logic_vector(3 downto 0);
	signal char_bit_addr  : std_logic_vector(2 downto 0);
	signal char_font_bit  : std_logic;
	
	signal ch0_on, ch1_on, ch2_on, ch3_on, title_on, fq1_on,
			 fq2_on, fq3_on, fq0_on : std_logic;
	
	signal we : std_logic;
	signal addr_r, addr_w : std_logic_vector(10 downto 0);
	signal din, dout : std_logic_vector(1 downto 0);
	
	constant MAX_X : integer := 80;
	constant MAX_Y : integer := 30;
	
	signal cur_x_reg, cur_x_next : unsigned(6 downto 0);
	signal cur_y_reg, cur_y_next : unsigned(3 downto 0);
	signal move_x_tick, move_y_tick : std_logic;
	signal logic1_on, logic2_on, logic3_on, logic4_on : std_logic;
	signal pix_x1_reg, pix_y1_reg : unsigned(9 downto 0);
	signal pix_x2_reg, pix_y2_reg : unsigned(9 downto 0);
	
	signal font_rgb, font_rev_rgb : std_logic_vector(2 downto 0);
	
	signal ch0_done_tick, ch1_done_tick, ch2_done_tick , ch3_done_tick : std_logic;
	signal ch0_freq, ch1_freq, ch2_freq, ch3_freq : std_logic_vector(19 downto 0);
	signal ch0_bcd0, ch0_bcd1, ch0_bcd2, ch0_bcd3,
			 ch0_bcd4, ch0_bcd5 : std_logic_vector(3 downto 0) := (others => '0');
	signal ch1_bcd0, ch1_bcd1, ch1_bcd2, ch1_bcd3,
			 ch1_bcd4, ch1_bcd5 : std_logic_vector(3 downto 0);
	signal ch2_bcd0, ch2_bcd1, ch2_bcd2, ch2_bcd3,
			 ch2_bcd4, ch2_bcd5 : std_logic_vector(3 downto 0);
	signal ch3_bcd0, ch3_bcd1, ch3_bcd2, ch3_bcd3,
			 ch3_bcd4, ch3_bcd5 : std_logic_vector(3 downto 0);
begin
	pix_x <= unsigned(pixel_x);
	pix_y <= unsigned(pixel_y);
	sampling_unit : entity work.sampler
		port map(clk => clk, in1 => in1, in2 => in2,
					in3 => in3, in4 => in4, trig => trig,
					screen_addr => addr_w, screen_data => din,
					screen_we => we);
	
	font_unit : entity work.font_rom
		port map(clk => clk, addr => rom_addr, data => font_word);
		
	char_unit : entity work.char_rom
		port map(clk => clk, addr => char_rom_addr, data => char_font_word);
		
	video_ram : entity work.altera_dual_port_ram_sync
		generic map(ADDR_WIDTH => 11, DATA_WIDTH => 2)
		port map(clk => clk, we => we,
					addr_a => addr_w, addr_b => addr_r,
					din_a => din, dout_a => open, dout_b => dout);
	freq_counter_unit0 : entity work.freq_counter
		port map(clk => clk, reset => reset, start => trig,
					si => in1, ready => open, done_tick => ch0_done_tick,
					freq => ch0_freq);
	freq_counter_unit1 : entity work.freq_counter
		port map(clk => clk, reset => reset, start => trig,
					si => in2, ready => open, done_tick => ch1_done_tick,
					freq => ch1_freq);
	freq_counter_unit2 : entity work.freq_counter
		port map(clk => clk, reset => reset, start => trig,
					si => in3, ready => open, done_tick => ch2_done_tick,
					freq => ch2_freq);
	freq_counter_unit3 : entity work.freq_counter
		port map(clk => clk, reset => reset, start => trig,
					si => in4, ready => open, done_tick => ch3_done_tick,
					freq => ch3_freq);
	bin2bcd_unit0 : entity work.bin2bcd 
		port map(clk => clk, reset => reset, start => ch0_done_tick, 
					bin => ch0_freq, ready => open, done_tick => open,
					bcd6 => open, bcd5 => ch0_bcd5, bcd4 => ch0_bcd4,
					bcd3 => ch0_bcd3, bcd2 => ch0_bcd2, bcd1 => ch0_bcd1,
					bcd0 => ch0_bcd0);
	bin2bcd_unit1 : entity work.bin2bcd 
		port map(clk => clk, reset => reset, start => ch1_done_tick, 
					bin => ch1_freq, ready => open, done_tick => open,
					bcd6 => open, bcd5 => ch1_bcd5, bcd4 => ch1_bcd4,
					bcd3 => ch1_bcd3, bcd2 => ch1_bcd2, bcd1 => ch1_bcd1,
					bcd0 => ch1_bcd0);
	bin2bcd_unit2 : entity work.bin2bcd 
		port map(clk => clk, reset => reset, start => ch2_done_tick, 
					bin => ch2_freq, ready => open, done_tick => open,
					bcd6 => open, bcd5 => ch2_bcd5, bcd4 => ch2_bcd4,
					bcd3 => ch2_bcd3, bcd2 => ch2_bcd2, bcd1 => ch2_bcd1,
					bcd0 => ch2_bcd0);
	bin2bcd_unit3 : entity work.bin2bcd 
		port map(clk => clk, reset => reset, start => ch3_done_tick, 
					bin => ch3_freq, ready => open, done_tick => open,
					bcd6 => open, bcd5 => ch3_bcd5, bcd4 => ch3_bcd4,
					bcd3 => ch3_bcd3, bcd2 => ch3_bcd2, bcd1 => ch3_bcd1,
					bcd0 => ch3_bcd0);
	process(clk)
	begin	
		if(clk'event and clk = '1') then
			pix_x1_reg <= unsigned(pixel_x);
			pix_x2_reg <= pix_x1_reg;
			pix_y1_reg <= unsigned(pixel_y);
			pix_y2_reg <= pix_y1_reg;
		end if;
	end process;
	
	addr_r <= pixel_y(8 downto 5) & pixel_x(9 downto 3);
	char_addr <= dout;
	row_addr <= pixel_y(4 downto 0);
	rom_addr <= char_addr & row_addr;
	bit_addr <= pix_x2_reg(2 downto 0);
	font_bit <= font_word(to_integer(not bit_addr));
	
	font_rgb <= "010" when font_bit = '1' else "000";
	font_rev_rgb <= "000" when font_bit = '1' else "010";
	logic1_on <= '1' when pixel_y(8 downto 5) = "0100" else
					'0';
	logic2_on <= '1' when pixel_y(8 downto 5) = "0110" else
					'0';
	logic3_on <= '1' when pixel_y(8 downto 5) = "1000" else
					'0';
	logic4_on <= '1' when pixel_y(8 downto 5) = "1010" else
					'0';
					
	ch0_on <= 
				'1' when pix_y(9 downto 4) = "000111" and
							pix_x(9 downto 3) < 11 else
				'0';
	row_addr0 <= std_logic_vector(pix_y(3 downto 0));
	bit_addr0 <= std_logic_vector(pix_x(2 downto 0));
	with pix_x(6 downto 3) select
		char_addr0 <= 
			"1000011" when "0000",-- C
			"1101000" when "0001",-- h
			"1100001" when "0010",-- a
			"1101110" when "0011",-- n
			"1101110" when "0100",-- n
			"1100101" when "0101",-- e
			"1101100" when "0110",-- l
			"0000000" when "0111",--
			"0110000" when "1000",-- 0
			"0111010" when "1001",-- :
			"0000000" when others;
	ch1_on <= 
				'1' when pix_y(9 downto 4) = "001011" and
							pix_x(9 downto 3) < 11 else
				'0';
	row_addr1 <= std_logic_vector(pix_y(3 downto 0));
	bit_addr1 <= std_logic_vector(pix_x(2 downto 0));
	with pix_x(6 downto 3) select
		char_addr1 <= 
			"1000011" when "0000",-- C
			"1101000" when "0001",-- h
			"1100001" when "0010",-- a
			"1101110" when "0011",-- n
			"1101110" when "0100",-- n
			"1100101" when "0101",-- e
			"1101100" when "0110",-- l
			"0000000" when "0111",--
			"0110001" when "1000",-- 1
			"0111010" when "1001",-- :
			"0000000" when others;	
	ch2_on <= 
				'1' when pix_y(9 downto 4) = "001111" and
							pix_x(9 downto 3) < 11 else
				'0';
	row_addr2 <= std_logic_vector(pix_y(3 downto 0));
	bit_addr2 <= std_logic_vector(pix_x(2 downto 0));
	with pix_x(6 downto 3) select
		char_addr2 <= 
			"1000011" when "0000",-- C
			"1101000" when "0001",-- h
			"1100001" when "0010",-- a
			"1101110" when "0011",-- n
			"1101110" when "0100",-- n
			"1100101" when "0101",-- e
			"1101100" when "0110",-- l
			"0000000" when "0111",--
			"0110010" when "1000",-- 2
			"0111010" when "1001",-- :
			"0000000" when others;	
	
	ch3_on <= 
				'1' when pix_y(9 downto 4) = "010011" and
							pix_x(9 downto 3) < 11 else
				'0';
	row_addr3 <= std_logic_vector(pix_y(3 downto 0));
	bit_addr3 <= std_logic_vector(pix_x(2 downto 0));
	with pix_x(6 downto 3) select
		char_addr3 <= 
			"1000011" when "0000",-- C
			"1101000" when "0001",-- h
			"1100001" when "0010",-- a
			"1101110" when "0011",-- n
			"1101110" when "0100",-- n
			"1100101" when "0101",-- e
			"1101100" when "0110",-- l
			"0000000" when "0111",--
			"0110011" when "1000",-- 3
			"0111010" when "1001",-- :
			"0000000" when others;
		
	title_on <= 
				'1' when pix_y(9 downto 5) = 0 and
							(pix_x(9 downto 4) >= 13) and (pix_x(9 downto 4) <= 26) else
				'0';
	row_addr_title <= std_logic_vector(pix_y(4 downto 1));
	bit_addr_title <= std_logic_vector(pix_x(3 downto 1));
	with pix_x(7 downto 4) select
		char_addr_title <= 
			"1001100" when "1101",-- L
			"1101111" when "1110",-- o
			"1100111" when "1111",-- g
			"1101001" when "0000",-- i
			"1100011" when "0001",-- c
			"0000000" when "0010",-- 
			"1000001" when "0011",-- A
			"1101110" when "0100",-- n
			"1100001" when "0101",-- a
			"1101100" when "0110",-- l
			"1111001" when "0111",-- y
			"1111010" when "1000",-- z
			"1100101" when "1001",-- e
			"1110010" when "1010",-- r
			"0000000" when others;
	fq0_on <= 
				'1' when pix_y(9 downto 4) = "011101" and
							pix_x(9 downto 3) < 19 else
				'0';
	row_addr_fq0 <= std_logic_vector(pix_y(3 downto 0));
	bit_addr_fq0 <= std_logic_vector(pix_x(2 downto 0));
	with pix_x(7 downto 3) select
		char_addr_fq0 <= 
			"1000011" when "00000",-- C
			"1001000" when "00001",-- H
			"0110000" when "00010",-- 0
			"0000000" when "00011",-- 
			"1000110" when "00100",-- F
			"1110010" when "00101",-- r
			"1100101" when "00110",-- e
			"1110001" when "00111",-- q 
			"0111010" when "01000",-- :
			"0000000" when "01001",--
			"011" & ch0_bcd5 when "01010",
			"011" & ch0_bcd4 when "01011",
			"011" & ch0_bcd3 when "01100",
			"011" & ch0_bcd2 when "01101",
			"011" & ch0_bcd1 when "01110",
			"011" & ch0_bcd0 when "01111",
			"0000000" when "10000",
			"1001000" when "10001",
			"1111010" when others;
			
	fq1_on <= 
				'1' when pix_y(9 downto 4) = "011101" and
							(pix_x(9 downto 3) >= 20) and (pix_x(9 downto 3) < 39) else
				'0';
	row_addr_fq1 <= std_logic_vector(pix_y(3 downto 0));
	bit_addr_fq1 <= std_logic_vector(pix_x(2 downto 0));
	with pix_x(8 downto 3) select
		char_addr_fq1 <= 
			"1000011" when "010100",-- C
			"1001000" when "010101",-- H
			"0110001" when "010110",-- 1
			"0000000" when "010111",-- 
			"1000110" when "011000",-- F
			"1110010" when "011001",-- r
			"1100101" when "011010",-- e
			"1110001" when "011011",-- q 
			"0111010" when "011100",-- :
			"0000000" when "011101",--
			"011" & ch1_bcd5 when "011110",
			"011" & ch1_bcd4 when "011111",
			"011" & ch1_bcd3 when "100000",
			"011" & ch1_bcd2 when "100001",
			"011" & ch1_bcd1 when "100010",
			"011" & ch1_bcd0 when "100011",
			"0000000" when "100100",
			"1001000" when "100101",
			"1111010" when others;
	
	fq2_on <= 
				'1' when pix_y(9 downto 4) = "011101" and
							(pix_x(9 downto 3) >= 40) and (pix_x(9 downto 3) < 59) else
				'0';
	row_addr_fq2 <= std_logic_vector(pix_y(3 downto 0));
	bit_addr_fq2 <= std_logic_vector(pix_x(2 downto 0));
	with pix_x(8 downto 3) select
		char_addr_fq2 <= 
			"1000011" when "101000",-- C
			"1001000" when "101001",-- H
			"0110010" when "101010",-- 2
			"0000000" when "101011",-- 
			"1000110" when "101100",-- F
			"1110010" when "101101",-- r
			"1100101" when "101110",-- e
			"1110001" when "101111",-- q 
			"0111010" when "110000",-- :
			"0000000" when "110001",--
			"011" & ch2_bcd5 when "110010",
			"011" & ch2_bcd4 when "110011",
			"011" & ch2_bcd3 when "110100",
			"011" & ch2_bcd2 when "110101",
			"011" & ch2_bcd1 when "110110",
			"011" & ch2_bcd0 when "110111",
			"0000000" when "111000",
			"1001000" when "111001",
			"1111010" when others;
	fq3_on <= 
				'1' when pix_y(9 downto 4) = "011101" and
							(pix_x(9 downto 3) >= 60) and (pix_x(9 downto 3) < 79) else
				'0';
	row_addr_fq3 <= std_logic_vector(pix_y(3 downto 0));
	bit_addr_fq3 <= std_logic_vector(pix_x(2 downto 0));
	with pix_x(9 downto 3) select
		char_addr_fq3 <= 
			"1000011" when "0111100",-- C
			"1001000" when "0111101",-- H
			"0110011" when "0111110",-- 3
			"0000000" when "0111111",-- 
			"1000110" when "1000000",-- F
			"1110010" when "1000001",-- r
			"1100101" when "1000010",-- e
			"1110001" when "1000011",-- q 
			"0111010" when "1000100",-- :
			"0000000" when "1000101",--
			"011" & ch3_bcd5 when "1000110",
			"011" & ch3_bcd4 when "1000111",
			"011" & ch3_bcd3 when "1001000",
			"011" & ch3_bcd2 when "1001001",
			"011" & ch3_bcd1 when "1001010",
			"011" & ch3_bcd0 when "1001011",
			"0000000" when "1001100",
			"1001000" when "1001101",
			"1111010" when others;
	
	process(video_on, logic1_on, logic2_on, font_rgb, font_rev_rgb,
				logic3_on, logic4_on, char_addr0, row_addr0, bit_addr0,
				char_font_bit, ch0_on, char_addr1, row_addr1, bit_addr1, ch1_on,
				ch2_on, ch3_on, char_addr2, row_addr2, bit_addr2, 
				char_addr3, row_addr3, bit_addr3, title_on, char_addr_title,
				row_addr_title, bit_addr_title, fq0_on, char_addr_fq0, 
				row_addr_fq0, bit_addr_fq0, fq1_on, char_addr_fq1, 
				row_addr_fq1, bit_addr_fq1, fq2_on, char_addr_fq2, 
				row_addr_fq2, bit_addr_fq2, fq3_on, char_addr_fq3,
				row_addr_fq3, bit_addr_fq3)
	begin
		if video_on = '0' then
			text_rgb <= "000";
			char_addr_text <= char_addr0;
			char_row_addr <= row_addr0;
			char_bit_addr <= bit_addr0;
		else
			if logic1_on = '1' or logic2_on = '1' or logic3_on = '1'
				or logic4_on = '1' then
				text_rgb <= font_rgb;
				char_addr_text <= char_addr0;
				char_row_addr <= row_addr0;
				char_bit_addr <= bit_addr0;
			elsif ch0_on = '1' then
				char_addr_text <= char_addr0;
				char_row_addr <= row_addr0;
				char_bit_addr <= bit_addr0;
				if char_font_bit = '1' then
					text_rgb <= "110";
				else
					text_rgb <= "000";
				end if;
			elsif ch1_on = '1' then
				char_addr_text <= char_addr1;
				char_row_addr <= row_addr1;
				char_bit_addr <= bit_addr1;
				if char_font_bit = '1' then
					text_rgb <= "100";
				else
					text_rgb <= "000";
				end if;
			elsif ch2_on = '1' then
				char_addr_text <= char_addr2;
				char_row_addr <= row_addr2;
				char_bit_addr <= bit_addr2;
				if char_font_bit = '1' then
					text_rgb <= "001";
				else
					text_rgb <= "000";
				end if;
			elsif ch3_on = '1' then
				char_addr_text <= char_addr3;
				char_row_addr <= row_addr3;
				char_bit_addr <= bit_addr3;
				if char_font_bit = '1' then
					text_rgb <= "011";
				else
					text_rgb <= "000";
				end if;
			elsif title_on = '1' then
				char_addr_text <= char_addr_title;
				char_row_addr <= row_addr_title;
				char_bit_addr <= bit_addr_title;
				if char_font_bit = '1' then
					text_rgb <= "111";
				else
					text_rgb <= "000";
				end if;
			elsif fq0_on = '1' then
				char_addr_text <= char_addr_fq0;
				char_row_addr <= row_addr_fq0;
				char_bit_addr <= bit_addr_fq0;
				if char_font_bit = '1' then
					text_rgb <= "110";
				else
					text_rgb <= "000";
				end if;
			elsif fq1_on = '1' then
				char_addr_text <= char_addr_fq1;
				char_row_addr <= row_addr_fq1;
				char_bit_addr <= bit_addr_fq1;
				if char_font_bit = '1' then
					text_rgb <= "100";
				else
					text_rgb <= "000";
				end if;
			elsif fq2_on = '1' then
				char_addr_text <= char_addr_fq2;
				char_row_addr <= row_addr_fq2;
				char_bit_addr <= bit_addr_fq2;
				if char_font_bit = '1' then
					text_rgb <= "001";
				else
					text_rgb <= "000";
				end if;
			elsif fq3_on = '1' then
				char_addr_text <= char_addr_fq3;
				char_row_addr <= row_addr_fq3;
				char_bit_addr <= bit_addr_fq3;
				if char_font_bit = '1' then
					text_rgb <= "011";
				else
					text_rgb <= "000";
				end if;
			else
				char_addr_text <= char_addr0;
				char_row_addr <= row_addr0;
				char_bit_addr <= bit_addr0;
				text_rgb <= "000";
			end if;
		end if;
	end process;
	ledr <= ch0_freq(9 downto 0);
	char_rom_addr <= char_addr_text & char_row_addr;
	char_font_bit <= char_font_word(to_integer(unsigned(not char_bit_addr)));
end arch;