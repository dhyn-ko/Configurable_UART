library ieee;
use ieee.std_logic_1164.all;
use work.UartPkg.all;

entity UartTx is
    port (
        i_Clk       : in  std_logic;
        i_Rst       : in  std_logic;
        i_Tick      : in  std_logic;

        i_Tx_Start  : in  std_logic;
        i_Tx_Byte   : in  std_logic_vector
                          ((c_BYTE_WIDTH * 8) - 1 downto 0);--Configurable input
        
        o_Tx_Active : out std_logic;                        -- "Busy signal" (safety lock)
        o_Tx_Done   : out std_logic;                        -- "Finished signal" (trigger)
        o_Tx_Serial : out std_logic                         -- Actual output
  
    );
end entity;

architecture rtl of UartTx is

    type t_State is (s_IDLE, s_ALIGN, s_START_BIT, s_DATA_BITS, s_STOP_BIT);
    signal r_State : t_State := s_IDLE;
    
    signal r_Bit_Index : integer range 0 to (c_BYTE_WIDTH * 8) - 1 := 0;
    signal r_Tx_Data   : std_logic_vector((c_BYTE_WIDTH * 8) - 1 downto 0) := (others => '0');

begin

    process(i_Clk)
    begin
        if rising_edge(i_Clk) then
            
            if i_Rst = '1' then
                r_State     <= s_IDLE;
                o_Tx_Serial <= '1';
                o_Tx_Active <= '0';
                o_Tx_Done   <= '0';
                r_Bit_Index <= 0;
            else
                o_Tx_Done <= '0';
                
                case r_State is
                    
                    when s_IDLE =>
                        o_Tx_Serial <= '1';
                        o_Tx_Active <= '0';
                        r_Bit_Index <= 0;
                        
                        if i_Tx_Start = '1' then
                            r_Tx_Data   <= i_Tx_Byte;
                            o_Tx_Active <= '1';
                            r_State     <= s_ALIGN;
                        end if;
                        
                    when s_ALIGN =>
                        if i_Tick = '1' then
                            r_State <= s_START_BIT;
                        end if;
                        
                    when s_START_BIT =>
                        o_Tx_Serial <= '0';

                        if i_Tick = '1' then
                            r_State <= s_DATA_BITS;
                        end if;
                        
                    when s_DATA_BITS =>
                        o_Tx_Serial <= r_Tx_Data(r_Bit_Index);

                        if i_Tick = '1' then
                            if r_Bit_Index = (c_BYTE_WIDTH * 8) - 1 then
                                r_Bit_Index <= 0;
                                r_State     <= s_STOP_BIT;
                            else
                                r_Bit_Index <= r_Bit_Index + 1;
                            end if;
                        end if; 

                    when s_STOP_BIT =>
                        o_Tx_Serial <= '1';

                        if i_Tick = '1' then
                            o_Tx_Done   <= '1';
                            o_Tx_Active <= '0';
                            r_State     <= s_IDLE;
                        end if;

                    when others =>
                        r_State <= s_IDLE;

                end case;

            end if;

        end if;
        
    end process;

end architecture;