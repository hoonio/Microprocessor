--
-- VHDL Architecture ece412_lib.mp2cp1defaults.untitled
--
-- Created:
--          by - stears.stdt (eesn13.ews.uiuc.edu)
--          at - 15:30:28 02/11/05
--
-- using Mentor Graphics HDL Designer(TM) 2004.1 (Build 41)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

ENTITY mp2cp1defaults IS
   PORT( 
      CLK_32MHZ         : IN     std_logic;
      DataOut           : IN     std_logic_vector (7 DOWNTO 0);
      DataOut1          : IN     std_logic_vector (7 DOWNTO 0);
      PB_ENTER          : IN     std_logic;
      PB_UP             : IN     std_logic;
      PCMCIA_ADDR       : IN     std_logic_vector (15 DOWNTO 1);
      PCMCIA_CE1_L      : IN     std_logic;
      PCMCIA_CE2_L      : IN     std_logic;
      PCMCIA_IORD_L     : IN     std_logic;
      PCMCIA_IOWR_L     : IN     std_logic;
      PCMCIA_OE_L       : IN     std_logic;
      PCMCIA_REG_L      : IN     std_logic;
      PCMCIA_RESET_H    : IN     std_logic;
      PCMCIA_WE_L       : IN     std_logic;
      XUP_DIP_SW        : IN     std_logic_vector (3 DOWNTO 0);
      DataIn            : OUT    std_logic_vector (7 DOWNTO 0);
      GROUND            : OUT    std_logic;
      PCMCIA_CD1_L      : OUT    std_logic;
      PCMCIA_CD2_L      : OUT    std_logic;
      PCMCIA_INPACK_H   : OUT    std_logic;
      PCMCIA_IREQ_RDY_H : OUT    std_logic;
      PCMCIA_WAIT_L     : OUT    std_logic;
      PCMCIA_WP_H       : OUT    std_logic;
      ParityIn          : OUT    std_logic_vector (0 DOWNTO 0);
      en_h              : OUT    std_logic;
      en_h1             : OUT    std_logic;
      reset_h           : OUT    std_logic;
      we_h              : OUT    std_logic;
      PCMCIA_DATA       : INOUT  std_logic_vector (7 DOWNTO 0);
      PS2_CLK1_H        : INOUT  std_logic;
      PS2_DATA1_H       : INOUT  std_logic
   );

-- Declarations

END mp2cp1defaults ;

--
ARCHITECTURE untitled OF mp2cp1defaults IS
 
  	 type state is (
		 ready,
		 transaction,
		 attRead,
		 attWrite,
		 comRead,
		 comWrite,
		 polling,
		 release,
		 enter
           );
   signal  curStage  :  state;
   signal  nextStage :  state;
   signal  cardout   :  std_logic;
   signal  cardin    :  std_logic;
   signal  hex       :  std_logic_vector(7 downto 0);
   signal  CISread   :  std_logic;
   signal  readEn    :  std_logic;
   signal  writeEn   :  std_logic;
   signal  poll      :  std_logic;
   signal  memMode   :  std_logic;      -- memory mode: 0 if common memory access, 1 if attribute memory access.
   signal  memory    :  std_logic_vector(7 downto 0);
   signal  debounced_PB_ENTER  :  std_logic;
   signal  debounced_PB_UP     :  std_logic;
   signal  clk_100Hz	:  std_logic;
   signal  cnt2Clk	  :  std_logic_vector(23 downto 0) := "000000000000000000000000";
   signal  shift_pb1	:  std_logic_vector(3 downto 0);
   signal  shift_pb2	:  std_logic_vector(3 downto 0);
 
 BEGIN
   GROUND <= '0';
   PS2_CLK1_H <= 'Z';
   PS2_DATA1_H <= 'Z';
 
   PCMCIA_INPACK_H <= '0';
   PCMCIA_WAIT_L <= '1';
   PCMCIA_WP_H <= '0';
   PCMCIA_IREQ_RDY_H <= '1';
 
   XUP_LED <= XUP_DIP_SW;
   
   clk_convert : process (CLK_32MHZ)
      begin
        if CLK_32MHZ = '1' and CLK_32MHZ'Event then 
 				  cnt2Clk <= cnt2Clk + 1;
        end if;
      end process;
	 clk_100Hz <= cnt2Clk(17);
 
	 card_in : process 
		 begin
  			 WAIT UNTIL (clk_100Hz'EVENT) AND (clk_100Hz = '1');
		 -- Use a shift register to filter switch contact bounce
  			 SHIFT_PB1(2 DOWNTO 0) <= SHIFT_PB1(3 DOWNTO 1);
  			 SHIFT_PB1(3) <= NOT PB_ENTER;
  			 IF SHIFT_PB1(3 DOWNTO 0)="0000" THEN
   				 debounced_PB_ENTER <= '0';
  			 ELSE 
   	 			 debounced_PB_ENTER <= '1';
  			 END IF;
		 end process;
	 cardout <= debounced_PB_ENTER;
 
	 card_out : process 
		 begin
  			 WAIT UNTIL (clk_100Hz'EVENT) AND (clk_100Hz = '1');
		 -- Use a shift register to filter switch contact bounce
  			 SHIFT_PB2(2 DOWNTO 0) <= SHIFT_PB2(3 DOWNTO 1);
  			 SHIFT_PB2(3) <= NOT PB_UP;
  			 IF SHIFT_PB2(3 DOWNTO 0)="0000" THEN
   				 debounced_PB_UP <= '0';
  			 ELSE 
   	 			 debounced_PB_UP <= '1';
  			 END IF;
		 end process;
	 cardin <= debounced_PB_UP;
   
 
   action : process (curStage, CLK_32MHZ)
     begin
      case curStage is 
     	 when release =>
    	    PCMCIA_CD1_L <= '1';
    	    PCMCIA_CD2_L <= '1';
    	    readEn <= '0';
  	      writeEn <= '0';
  	      CISread <= '0';
  	      poll <= '0';
    	    reset_h <= '1';
     	 when enter =>
    	    PCMCIA_CD1_L <= '0';
    	    PCMCIA_CD2_L <= '0';
    	    readEn <= '0';
  	      writeEn <= '0';
  	      CISread <= '0';
  	      poll <= '0';
    	    reset_h <= '0';  	   
     	 when ready =>
    	    readEn <= '0';
  	      writeEn <= '0';
  	      poll <= '0';
  	      CISread <= '0';
       when polling =>
    	    readEn <= '0';
  	      writeEn <= '0';     
  	      memMode <= '0';
  	      poll <= '1';
  	      CISread <= '0';
  	    when attRead =>
  	      writeEn <= '0';
  	      poll <= '0';
  	      memMode <= '1';
         if (PCMCIA_ADDR > "000000000101000") then
    	      CISread <= '0';
    	      readEn <= '1';
  	      else
  	        CISread <= '1';
  	        readEn <= '0';
         end if;
  	    when attWrite =>
  	      readEn <= '0';
  	      writeEn <= '1';
  	      memMode <= '1';
  	      poll <= '0';
  	      CISread <= '0';
  	    when comRead =>
  	      readEn <= '1';
  	      writeEn <= '0';
  	      memMode <= '0';
  	      poll <= '0';
  	      CISread <= '0';
  	    when comWrite =>
  	      readEn <= '0';
  	      writeEn <= '1';
  	      memMode <= '0';
  	      poll <= '0';
  	      CISread <= '0';
  	    when others =>
    	    readEn <= '0';
  	      writeEn <= '0';
  	      memMode <= '0';
  	      poll <= '0';
  	      CISread <= '0';
  	    end case;
    end process;
    PCMCIA_DATA <= "ZZZZZZZZ";
      
   transition : process (CLK_32MHZ, curStage, cardout, cardin)
     begin
       if (cardin = '1') then
         nextStage <= ready;
       end if;
       case curStage is 
       	 when release =>
	         if (cardin = '1') then
      	      nextStage <= enter;
	         else
	           nextStage <= release;
	         end if;
       	 when enter =>
      	    nextStage <= ready;
       	 when ready =>
       	   if (PCMCIA_CE1_L = '0') then
       	     nextStage <= transaction;
     	     else
             nextStage <= ready;
           end if;
         when transaction =>
           if (PCMCIA_OE_L <= '0') then
             if (PCMCIA_REG_L = '0' and PCMCIA_ADDR = "000011111111111") then
               nextStage <= polling;
             elsif (PCMCIA_REG_L = '0') then
               nextStage <= attRead;
             else
               nextStage <= comRead;
             end if;
           elsif (PCMCIA_WE_L <= '0') then
             if (PCMCIA_REG_L = '0') then
               nextStage <= attWrite;
             else
               nextStage <= comWrite;
             end if;         
           else
             nextStage <= transaction;
           end if;
         when polling =>
            if (PCMCIA_OE_L <= '1') then
              nextStage <= ready;
            else
              nextStage <= polling;
            end if;
         when attRead =>
           if (PCMCIA_OE_L <= '1') then
             nextStage <= ready;
           else
             nextStage <= attRead;
           end if;
         when attWrite =>
           if (PCMCIA_OE_L <= '1') then
             nextStage <= ready;
           else
             nextStage <= attWrite;
           end if;      
         when comRead =>
           if (PCMCIA_OE_L <= '1') then
             nextStage <= ready;
           else
             nextStage <= attRead;
           end if;
         when comWrite =>
           if (PCMCIA_OE_L <= '1') then
             nextStage <= ready;
           else
             nextStage <= attWrite;
           end if;      
    	    when others =>
    	      nextStage <= release;
       end case;
       if (CLK_32MHZ'event and CLK_32MHZ = '1') then
         curStage <= nextStage;
       end if;
     end process;
 
   memoryOp : process (readEn, writeEn)
     begin
       if (CLK_32MHZ'event and CLK_32MHZ = '1') then
         if (readEn = '1') then
           if (memMode = '0') then
             PCMCIA_DATA <= DataOut;
             en_h <= '1';
             en_h1 <= '0';
           else
             PCMCIA_DATA <= DataOut1;
             en_h1 <= '1';
             en_h <= '0';
           end if;
           we_h <= '0';
         elsif (writeEn = '1') then
           if (memMode = '0') then
             en_h <= '1';
             en_h1 <= '0';
           else
             en_h1 <= '1';
             en_h <= '0';
           end if;
           DataIn <= PCMCIA_DATA;
           ParityIn <= "0";
           we_h <= '1';
         elsif (poll = '1') then
           DataIn <= "0000" & XUP_DIP_SW;
           PCMCIA_DATA <= "0000" & XUP_DIP_SW;
           we_h <= '1';
           en_h <= '0';
           en_h1 <= '1';
         elsif (CISread = '1') then
           PCMCIA_DATA <= memory;
           en_h <= '0';
           we_h <= '0';          
           en_h1 <= '0';
         else
           en_h <= '0';
           en_h1 <= '0';
           we_h <= '0';
         end if;
         hex <= PCMCIA_ADDR(7 downto 1) & '0';
       end if;
     end process;
 
   CISinfo : process (hex)
     begin
       case hex is
         when X"00" =>
           memory <= X"01";
         when X"02" =>
           memory <= X"03";
		     when X"04" =>
           memory <= X"61";
		     when X"06" =>
           memory <= X"05";
		     when X"08" =>
           memory <= X"FF";
		     when X"0A" =>
           memory <= X"15";
		     when X"0C" =>
           memory <= X"15";
		     when X"0E" =>
           memory <= X"05";
		     when X"10" =>
           memory <= X"01";
		     when X"12" =>
           memory <= X"45";
		     when X"14" =>
           memory <= X"43";
		     when X"16" =>
           memory <= X"45";
		     when X"18" =>
           memory <= X"34";
		     when X"1A" =>
           memory <= X"31";
		     when X"1C" =>
           memory <= X"32";
		     when X"1E" =>
           memory <= X"00";
		     when X"20" =>
           memory <= X"53";
		     when X"22" =>
           memory <= X"4B";
		     when X"24" =>
           memory <= X"49";
		     when X"26" =>
           memory <= X"4D";
		     when X"28" =>
           memory <= X"34";
		     when X"2A" =>
           memory <= X"31";
		     when X"2C" =>
           memory <= X"00";
		     when X"2E" =>
           memory <= X"31";
		     when X"30" =>
           memory <= X"00";
		     when X"32" =>
           memory <= X"31";
		     when X"34" =>
           memory <= X"00";
		     when X"36" =>
           memory <= X"FF";
		     when X"38" =>
           memory <= X"20";
		     when X"3A" =>
           memory <= X"04";
		     when X"3C" =>
           memory <= X"cd";
		     when X"3E" =>
           memory <= X"ab";
		     when X"40" =>
           memory <= X"34";
		     when X"42" =>
           memory <= X"12";
		     when X"44" =>
           memory <= X"21";
		     when X"46" =>
           memory <= X"02";
		     when X"48" =>
           memory <= X"01";
		     when X"4A" =>
           memory <= X"00";
		     when X"4C" =>
           memory <= X"14";
		     when X"4E" =>
           memory <= X"00";
		     when X"50" =>
           memory <= X"FF";
         when others =>
           memory <= X"00";
     end case;
   end process;   
  
		  		    
END ARCHITECTURE untitled;

