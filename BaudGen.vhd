library ieee;
use ieee.std_logic_1164.all;
use work.UartPkg.all;


entity BaudGen is

    port (
        i_Clk   : in    std_logic;
        i_Rst   : in    std_logic;
        o_Tick  : out   std_logic
    );

end entity;

architecture rtl of BaudGen is

    constant c_LIMIT : integer := calc_BaudLimit(c_CLK_FREQ, c_BAUD_RATE);

    signal r_Counter : integer range 0 to c_LIMIT - 1 := 0;

begin

    process(i_Clk) is
    begin
        if rising_edge(i_Clk) then
            if i_Rst = '1' then
                r_Counter   <=  0;
                o_Tick      <= '0';
            else
                if r_Counter = c_LIMIT - 1 then
                    r_Counter   <= 0;
                    o_Tick      <= '1';
                else
                    r_Counter   <= r_Counter + 1;
                    o_Tick      <= '0';
                end if;
            end if;
        end if;
    end process;
    
end architecture;