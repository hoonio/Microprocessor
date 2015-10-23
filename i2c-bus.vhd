--
-- VHDL Architecture ece412_lib.mp3cp2.untitled
--
-- Created:
--          by - skim41.stdt (eesn43.ews.uiuc.edu)
--          at - 16:21:23 03/28/05
--
-- using Mentor Graphics HDL Designer(TM) 2004.1 (Build 41)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

ENTITY mp3cp2 IS
   PORT( 
      VDEC1_SCLK    : OUT    std_logic;
      VDEC1_SDA     : OUT    std_logic;
      RESET_H       : OUT    std_logic;
      RESET_L       : OUT    std_logic;
      PB_ENTER      : IN     std_logic;
      RESET_VDEC1_Z : OUT    std_logic;
      VDEC1_PWRDN_Z : OUT    std_logic;
      VDEC1_OE_Z    : OUT    std_logic;
      DIN_ENABLE    : OUT    std_logic;
      XUP_LED       : OUT    std_logic_vector (3 DOWNTO 0);
      CLK_400KHZ    : IN     std_logic;
      CLK_800KHZ    : IN     std_logic
   );

-- Declarations

END mp3cp2 ;

--
ARCHITECTURE untitled OF mp3cp2 IS
 	type state is (
		start,
		inits,
		initw,
		initack,
		initp,
		idle
          );
  signal curStage    : state;
  signal nextStage   : state;
  signal regcount    : integer range 0 to 31;
  signal wordcount   : integer range 0 to 7;
  signal bitcount    : integer range 0 to 15;
  signal debounced_PB_ENTER  :  std_logic;
  signal shift_pb1	  : std_logic_vector(3 downto 0);
--  signal vgaOut      : std_logic;
  signal regAddress  : std_logic_vector(7 downto 0);
  signal regValue    : std_logic_vector(7 downto 0);
  signal slaveAddress: std_logic_vector(7 downto 0) := "01000000";
  signal intermSDA   : std_logic := '1';
--  signal dispEn      : std_logic := '0';
  signal reset       : std_logic := '0';
  
BEGIN
  
--   RESET_VDEC1_Z <= '1';
--   VDEC1_OE_Z <= '1';
--   VDEC1_PWRDN_Z <= '1';

 	 DIN_ENABLE <= '1';
   VDEC1_PWRDN_Z <= '1';
--	 dbus2 <= CONV_STD_LOGIC_VECTOR(regCount, 5);
--	 DebugOut(0) <= cnt2clk(9);
--	 DebugOut(1) <= cnt2clk(8);
--	 DebugOut(2) <= cnt2clk(1);
--	 DebugOut(6 downto 3) <= CONV_STD_LOGIC_VECTOR(bitCount, 4);
--	 DebugOut(14 downto 7) <= regAddress;
--	 DebugOut(22 downto 15) <= regValue;

	 debouncer : process 
	 begin
 		 WAIT UNTIL (clk_800KHz'EVENT) AND (clk_800KHz = '1');
	 -- Use a shift register to filter switch contact bounce
 		 SHIFT_PB1(2 DOWNTO 0) <= SHIFT_PB1(3 DOWNTO 1);
 		 SHIFT_PB1(3) <= NOT PB_ENTER;
 		 IF SHIFT_PB1(3 DOWNTO 0)="0000" THEN
 			 debounced_PB_ENTER <= '0';
 		 ELSE 
  			 debounced_PB_ENTER <= '1';
 		 END IF;
	 end process;
	 reset <= debounced_PB_ENTER;
 
   transition : process (reset, curStage, regCount, bitCount, wordCount, CLK_400KHZ)
   begin
     if (reset = '1') then
       nextStage <= start;
     else
     case curStage is 
   	   when start =>
    	    nextStage <= inits;
     	 when inits =>
     	   nextStage <= initw;
     	 when initw =>
     	   if (bitCount = 9) then
       	   nextStage <= initack;
     	   else
     	     nextStage <= initw;
   	     end if;
     	 when initack =>
     	   if (wordCount > 2 or wordCount = 0) then
       	   nextStage <= initp;
     	   else
     	     nextStage <= initw;
   	     end if;
     	 when initp =>
     	   if (regcount >= 19) then
     	     nextStage <= idle;
   	     else
       	   nextStage <= inits;
     	   end if;
     	 when idle =>
    	    nextStage <= idle;
  	    when others =>
         nextStage <= start;
 	   end case;
 	   end if;
     if (CLK_400KHZ'event and CLK_400KHZ = '1') then
       curStage <= nextStage;
     end if;
   end process;

   action : process (curStage, CLK_400KHZ)
   begin
     case curStage is 
      	when start =>
     	   RESET_L <= '0';
     	   RESET_H <= '1';
 --    	   regCount <= 0;
     	   bitCount <= 0;
--     	   wordCount <= 0;
     	   intermSDA <= '1';
     	   VDEC1_SCLK <= '1';
     	   RESET_VDEC1_Z <= '0';
     	   XUP_LED <= "0000";
      	when inits =>
         intermSDA <= '0';
     	   RESET_L <= '1';
     	   RESET_H <= '0';
   	     VDEC1_SCLK <= CLK_400KHZ;
   	     RESET_VDEC1_Z <= '1';
   	     VDEC1_OE_Z <= '1';
   	     XUP_LED <= "0101";
     	   if (CLK_400KHZ'event and CLK_400KHZ = '0') then
--     	     bitCount <= 1;
       	     if (wordCount = 0 or wordCount = 3) then
       	       intermSDA <= slaveAddress(7-bitCount);
     	       elsif (wordCount = 1) then
     	         intermSDA <= regAddress(7-bitCount);
 	           else
 	             intermSDA <= regValue(7-bitCount);
             end if;
   	     end if;
      	when initw =>
     	   VDEC1_SCLK <= CLK_400KHZ;
     	   XUP_LED <= "0110";
     	   if (CLK_400KHZ'event and CLK_400KHZ = '0') then
            if (bitcount < 8 and bitCount >= 0) then
          	  bitCount <= bitCount + 1;
       	     if (wordCount = 0) then
       	       intermSDA <= slaveAddress(7-bitCount);
     	       elsif (wordCount = 1) then
     	         intermSDA <= regAddress(7-bitCount);
 	           elsif (wordCount = 2) then
 	             intermSDA <= regValue(7-bitCount);
 	             else
 	               intermSDA <= '0';
             end if;
           elsif (bitcount = 8) then
             intermSDA <= '0';
             bitCount <= 9;
           else
             intermSDA <= '0';
           end if;
   	     end if;
      	when initack =>
      	  VDEC1_SCLK <= CLK_400KHZ;
      	  XUP_LED <= "0111";
      	    intermSDA <= '0';
      	   if (CLK_400KHZ'event and CLK_400KHZ = '0') then
      	     if (bitCount = 9) then
        	  bitCount <= 0;
        	  intermSDA <= '0';
--      	  elsif (bitCount = 0) then
--    	    else
--    	      intermSDA <= '1';
      	  end if;
--     	   elsif (CLK_400KHZ'event and CLK_400KHZ = '0') then
--        	  wor     dCount <= wordCount + 1;
--          if (bitCount = 0) then
--          else
--        	  intermSDA <= '0';
--   	     end if;
 	     end if;
      	when initp =>
  	      intermSDA <= '1';
  	      XUP_LED <= "1001";
--     	   if (CLK_400KHZ'event and CLK_400KHZ = '0') then
--        	  wordCount <= 0;
--        	  regCount <= regCount + 1;
--   	     end if;
 	       VDEC1_SCLK <= '1';
  	    when idle =>
  	      VDEC1_SCLK <= '1';
  	      intermSDA <= '1';
  	      VDEC1_OE_Z <= '0'; 
  	      XUP_LED <= "0001"; 	   
  	    when others =>
  	      XUP_LED <= "0010";
     	   RESET_L <= '1';
  	      VDEC1_PWRDN_Z <= '0';    	   
	   end case;
   end process;
   
   counter : process (reset, CLK_400KHZ, bitCount, wordCount)
   begin
     if (CLK_400KHZ'event and CLK_400KHZ = '0') then
     if (reset = '1') then
       wordCount <= 0;
       regCount <= 0;
   else
         if (wordCount = 3 and bitCount = 0) then
           wordCount <= 0;
           regCount <= regCount + 1;
       elsif (bitCount = 8) then
           wordCount <= wordCount + 1;
         end if;
       end if;
     end if;
   end process;
         
   
   vdecSDA : process (CLK_800KHZ)
   begin     
   	   if (CLK_800KHZ'event and CLK_800KHZ = '1') then
         VDEC1_SDA <= intermSDA;
--         DebugOut(23) <= intermSDA;
       end if;
--     else
--   	   if (CLK_800KHZ'event and CLK_800KHZ = '1') then
--         VDEC1_SDA <= intermSDA;
--       end if;
--     end if;
   end process;
   
   decoderValue : process (regCount)
   begin
         case regCount is
           when 0 =>
             regAddress <= X"00";
             regValue <= X"04";             
           when 1 =>
             regAddress <= X"15";
             regValue <= X"00";             
           when 2 =>
             regAddress <= X"17";
             regValue <= X"41";             
           when 3 =>
             regAddress <= X"27";
             regValue <= X"58";             
           when 4 =>
             regAddress <= X"3A";
             regValue <= X"16";             
           when 5 =>
             regAddress <= X"50";
             regValue <= X"04";             
           when 6 =>
             regAddress <= X"0E";
             regValue <= X"80";             
           when 7 =>
             regAddress <= X"50";
             regValue <= X"20";             
           when 8 =>
             regAddress <= X"52";
             regValue <= X"18";             
           when 9 =>
             regAddress <= X"58";
             regValue <= X"ED";             
           when 10 =>
             regAddress <= X"77";
             regValue <= X"C5";             
           when 11 =>
             regAddress <= X"7C";
             regValue <= X"93";             
           when 12 =>
             regAddress <= X"7D";
             regValue <= X"00";             
           when 13 =>
             regAddress <= X"D0";
             regValue <= X"48";             
           when 14 =>
             regAddress <= X"D5";
             regValue <= X"A0";             
           when 15 =>
             regAddress <= X"D7";
             regValue <= X"EA";             
           when 16 =>
             regAddress <= X"E4";
             regValue <= X"3E";             
           when 17 =>
             regAddress <= X"EA";
             regValue <= X"0F";             
           when 18 =>
             regAddress <= X"0E";
             regValue <= X"00";             
           when others =>
             regAddress <= X"00";
             regValue <= X"00";             
         end case;             
   end process;
  
END ARCHITECTURE untitled;

