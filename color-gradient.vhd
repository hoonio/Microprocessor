--
-- VHDL Architecture ece412_lib.mp3_1.untitled
--
-- Created:
--          by - skim41.stdt (eesn39.ews.uiuc.edu)
--          at - 12:31:12 03/18/05
--
-- using Mentor Graphics HDL Designer(TM) 2004.1 (Build 41)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

ENTITY mp3_1 IS
   PORT( 
      CLK_100MHZ          : IN     std_logic;
      CLK_32MHZ           : IN     std_logic;
      PB_DOWN             : IN     std_logic;
      PB_ENTER            : IN     std_logic;
      PB_LEFT             : IN     std_logic;
      PB_RIGHT            : IN     std_logic;
      PB_UP               : IN     std_logic;
      XUP_DIP_SW          : IN     std_logic_vector (3 DOWNTO 0);
      VGA_COMP_SYNCH      : OUT    std_logic;
      VGA_HSYNCH          : OUT    std_logic;
      VGA_OUT_BLANK_Z     : OUT    std_logic;
      VGA_OUT_BLUE        : OUT    std_logic_vector (7 DOWNTO 0);
      VGA_OUT_GREEN       : OUT    std_logic_vector (7 DOWNTO 0);
      VGA_OUT_PIXEL_CLOCK : OUT    std_logic;
      VGA_OUT_RED         : OUT    std_logic_vector (7 DOWNTO 0);
      VGA_VSYNCH          : OUT    std_logic;
      XUP_LED             : OUT    std_logic_vector (3 DOWNTO 0)
   );

-- Declarations

END ENTITY mp3_1 ;

--
ARCHITECTURE untitled OF mp3_1 IS
  signal rowcount  : integer range 0 to 1023;
  signal columncount : integer range 0 to 1023;
  signal CLK_25MHZ  : std_logic;
  signal cnt2clk    : std_logic_vector(2 downto 0) := "000";
  signal gradient  : std_logic_vector(9 downto 0);
  
BEGIN


  VGA_COMP_SYNCH <= '1';

   clk_convert : process (CLK_100MHZ)
      begin
        if (CLK_100MHZ = '1' and CLK_100MHZ'Event) then 
 				  cnt2Clk <= cnt2Clk + 1;
        end if;
      end process;
	 clk_25MHZ <= cnt2Clk(1);
	 VGA_OUT_PIXEL_CLOCK <= cnt2clk(1);

   count : process (CLK_25MHZ)
   begin
     if (CLK_25MHZ = '1' and CLK_25MHZ'EVENT) then
       columncount <= columncount + 1;
     end if;
     if (columncount > 800) then
       columncount <= 1;
       rowcount <= rowcount + 1;
     end if;
     if (rowcount >= 520) then
       rowcount <= 1;
     end if;
   end process;
   
   syncout : process (CLK_25MHZ)
   begin
     if (CLK_25MHZ = '1' and CLK_25MHZ'EVENT) then
       if (rowcount = 494) then
         VGA_VSYNCH <= '0';
       else
         VGA_VSYNCH <= '1';
       end if;
       if (columncount >= 660 and columncount < 756) then
         VGA_HSYNCH <= '0';
       else
         VGA_HSYNCH <= '1';
       end if;
       if (rowcount > 480 or columncount > 640) then
         VGA_OUT_BLANK_Z <= '0';
       else
         VGA_OUT_BLANK_Z <= '1';
       end if;
     end if;
   end process;
   
   display : process
   begin
     wait until (CLK_25MHZ = '1' and CLK_25MHZ'EVENT);
     if (rowcount >= 60 and rowcount < 320) then
       if (columncount >= 576) then
         VGA_OUT_RED <= X"00";
         VGA_OUT_BLUE <= X"00";
         VGA_OUT_GREEN <= X"00";
       elsif (columncount >= 480) then
         VGA_OUT_RED <= X"00";
         VGA_OUT_BLUE <= X"FF";
         VGA_OUT_GREEN <= X"FF";
       elsif (columncount >= 320) then
         VGA_OUT_RED <= X"FF";
         VGA_OUT_BLUE <= X"00";
         VGA_OUT_GREEN <= X"00";
       elsif (columncount >= 160) then
         VGA_OUT_RED <= X"FF";
         VGA_OUT_BLUE <= X"00";
         VGA_OUT_GREEN <= X"FF";
       elsif (columncount >= 64) then
         VGA_OUT_RED <= X"FF";
         VGA_OUT_BLUE <= X"FF";
         VGA_OUT_GREEN <= X"00";
       else
         VGA_OUT_RED <= X"00";
         VGA_OUT_BLUE <= X"00";
         VGA_OUT_GREEN <= X"00";
       end if;
     elsif (rowcount >= 320 and rowcount < 420) then
       if (columncount >= 64 and columncount < 576) then
         gradient <= CONV_STD_LOGIC_VECTOR(columncount - 64, 10);
         VGA_OUT_RED <= gradient(8 downto 1);
         VGA_OUT_BLUE <= gradient(8 downto 1);
         VGA_OUT_GREEN <= gradient(8 downto 1);
       else
         VGA_OUT_RED <= X"00";
         VGA_OUT_BLUE <= X"00";
         VGA_OUT_GREEN <= X"00";
       end if;
     else
         VGA_OUT_RED <= X"00";
         VGA_OUT_BLUE <= X"00";
         VGA_OUT_GREEN <= X"00";
       end if;
     end process;
       

END ARCHITECTURE untitled;

