library ieee;  -- Standard IEEE library
use ieee.std_logic_1164.all;  -- Using standard logic types
use ieee.numeric_std.all;  -- Using numeric types and functions

entity optimized_multplier is
    port(
        clk, reset: in std_logic;  -- Clock and reset inputs
        multiplier, multiplicand: in std_logic_vector (63 downto 0);  -- Input vectors for multiplication
        start: in std_logic;  -- Start signal to initiate multiplication
        ready: out std_logic;  -- Output indicating readiness for next operation
        rep_check: out std_logic_vector (7 downto 0);  -- Output representing repetition count
        product: out std_logic_vector (128 downto 0)  -- Output representing the product
    );
end optimized_multplier;

architecture arch of optimized_multplier is
    -- constant to store the width of the multiplier and the multiplicand i.e. 64
    constant WIDTH: integer := 64;  -- Width constant definition
    
    -- state transition register which stores the states that our Finite state machine is in acting as the control unit for the multiplier
    type state_type is (idle, load, op);  -- Definition of state type
    signal state_reg, state_next: state_type;  -- State registers
    
    -- registers to store the current and next states of the product register in each state
    signal product_reg, product_next: unsigned(2*WIDTH downto 0);  -- Product registers
    
    -- rep check register checks if 64 shifts have occured or not indicating the end of the multiplication hardware algorithm
    signal rep_check_reg, rep_check_next: unsigned (7 downto 0);  -- Repetition check registers
    
    signal intermediate_multiplicand: unsigned (WIDTH downto 0);  -- Intermediate multiplicand register
    signal intermediate_product: unsigned (WIDTH downto 0);  -- Intermediate product register
    signal intermediate_product_reg: unsigned (2*WIDTH downto 0);  -- Intermediate product register (extended)
begin
    -- state and product register process block
    process(clk, reset)
    begin
        if (reset = '1') then  -- Reset condition
            state_reg <= idle;  -- Set state to idle
            product_reg <= (others => '0');  -- Initialize product register
            rep_check_reg <= (others => '0');  -- Initialize repetition check register
        elsif (clk'event and clk = '1') then  -- Clock edge condition
            state_reg <= state_next;  -- Update state register
            product_reg <= product_next;  -- Update product register
            rep_check_reg <= rep_check_next;  -- Update repetition check register
        end if;
    end process;

    -- next-state combinational logic block
    process(start, state_reg, product_reg, multiplier, multiplicand, rep_check_reg, intermediate_multiplicand, intermediate_product, intermediate_product_reg)
    begin
        -- default values
        state_next <= state_reg;  -- Default next state
        product_next <= product_reg;  -- Default next product
        rep_check_next <= rep_check_reg;  -- Default next repetition check
        intermediate_multiplicand <= (others => '0');  -- Default intermediate multiplicand
        intermediate_product <= (others => '0');  -- Default intermediate product
        intermediate_product_reg <= (others => '0');  -- Default intermediate product (extended)
        ready <= '0';  -- Initialize ready signal
        case state_reg is  -- State machine
            when idle =>  -- Idle state
                if (start = '1') then  -- Start signal assertion
                    state_next <= load;  -- Move to load state
                end if;
                ready <= '1';  -- Set ready signal
            when load =>  -- Load state
                product_next <= "00000000000000000000000000000000000000000000000000000000000000000" & unsigned(multiplier);  -- Load multiplier into the lower bits of the product register
                rep_check_next <= (others => '0');  -- Reset repetition check
                state_next <= op;  -- Move to operation state
            when op =>  -- Operation state
                rep_check_next <= rep_check_reg + 1;  -- Increment repetition check
                intermediate_multiplicand <= ('0' & unsigned(multiplicand));  -- add a '0' to the MSB of the multiplicand to match its width with the 65 upper bits of the product register
                if (product_reg(0) = '1') then  -- Check LSB of product
                    intermediate_product <= intermediate_multiplicand + product_reg(128 downto 64);  -- Add multiplicand to upper 65 bits of product register if LSB is 1
                    intermediate_product_reg <= intermediate_product & product_reg(63 downto 0);  -- concatenate the sum calculated in earlier step to the lower 64 bits of the product register
                    product_next <= shift_right(intermediate_product_reg, 1);  -- Shift intermediate_product_reg right by 1 bit and assign to the product register
                else
                    product_next <= shift_right(product_reg, 1);  -- just Shift right by 1 bit if LSB = 0
                end if;
                if (rep_check_next = to_unsigned(63, 8)) then  -- Check if 64 shifts have occurred
                    state_next <= idle;  -- Return to idle state
                end if;
        end case;
    end process;

    -- output logic
    product <= std_logic_vector (product_reg);  -- Output product
    rep_check <= std_logic_vector (rep_check_reg);  -- Output repetition check
end arch;
