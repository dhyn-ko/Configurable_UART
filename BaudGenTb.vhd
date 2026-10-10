library ieee;
use ieee.std_logic_1164.all;
use work.Uartpkg.all;
use std.env.all;

entity BaudGenTb is
    constant tb_Clock_Period : time := 1000 ms / c_CLK_FREQ;
end entity;

architecture sim of BaudGenTb is
    signal r_Clk    :   std_logic   :=  '0';
    signal r_Rst    :   std_logic   :=  '1';
    signal w_Tick   :   std_logic;
begin

    baud_inst : entity work.BaudGen(rtl)
    port map(
        i_Clk   =>  r_Clk,
        i_Rst   =>  r_Rst,
        o_Tick  =>  w_Tick
    );

    r_Clk <= not r_Clk after tb_Clock_Period/2;

    process is
    begin

        wait for 100 ns;
        wait until rising_edge(r_Clk);
        r_Rst   <=  '0';    --release reset after 100 ns
        wait until rising_edge(r_Clk);
        wait for 100 us;    --runtime 100 microseconds

        finish;

    end process;

end architecture;