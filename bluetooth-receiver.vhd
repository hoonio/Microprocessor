--
-- VHDL Architecture ece412_lib.receiver.mp4_send
--
-- Created:
--          by - skim41.stdt (eesn19.ews.uiuc.edu)
--          at - 10:32:49 04/22/05
--
-- using Mentor Graphics HDL Designer(TM) 2004.1 (Build 41)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

ENTITY receiver IS
   PORT( 
      CLK_100MHZ : IN     std_logic;
      PB_ENTER   : IN     std_logic;
      XUP_DIP_SW : IN     std_logic_vector (3 DOWNTO 0);
      DebugOut   : OUT    std_logic_vector (24 DOWNTO 0);
      USB_ASTB   : OUT    std_logic;
      USB_DATA   : OUT    std_logic_vector (7 DOWNTO 0);
      USB_DSTB   : OUT    std_logic;
      USB_INT    : IN    std_logic;
      USB_RESET  : OUT    std_logic;
      USB_WAIT   : IN    std_logic;
      USB_WRITE  : OUT    std_logic;
      XUP_LED    : OUT    std_logic_vector (3 DOWNTO 0)
   );

-- Declarations

END ENTITY receiver ;

--
ARCHITECTURE mp4_recv OF receiver IS
  type state is (
		start,
		adrs1,
		adrs2,
		adrs3,
		adrs4,
		write1,
		write2,
		write3,
		write4,
		read1,
		read2,
		read3,
		read4,
		read5,
		read6,
		read7,
		idle,
		terminate
          );
  signal curStage    : state;
  signal nextStage   : state;
  signal count       : integer range 0 to 7;
  signal databank    : std_logic_vector(7 downto 0);
  signal debounced_PB_ENTER  :  std_logic;
  signal shift_pb1   : std_logic_vector(3 downto 0);
  signal reset       : std_logic := '0';

BEGIN

   debouncer : process 
	 begin
 		 WAIT UNTIL (clk_100MHz'EVENT) AND (clk_100MHz = '1');
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
 
   transition : process (CLK_100MHZ, PB_ENTER, curStage, USB_WAIT, count)
   begin
     if (PB_ENTER = '1') then
       nextStage <= start;
     else
     case curStage is 
   	 when start =>
    	   nextStage <= adrs1;
     	 when adrs1 =>
     	   nextStage <= adrs2;
     	 when adrs2 =>
     	   if (USB_WAIT = '1') then
     	      nextStage <= adrs3;
     	   else
     	      nextStage <= adrs2;
     	   end if;
     	 when adrs3 =>
     	   nextStage <= adrs4;
     	 when adrs4 =>
     	   if (USB_WAIT = '0') then
    	     nextStage <= idle;
     	   else
     	      nextStage <= adrs4;
     	   end if;
     	 when write1 =>
     	   nextStage <= write2;
     	 when write2 =>
     	   if (USB_WAIT = '1') then
     	      nextStage <= write3;
     	   else
     	      nextStage <= write2;
     	   end if;
     	 when write3 =>
     	   nextStage <= write4;
     	 when write4 =>
     	   if (USB_WAIT = '0') then
     	     if (count = 3)
     	       nextStage <= read1;
     	     else
     	       nextStage <= idle;
     	     end if;
     	   else
     	      nextStage <= write4;
     	   end if;
     	 when read1 =>
     	   if (USB_WAIT = '1') then
     	      nextStage <= read2;
     	   else
     	      nextStage <= read1;
     	   end if;
     	 when read2 =>
     	   nextStage <= read3;
     	 when read3 =>
     	   if (USB_WAIT = '0') then
     	      nextStage <= terminate;
     	   else
     	      nextStage <= read4;
     	   end if;
     	 when read4 =>
     	   nextStage <= read5;
     	 when read5 =>
     	   if (USB_WAIT = '1') then
     	      nextStage <= read6;
     	   else
     	      nextStage <= read5;
     	   end if;
     	 when read6 =>
     	   nextStage <= read7;
     	 when read7 =>
     	   if (USB_WAIT = '0') then
     	      nextStage <= terminate;
     	   else
     	      nextStage <= read7;
     	   end if;
     	 when idle =>
     	   nextStage <= write1;
     	 when terminate =>
     	   nextStage <= terminate;
	 when others =>
           nextStage <= start;
 	 end case;
     end if;
     if (CLK_100MHZ'event and CLK_100MHZ = '1') then
       curStage <= nextStage;
     end if;
   end process;

   action : process (curStage)
   begin
     case curStage is 
   	 when start =>
  	   USB_RESET <= '0';
  	   count <= 0;
     	   USB_WRITE <= '1';
       	   USB_DSTB <= '1';
       	   USB_DSTB <= '1';
     	 when adrs1 =>
     	   USB_RESET <= '1';
     	   USB_WRITE <= '0';
     	   USB_DATA <= X"77";
     	 when adrs2 =>
       	   USB_ASTB <= '0';
     	 when adrs3 =>
       	   USB_ASTB <= '1';
     	 when adrs4 =>
    	   USB_WRITE <= '1';
     	 when write1 =>
     	   USB_WRITE <= '0';
     	   USB_DATA <= databank;
     	 when write2 =>
       	   USB_DSTB <= '0';
     	 when write3 =>
       	   USB_DSTB <= '1';
     	 when write4 =>
    	   USB_WRITE <= '1';
     	 when read1 =>
       	   USB_ASTB <= '0';
     	 when read2 =>
     	   XUP_LED <= USB_DATA(7 downto 4);
     	 when read3 =>
       	   USB_ASTB <= '1';
     	 when read4 =>
       	   USB_ASTB <= '1';
     	 when read5 =>
       	   USB_ASTB <= '0';
     	 when read6 =>
     	   XUP_LED <= USB_DATA(7 downto 4);
     	 when read7 =>
       	   USB_ASTB <= '1';
     	 when idle =>
     	   count <= count + 1;
     	 when terminate =>
     	   USB_DATA <= X"00";
         when others =>
  	   USB_RESET <= '1';
	 end case;
   end process;
  
  dataOut : process (count)
    begin
      case count is
        when 0 =>
          databank <= X"01";		-- sync
        when 1 =>
          databank <= X"96";		-- token PID read
        when 2 =>
          databank <= X"02";		-- 6:0 Addr 7 ENDP(0)
        when 3 =>
          databank <= X"01";		-- 2:0 ENDP(3:1)  7:3 CRC5
        when others =>
          memory <= X"00";		-- wait for ACK, ignored here
    end case;
  end process;   
  
END ARCHITECTURE mp4_recv;

