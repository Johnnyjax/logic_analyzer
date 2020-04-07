library ieee;
use ieee.std_logic_1164.all;
entity logic_analyzer_top is
	port(
		CLOCK_50 : in std_logic;
		KEY            : in std_logic_vector(3 downto 0);
		LEDR            : out std_logic_vector(9 downto 0);
		GPIO_0         : in std_logic_vector(3 downto 0);
		VGA_HS, VGA_VS : out std_logic;	
		VGA_R, VGA_B, VGA_G : out std_logic_vector(2 downto 0)
	);
end logic_analyzer_top;

architecture arch of logic_analyzer_top is
	signal pixel_x, pixel_y : std_logic_vector(9 downto 0);
	signal video_on, pixel_tick : std_logic;
	signal rgb_reg, rgb_next : std_logic_vector(2 downto 0);
	signal trig : std_logic;
begin
	vga_sync_unit : entity work.vga_sync
		port map(clk => CLOCK_50, reset => not(KEY(0)),
					vsync => VGA_VS, hsync => VGA_HS, video_on => video_on,
					p_tick => pixel_tick, pixel_x => pixel_x, pixel_y => pixel_y);
	logic_analyzer_unit : entity work.logic_analyzer	
		port map(clk => CLOCK_50, reset => not(KEY(0)), trig => trig, in1 => GPIO_0(0),
					in2 => GPIO_0(1), in3 => GPIO_0(2), in4 => GPIO_0(3),
					video_on => video_on, pixel_x => pixel_x, pixel_y => pixel_y,
					text_rgb => rgb_next, ledr => LEDR);
	debounce_unit : entity work.debounce
		port map(clk => CLOCK_50, reset => not(KEY(0)), sw => not(KEY(1)),
					db_level => open, db_tick => trig);
	process(CLOCK_50)
	begin
		if(CLOCK_50'event and CLOCK_50 = '1') then
			if(pixel_tick = '1') then
				rgb_reg <= rgb_next;
			end if;
		end if;
	end process;
	VGA_R <= (others => rgb_reg(2));
	VGA_G <= (others => rgb_reg(1));
	VGA_B <= (others => rgb_reg(0));
end arch;
		