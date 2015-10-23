--
-- VHDL Architecture ece412_lib.mp2cp2defautls.untitled
--
-- Created:
--          by - stears.stdt (eesn18.ews.uiuc.edu)
--          at - 12:23:32 02/19/05
--
-- using Mentor Graphics HDL Designer(TM) 2004.1 (Build 41)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

ENTITY mp2cp2defautls IS
   PORT( 
      CLK_32MHZ         : IN     std_logic;
      DataOut           : IN     std_logic_vector (7 DOWNTO 0);
      DataOut1          : IN     std_logic_vector (7 DOWNTO 0);
      PCMCIA_ADDR       : IN     std_logic_vector (15 DOWNTO 1);
      PCMCIA_CE1_L      : IN     std_logic;
      PCMCIA_OE_L       : IN     std_logic;
      PCMCIA_REG_L      : IN     std_logic;
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
      XUP_LED           : OUT    std_logic_vector (3 DOWNTO 0);
      en_h              : OUT    std_logic;
      en_h1             : OUT    std_logic;
      reset_h           : OUT    std_logic;
      we_h              : OUT    std_logic;
      PCMCIA_DATA       : INOUT  std_logic_vector (7 DOWNTO 0);
      PCMCIA_WE_L       : IN     std_logic
   );

-- Declarations

END mp2cp2defautls ;

--
ARCHITECTURE untitled OF mp2cp2defautls IS

  	type state is (
		ready,
		release,
		enter
          );
  signal  curStage  :  state;
  signal  nextStage :  state;
  signal  hex       :  std_logic_vector(7 downto 0);
  signal  CISread   :  std_logic;
  signal  readEn    :  std_logic;
  signal  writeEn   :  std_logic;
  signal  poll      :  std_logic;
  signal  memMode   :  std_logic;      -- memory mode: 0 if common memory access, 1 if attribute memory access.
  signal  memory    :  std_logic_vector(7 downto 0);

BEGIN
  GROUND <= '0';

  PCMCIA_INPACK_H <= '0';
  PCMCIA_WAIT_L <= '1';
  PCMCIA_WP_H <= '0';
  PCMCIA_IREQ_RDY_H <= '1';
  
  action : process (curStage, CLK_32MHZ, PCMCIA_WE_L, PCMCIA_OE_L, PCMCIA_CE1_L, PCMCIA_REG_L, PCMCIA_ADDR)
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
    	   reset_h <= '0';  	   
        if (PCMCIA_REG_L = '0') then
          memMode <= '1';
        else
          memMode <= '0';
        end if;
        if (PCMCIA_CE1_L = '0') then
          if (PCMCIA_OE_L = '0') then
            if (PCMCIA_REG_L = '0' and PCMCIA_ADDR = "000011111111111") then
              poll <= '1';
          	   readEn <= '0';
    	         writeEn <= '0';
    	         CISread <= '0';
            elsif (PCMCIA_REG_L = '0' and PCMCIA_ADDR < "000000000101001") then
              CISread <= '1';
          	   readEn <= '0';
    	         writeEn <= '0';
  	           poll <= '0';
            else
        	     readEn <= '1';
     	        writeEn <= '0';
     	        CISread <= '0';
   	          poll <= '0';
             end if;
          elsif (PCMCIA_WE_L = '0') then
            writeEn <= '1';
        	   readEn <= '0';
   	        CISread <= '0';
 	          poll <= '0';
          else
        	   readEn <= '0';
    	       writeEn <= '0';
    	       CISread <= '0';
  	         poll <= '0';
          end if;
        else
      	   readEn <= '0';
    	     writeEn <= '0';
    	     CISread <= '0';
  	       poll <= '0';
        end if;
    	   PCMCIA_CD1_L <= '0';
    	   PCMCIA_CD2_L <= '0';
  	   when others =>
    	   readEn <= '0';
  	     writeEn <= '0';
  	     poll <= '0';
  	     CISread <= '0';
  	   end case;
   end process;

     
  transition : process (CLK_32MHZ, XUP_DIP_SW)
    begin
      if (XUP_DIP_SW(3) = '0') then
       nextStage <= release;
      end if;
      case curStage is 
       	when release =>
	        if (XUP_DIP_SW(3) = '1') then
      	     nextStage <= enter;
	        else
	          nextStage <= release;
	        end if;
       	when enter =>
      	   nextStage <= ready;
       	when ready =>
          nextStage <= ready;
    	   when others =>
    	     nextStage <= release;
      end case;
      if (CLK_32MHZ'event and CLK_32MHZ = '1') then
        curStage <= nextStage;
      end if;
    end process;

  memoryOp : process (readEn, writeEn, memMode, poll, CISread, PCMCIA_DATA)
    begin
--      PCMCIA_DATA <= "ZZZZZZZZ";
      if (CLK_32MHZ'event and CLK_32MHZ = '1') then
        if (readEn = '1') then
          if (memMode = '0') then
            PCMCIA_DATA <= DataOut;
          else
            PCMCIA_DATA <= DataOut1;
          end if;
            en_h <= NOT memMode;
            en_h1 <= memMode;
            we_h <= '0';
        elsif (writeEn = '1') then
          en_h <= NOT memMode;
          en_h1 <= memMode;
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
      XUP_LED <= XUP_DIP_SW;
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

