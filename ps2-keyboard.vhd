
--
-- VHDL Architecture ece412_lib.PS2_reader.untitled
--
-- Created:
--          by - skim41.stdt (eesn43.ews.uiuc.edu)
--          at - 23:11:24 02/06/05
--
-- using Mentor Graphics HDL Designer(TM) 2004.1 (Build 41)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

ENTITY PS2 IS
   PORT( 
      PS2_DATA1_H : INOUT  std_logic;
      PS2_CLK1_H  : INOUT  std_logic;
      SSD1        : OUT    std_logic_vector (3 DOWNTO 0);
      SSD2        : OUT    std_logic_vector (3 DOWNTO 0);
      LEDin       : OUT    std_logic_vector (15 DOWNTO 0);
      DebugOut    : OUT    std_logic_vector (24 DOWNTO 0);
      PB_ENTER    : IN     std_logic
   );

-- Declarations

END PS2 ;

ARCHITECTURE untitled OF PS2 IS
  signal  reg11     :  std_logic_vector(10 downto 0) := "10101010101";
  signal  rst       :  std_logic;
 	signal  debounced_PB_ENTER	 : std_logic;
	signal  shift_pb1	:  std_logic_vector(3 downto 0);
  
BEGIN
  
	process
		begin
  			WAIT UNTIL (PS2_CLK1_H'EVENT) AND (PS2_CLK1_H = '1');
		-- Use a shift register to filter switch contact bounce
  			SHIFT_PB1(2 DOWNTO 0) <= SHIFT_PB1(3 DOWNTO 1);
  			SHIFT_PB1(3) <= NOT PB_ENTER;
  			IF SHIFT_PB1(3 DOWNTO 0)="0000" THEN
   				debounced_PB_ENTER <= '0';
  			ELSE 
   	 			debounced_PB_ENTER <= '1';
  			END IF;
		end process;
	rst <= debounced_PB_ENTER;

  PS2 : process (PS2_CLK1_H, PS2_DATA1_H, reg11, PB_ENTER)
  BEGIN
    if (PS2_CLK1_H'event and PS2_CLK1_H = '0') then
        reg11 <= PS2_DATA1_H & reg11(10 downto 1);
    end if;
    if (rst = '1') then
      reg11 <= "00000000000";
    end if;
  end process PS2;

      SSD2 <= reg11(8 downto 5);
      SSD1 <= reg11(4 downto 1);   
      LEDin(15) <= reg11(9);
      DebugOut(0) <= PS2_CLK1_H;
      DebugOut(1) <= PS2_DATA1_H;
      DebugOut(12 downto 2) <= reg11;
      DebugOut(24 downto 13) <= "000000000000";
      LEDin(11 downto 0) <= reg11;
      LEDin(14 downto 12) <= "000";  
      PS2_CLK1_H <= 'Z';
      PS2_DATA1_H <= 'Z';
    
END ARCHITECTURE untitled;
