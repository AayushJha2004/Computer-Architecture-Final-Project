library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testbench_optimized_divider is
end entity testbench_optimized_divider;

architecture tb_arch of testbench_optimized_divider is
    -- Constants
    constant CLK_PERIOD : time := 10 ps; -- Clock period

    -- Signals
    signal clk, reset, start, ready : std_logic;
    signal divider, dividend   : std_logic_vector(63 downto 0);
    signal quotient, remainder : std_logic_vector(63 downto 0);
    signal rep_check: std_logic_vector(7 downto 0);

begin
    -- Instantiate the optimized_multplier module
    dut : entity work.optimized_divider
        port map(
            clk          => clk,
            reset        => reset,
            divider      => divider,
            dividend     => dividend,
            start        => start,
            ready        => ready,
            rep_check    => rep_check,
            quotient      => quotient,
            remainder     => remainder
        );

    -- Clock process
    clk_process: process
    begin
        while now < 1000 ns loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    -- Stimulus process
    stimulus_process: process
    begin
        -- Reset
        reset <= '1';
        start <= '0';
        divider <= X"0000000000000000";
        dividend <= X"0000000000000000";
        wait for CLK_PERIOD;
        reset <= '0';

        -- Load divider and dividend
        divider <= X"000000000000002F";
        dividend <= X"000000001234567E";
        wait for CLK_PERIOD;
        -- Start division
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        -- Wait for division to complete
        wait until ready = '1';
        
        -- engage 100 different combinations of input and output
        for i in 56897 to 56995 loop
            -- Load divider and dividend with pseudo random numbers
            divider <= std_logic_vector(to_unsigned((i+8990)*137, 64));
            dividend <= std_logic_vector(to_unsigned((i + 7179)*(i-568)*997651917, 64));
            wait for CLK_PERIOD;
            -- Start division
            start <= '1';
            wait for CLK_PERIOD;
            start <= '0';
            -- Wait for division to complete
            wait until ready = '1';
        end loop;

        wait;
    end process;

end architecture tb_arch;
