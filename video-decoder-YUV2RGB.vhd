--
-- VHDL Architecture ece412_lib.YUV2RGB.untitled
--
-- Created:
--          by - skim41.stdt (eesn19.ews.uiuc.edu)
--          at - 01:17:41 04/21/05
--
-- using Mentor Graphics HDL Designer(TM) 2004.1 (Build 41)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

ENTITY YUV2RGB IS
   PORT( 
      LLC_CLOCK     : IN     std_logic;
      RESET_L       : IN     std_logic;
      VDEC1_FIELD   : IN     std_logic;
      VDEC1_HS      : IN     std_logic;
      VDEC1_VS      : IN     std_logic;
      YCrCb_in      : IN     std_logic_vector (7 DOWNTO 0);
      RAM_ADDR      : OUT    std_logic_vector (15 DOWNTO 0);
      RAM_DATA      : OUT    std_logic_vector (14 DOWNTO 0);
      RAM_WR_ENABLE : OUT    std_logic
   );

-- Declarations

END ENTITY YUV2RGB ;

--
ARCHITECTURE untitled OF YUV2RGB IS
  type state is (
	idle,
	stop,
	CB,
	Y1,
	CR,
	Y2
  );
  signal curStage    	: state;
  signal nextStage   	: state;
  signal data1		: std_logic_vector (7 downto 0);
  signal data2		: std_logic_vector (7 downto 0);
  signal data3		: std_logic_vector (7 downto 0);
  signal data4		: std_logic_vector (7 downto 0);
  signal rowCount	: std_logic_vector (7 downto 0);
  signal columnCount	: std_logic_vector (8 downto 0);
  signal intermY	: std_logic_vector (15 downto 0);
  signal intermU1	: std_logic_vector (23 downto 0);
  signal intermU2	: std_logic_vector (23 downto 0);
  signal intermV1	: std_logic_vector (23 downto 0);
  signal intermV2	: std_logic_vector (23 downto 0);
  signal Y		: std_logic_vector (7 downto 0);
  signal U1		: std_logic_vector (7 downto 0);
  signal V1		: std_logic_vector (7 downto 0);
  signal U2		: std_logic_vector (7 downto 0);
  signal V2		: std_logic_vector (7 downto 0);
  signal R		: std_logic_vector (7 downto 0);
  signal G		: std_logic_vector (7 downto 0);
  signal B		: std_logic_vector (7 downto 0);
	
BEGIN
  
   transition : process (LLC_CLOCK, VDEC1_HS)
   begin
     case curStage is 
   	 when idle =>
    	    if (VDEC1_HS = '0') then
    	       nextStage <= CB;
    	    else
    	       nextStage <= idle;   
    	    end if;
     	 when CB =>
     	   nextStage <= Y1;
     	 when Y1 =>
     	   nextStage <= CR;
     	 when CR =>
     	   nextStage <= Y2;
     	 when Y2 =>
       	   if (VDEC1_HS = '1') then
       	      nextStage <= stop;
       	   else
       	      nextStage <= CB;
       	   end if;
       	 when stop =>
       	   nextStage <= idle;
         when others =>
           nextStage <= idle;
     end case;
     if (LLC_CLOCK'event and LLC_CLOCK = '1') then
       curStage <= nextStage;
     end if;
   end process;

   action : process (LLC_CLOCK)
   begin
     case curStage is 
      	when idle =>
      	   rowCount <= "00000000";
      	   columnCount <= "000000000";
      	when CB =>
      	   data1 <= YCrCb_in;
      	   if (rowCount < "01000000" and columnCount < "010000000") then
      	      R <= Y + V1;
      	      G <= Y - U2 - V2;
      	      B <= Y + U1;
      	      RAM_WR_ENABLE <= '1';
       	      RAM_DATA <= R(7 downto 3) & G(7 downto 3) & B(7 downto 3);
      	   end if;
      	when Y1 =>
      	   RAM_WR_ENABLE <= '0';
      	   data2 <= YCrCb_in;
      	   intermU1 <= (data1 - "10000000")*"10010001"*"11100011";	-- *145*227
      	   intermU2 <= (data1 - "10000000")*"10010001"*"00101100";	-- *145*44
      	   U1 <= intermU1(21 downto 14);				-- /128/128
      	   U2 <= intermU2(21 downto 14);				-- /128/128
      	when CR =>
      	   data3 <= YCrCb_in;
      	   intermY <= (data2 - "10000000")*"10010101";			-- *149
      	   Y <= intermY(14 downto 7);					-- /128
      	   if (rowCount < "01000000" and columnCount < "010000000") then
      	      if (VDEC1_FIELD = '0') then
      	         RAM_ADDR <= rowCount(6 downto 0) & '1' & columnCount(7 downto 0);
      	      else
      	         RAM_ADDR <= rowCount(6 downto 0) & '0' & columnCount(7 downto 0);
      	      end if;
      	   end if;
      	when Y2 =>
      	   data4 <= YCrCb_in;
      	   intermV1 <= (data3 - "10000000")*"10010001"*"10110100";	-- *145*180
      	   intermV2 <= (data3 - "10000000")*"10010001"*"01011011";	-- *145*91
      	   V1 <= intermV1(21 downto 14);				-- /128/128
      	   V2 <= intermV2(21 downto 14);				-- /128/128
 	   if (LLC_CLOCK'event and LLC_CLOCK = '1') then
 	      columnCount <= columnCount + "000000001";   
       	   end if;
      	when stop =>
 	   if (LLC_CLOCK'event and LLC_CLOCK = '1') then
      	      rowCount <= rowCount + "00000001";
       	      columnCount <= "000000000";
       	   end if;
        when others =>
     end case;
   end process;

END ARCHITECTURE untitled;

