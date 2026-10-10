library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.UartPkg.all;
use std.env.all;

entity UartRxTb is
    constant tb_Clock_Period : time := 1000 ms / c_CLK_FREQ;
end entity;

architecture sim of UartRxTb is
    
    -- System signals
    signal r_Clk       : std_logic := '0';
    signal r_Rst       : std_logic := '1';
    
    -- Baud
    signal w_Tick      : std_logic;
    
    -- Serial wire
    signal w_Serial    : std_logic := '1';
    
    -- Transmitter input
    signal r_Tx_Start  : std_logic := '0';
    signal r_Tx_Byte   : std_logic_vector((c_BYTE_WIDTH * 8) - 1 downto 0) 
                                                := (others => '0');
    
    -- Transmitter output
    signal w_Tx_Active : std_logic;
    signal w_Tx_Done   : std_logic;

    -- Receiver output
    signal w_Rx_Active : std_logic;
    signal w_Rx_Done   : std_logic;
    signal w_Rx_Byte   : std_logic_vector((c_BYTE_WIDTH * 8) - 1 downto 0);

begin

    -- Clock Generation
    r_Clk <= not r_Clk after tb_Clock_Period / 2;

    -- Baud
    baud_inst : entity work.BaudGen(rtl)
    port map(
        i_Clk  => r_Clk,
        i_Rst  => r_Rst,
        o_Tick => w_Tick
    );

    -- Transmitter
    tx_inst : entity work.UartTx(rtl)
    port map(
        i_Clk       => r_Clk,
        i_Rst       => r_Rst,
        i_Tick      => w_Tick,
        i_Tx_Start  => r_Tx_Start,
        i_Tx_Byte   => r_Tx_Byte,
        o_Tx_Active => w_Tx_Active,
        o_Tx_Serial => w_Serial,    -- OUT to the wire
        o_Tx_Done   => w_Tx_Done
    );

    -- Receiver
    rx_inst : entity work.UartRx(rtl)
    port map(
        i_Clk       => r_Clk,
        i_Rst       => r_Rst,
        i_Rx_Serial => w_Serial,    -- IN from the wire
        o_Rx_Active => w_Rx_Active,
        o_Rx_Done   => w_Rx_Done,
        o_Rx_Byte   => w_Rx_Byte
    );

    process is

        procedure SendTestValue(
            i_Data : in unsigned(63 downto 0);
            i_Wait_Time : in time
        ) is
        begin
            wait until rising_edge(r_Clk);
            
            r_Tx_Byte  <= std_logic_vector(resize(i_Data, c_BYTE_WIDTH * 8));
            r_Tx_Start <= '1';
            
            wait until rising_edge(r_Clk);
            r_Tx_Start <= '0';
            
            -- Wait on receiver
            wait until w_Rx_Done = '1';
            
            -- Wait one clock cycle
            wait until rising_edge(r_Clk);

            -- Data value check
            assert w_Rx_Byte = r_Tx_Byte
                report "Data mismatch! transmitter: " & integer'image(to_integer(unsigned(r_Tx_Byte))) & 
                       ", receiver: " & integer'image(to_integer(unsigned(w_Rx_Byte)))
                severity failure;
            wait until w_Tx_Done = '1';
            
            wait for i_Wait_Time;
        end procedure;

    begin
        
        -- Unlock (undo reset)
        wait for 100 ns;
        wait until rising_edge(r_Clk);
        r_Rst <= '0';
        wait for 100 ns;
        wait until rising_edge(r_Clk);
        
        -- Tests
        SendTestValue(c_TEST_1, 10  ns);
        SendTestValue(c_TEST_2, 1   us);
        SendTestValue(c_TEST_3, 50  ns);
        SendTestValue(c_TEST_4, 100 ns);
        SendTestValue(c_TEST_2, 3   us);

        wait for 50 us;

        finish;

    end process;

end architecture;