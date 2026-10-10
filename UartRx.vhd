library ieee;
use ieee.std_logic_1164.all;
use work.UartPkg.all;

entity UartRx is
    port(
        i_Clk       : in    std_logic;
        i_Rst       : in    std_logic;

        i_Rx_Serial : in    std_logic;

        o_Rx_Active : out   std_logic;
        o_Rx_Done   : out   std_logic;
        o_Rx_Byte   : out   std_logic_vector((c_BYTE_WIDTH * 8) - 1 downto 0)
    );
end entity;

architecture rtl of UartRx is
    constant c_LIMIT : integer := calc_BaudLimit(c_CLK_FREQ, c_BAUD_RATE);

    --Default to '1' for serial line
    signal r_Rx_Sync_1      : std_logic := '1';
    signal r_Rx_Sync_2      : std_logic := '1';

    --State machine
    type t_State is (s_IDLE, s_START_BIT, s_DATA_BITS, s_STOP_BIT, s_CLEANUP);
    signal r_State          : t_State := s_IDLE;

    --Internal counters and registers
    signal r_Clock_Count    : integer range 0 to c_LIMIT - 1 := 0;
    signal r_Bit_Index      : integer range 0 to (c_BYTE_WIDTH * 8) - 1 := 0;
    signal r_Rx_Data        : std_logic_vector((c_BYTE_WIDTH * 8) - 1 downto 0) := (others => '0');
begin

    --Wire internal register to output
    o_Rx_Byte <= r_Rx_Data;

    process(i_Clk) is
    begin

        if rising_edge(i_Clk) then

            if i_Rst = '1' then
                r_Rx_Sync_1     <= '1';
                r_Rx_Sync_2     <= '1';
                r_State         <= s_IDLE;
                r_Clock_Count   <= 0;
                r_Bit_Index     <= 0;
                r_Rx_Data       <= (others => '0');
                o_Rx_Active     <= '0';
                o_Rx_Done       <= '0';
            else
                --Compartamentalized data transfer (2 clock cycles)
                --Unnecessary for simulation, necessary for synthesis
                r_Rx_Sync_1 <= i_Rx_Serial;
                r_Rx_Sync_2 <= r_Rx_Sync_1;

                --Default output
                o_Rx_Done   <= '0';

                --State machine
                case r_State is

                    when s_IDLE         =>
                        o_Rx_Active     <= '0';
                        r_Clock_Count   <= 0;
                        r_Bit_Index     <= 0;
                        if r_Rx_Sync_2 = '0' then
                            r_State     <= s_START_BIT;
                            o_Rx_Active <= '1';
                        end if;
                    
                    when s_START_BIT    =>
                        --Find middle of bit period (stability)
                        if r_Clock_Count = (c_LIMIT - 1)/2 then
                            r_Clock_Count   <= 0;

                            --Glitch rejection: still 0 after half a bit period?
                            if r_Rx_Sync_2 = '0' then
                                r_State     <= s_DATA_BITS;
                            else
                                r_State     <= s_IDLE;
                            end if;

                        else
                            r_Clock_Count   <= r_Clock_Count + 1;
                        end if;

                    when s_DATA_BITS    =>
                        --Now wait full bit periods to continually sample the center
                        if r_Clock_Count = c_LIMIT - 1 then
                            r_Clock_Count           <= 0;

                            --Sample bit into register
                            r_Rx_Data(r_Bit_Index)  <= r_Rx_Sync_2;

                            --All bits read?
                            if r_Bit_Index  = (c_BYTE_WIDTH * 8) - 1 then
                                r_Bit_Index     <= 0;
                                r_State         <= s_STOP_BIT;
                            else
                                r_Bit_Index     <= r_Bit_Index + 1;
                            end if;
                        else
                            r_Clock_Count       <= r_Clock_Count + 1;
                        end if;

                    when s_STOP_BIT     =>
                        -- Wait a full bit period to reach the center of the Stop Bit
                        if r_Clock_Count = c_LIMIT - 1 then
                            r_Clock_Count <= 0;
                            o_Rx_Done     <= '1';
                            r_State       <= s_CLEANUP;
                        else
                            r_Clock_Count <= r_Clock_Count + 1;
                        end if;
                    
                    when s_CLEANUP      =>
                        --Delay 1 clock cycle to make sure o_Rx_Done pulses properly
                        r_State         <= s_IDLE;

                    when others         =>
                        r_State         <= s_IDLE;
                end case;


            end if;
        end if;

    end process;

end architecture;