library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package Uartpkg is

    constant c_CLK_FREQ     : integer := 50e6;

    constant c_BAUD_RATE    : integer := 115200; -- baud signals per second

    constant c_BYTE_WIDTH   : integer := 8;

    constant c_TEST_1 : unsigned(63 downto 0) := x"1122334455667788";
    constant c_TEST_2 : unsigned(63 downto 0) := x"AABBCCDDEEFF0011";
    constant c_TEST_3 : unsigned(63 downto 0) := x"DEADBEEFCAFEFACE";
    constant c_TEST_4 : unsigned(63 downto 0) := x"1234567890ABCDEF";

    function calc_BaudLimit (clk_freq, baud_rate : in integer) return integer;

end package Uartpkg;

package body Uartpkg is

    function calc_BaudLimit(clk_freq, baud_rate : in integer) return integer is
        begin

            return clk_freq/baud_rate; -- Hz * seconds per signal => total baud signals

    end function;

end package body Uartpkg;