library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testbench_optimized_multplier is
end entity testbench_optimized_multplier;

architecture tb_arch of testbench_optimized_multplier is
    -- Constants
    constant CLK_PERIOD : time := 10 ps; -- Clock period

    -- Signals
    signal clk, reset, start, ready : std_logic;
    signal multiplier, multiplicand   : std_logic_vector(63 downto 0);
    signal product_actual : std_logic_vector(128 downto 0);
    signal rep_check: std_logic_vector(7 downto 0);

begin
    -- Instantiate the optimized_multplier module
    dut : entity work.optimized_multplier
        port map(
            clk          => clk,
            reset        => reset,
            multiplier   => multiplier,
            multiplicand => multiplicand,
            start        => start,
            ready        => ready,
            rep_check    => rep_check,
            product      => product_actual
        );

    -- Clock process
    clk_process: process
    begin
        while now < 100 ns loop
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
        multiplier <= X"0000000000000000";
        multiplicand <= X"0000000000000000";
        wait for CLK_PERIOD;
        reset <= '0';

        -- Load multiplier and multiplicand
        multiplier <= X"000000000000FFFF";
        multiplicand <= X"000000000000EEEE";
        wait for CLK_PERIOD;
        -- Start multiplication
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        -- Wait for multiplication to complete
        wait until ready = '1';

        -- engage multiplier for 100 different input combinations
        for i in 56897 to 56995 loop
            -- Load multiplier and multiplicand with pseudo random numbers
            multiplier <= std_logic_vector(to_unsigned(i*10, 64));
            multiplicand <= std_logic_vector(to_unsigned((i + 71)*71, 64));
            wait for CLK_PERIOD;
            -- Start multiplication
            start <= '1';
            wait for CLK_PERIOD;
            start <= '0';
            -- Wait for multiplication to complete
            wait until ready = '1';
        end loop;
        
        wait;
    end process;

end architecture tb_arch;
