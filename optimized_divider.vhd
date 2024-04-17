-- Library and package imports
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Entity declaration with port definitions
entity optimized_divider is
    port(
        clk, reset: in std_logic;          -- Clock and reset inputs
        start: in std_logic;               -- Start signal for triggering the division operation
        divider, dividend: in std_logic_vector (63 downto 0);  -- Input divider and dividend signals
        ready: out std_logic;              -- Output ready signal indicating when the module is ready for operation
        rep_check: out std_logic_vector (7 downto 0);  -- Output repetition counter signal
        quotient: out std_logic_vector (63 downto 0);   -- Output quotient signal
        remainder: out std_logic_vector (63 downto 0)    -- Output remainder signal
    );
end optimized_divider;

-- Architecture declaration
architecture arch of optimized_divider is
    -- Constants and types declaration
    constant WIDTH: integer := 64;        -- Width constant for data size
    type state_type is (idle, load, op);  -- Type declaration for state machine states

    -- Signal declarations
    signal state_reg, state_next: state_type;                 -- State registers
    signal divider_reg, divider_next: unsigned(WIDTH-1 downto 0);   -- Divider registers
    signal dividend_reg, dividend_next: unsigned(2*WIDTH downto 0); -- Dividend registers
    signal rep_check_reg, rep_check_next: unsigned (7 downto 0);    -- Repetition check registers
    signal intermediate_divider: unsigned (WIDTH downto 0);  -- Intermediate divider signal
    signal intermediate_result: unsigned (WIDTH downto 0);   -- Intermediate result signal
    signal intermediate_result2: unsigned (WIDTH downto 0);  -- Second intermediate result signal
    signal intermediate_dividend: unsigned (2*WIDTH downto 0);   -- Intermediate dividend signal

begin
    -- Process block for register updates
    process(clk, reset)
    begin
        if (reset = '1') then 
            -- Reset state and registers
            state_reg <= idle;
            divider_reg <= (others => '0');
            dividend_reg <= (others => '0');
            rep_check_reg <= (others => '0');
        elsif (clk'event and clk = '1') then 
            -- Update state and registers on clock rising edge
            state_reg <= state_next;
            divider_reg <= divider_next;
            dividend_reg <= dividend_next;
            rep_check_reg <= rep_check_next;
        end if;
    end process;

    -- Combinational logic for next state calculation
    process(start, state_reg, divider_reg, dividend_reg, divider, dividend, rep_check_reg, intermediate_divider, intermediate_result, intermediate_result2, intermediate_dividend)
    begin
        -- Default assignments
        state_next <= state_reg;
        divider_next <= divider_reg;
        dividend_next <= dividend_reg;
        rep_check_next <= rep_check_reg;
        intermediate_divider <= (others => '0');
        intermediate_result <= (others => '0');
        intermediate_result2 <= (others => '0');
        intermediate_dividend <= (others => '0');
        ready <= '0';
        -- State machine logic
        case state_reg is
            when idle => -- idle state
                -- Transition to load state when start signal is asserted
                if (start = '1') then 
                    state_next <= load;
                end if;
                -- Set ready signal to indicate module is ready for operation
                ready <= '1';
            when load => -- load state
                -- Transition to op state and load divider and dividend
                state_next <= op;
                divider_next <= unsigned(divider); -- next state of divider loaded
                -- right half (lower 64 bits) of 129-bit dividend register (which will store our final quotient and remainder) initialized with dividend 
                dividend_next <= "00000000000000000000000000000000000000000000000000000000000000000" & unsigned(dividend); 
                -- initializing the repetition checker with 0
                rep_check_next <= (others => '0');
            when op => -- operation state
                -- Increment repetition check counter
                rep_check_next <= rep_check_reg + 1;  
                intermediate_divider <= ("0" & divider_reg); -- intermediate divider concatenates the divider with a '0' to match its width with the upper 65 bits of the dividend register
                intermediate_result <= dividend_reg(2*WIDTH downto WIDTH); -- intermediate result stores the upper 65 bits of the dividend register
                intermediate_result2 <= intermediate_result - intermediate_divider; -- intermediate_result2 stores the difference of the previous two registers
                -- Check if difference is less than 0
                if (intermediate_result < intermediate_divider) then 
                    dividend_next <= shift_left(dividend_reg, 1); -- if intermediate_result2 < 0, we just shift the dividend register left by 1
                else
                    -- if difference > 0
                    intermediate_dividend <= intermediate_result2 & dividend_reg(WIDTH-1 downto 0); -- intermediate_dividend stores the difference (intermediate_result2) concatenated with the lower 64 bits of the dividend register
                    dividend_next <=  intermediate_dividend(2*WIDTH-1 downto 0) & '1'; -- since the difference > 0, we were able to divide and we shift the dividend register left and add a 1 to the LSB 
                end if;
                -- Return to idle state when repetition check reaches threshold
                if (rep_check_next = to_unsigned(WIDTH+1, 8)) then 
                    state_next <= idle;
                end if;
        end case;
    end process;

    -- Output logic
    quotient <= std_logic_vector(dividend_reg(WIDTH-1 downto 0));    -- Assign quotient output as the lower 64 bits of the dividend register
    remainder <= std_logic_vector(shift_right(dividend_reg(2*WIDTH-1 downto WIDTH), 1));   -- Assign remainder output as the upper 64 bits of the remainder register shifter to the right by 1
    rep_check <= std_logic_vector(rep_check_reg);    -- Assign repetition check output
    
end arch;
