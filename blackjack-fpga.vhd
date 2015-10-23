--
-- VHDL Architecture ece412_lib.mp1cp3defaults.untitled
--
-- Created:
--          by - stears.stdt (glsn4.ews.uiuc.edu)
--          at - 14:25:25 02/06/05
--
-- using Mentor Graphics HDL Designer(TM) 2004.1 (Build 41)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

ENTITY mp1cp3 IS
   PORT( 
      CLK_32MHZ : IN     std_logic;
      PB_ENTER  : IN     std_logic;
      left_hex  : IN     std_logic_vector (3 DOWNTO 0);
      output    : IN     std_logic_vector (15 DOWNTO 0);
      pbutton   : IN     std_logic_vector (15 DOWNTO 0);
      right_hex : IN     std_logic_vector (3 DOWNTO 0);
      switches  : IN     std_logic_vector (7 DOWNTO 0);
      DebugOut  : OUT    std_logic_vector (24 DOWNTO 0);
      LEDin     : OUT    std_logic_vector (15 DOWNTO 0);
      SSD1      : OUT    std_logic_vector (3 DOWNTO 0);
      SSD2      : OUT    std_logic_vector (3 DOWNTO 0);
      SSD3      : OUT    std_logic_vector (3 DOWNTO 0);
      SSD4      : OUT    std_logic_vector (3 DOWNTO 0)
   );

-- Declarations

END mp1cp3 ;

--
ARCHITECTURE untitled OF mp1cp3 IS
  	type state is (
			  stReset,			-- Reset state
			  stInit,
		    stDeal1,
        stDeal2,
        stDeal3,
        stDeal4,
        plHit,
        plPrompt,
        plComp21,
        pldlComp,
        dlComp21,
        dlHit,
        plWin,
        dlWin,
        gameDraw,
        gameOver
          );
  signal  curStage  :  state;
  signal  nextStage :  state;
  signal  plUpdate  :  std_logic := '0';
  signal  dlUpdate  :  std_logic := '0';
  signal  plDisp    :  std_logic_vector(7 downto 0);
  signal  dlDisp    :  std_logic_vector(7 downto 0);
  signal  dealer    :  std_logic_vector(4 downto 0);
  signal  player    :  std_logic_vector(4 downto 0);
  signal  dealerAdd :  std_logic := '0';
  signal  playerAdd :  std_logic := '0';
  signal  deck      :  std_logic_vector(4 downto 0);
  signal  rst       :  std_logic;
 	signal  debounced_PB_ENTER	 : std_logic;
 	signal  debounced_pbutton15	: std_logic;
 	signal  debounced_pbutton14	: std_logic;
	signal  shift_pb1	:  std_logic_vector(3 downto 0);
	signal  shift_pb2	:  std_logic_vector(3 downto 0);
	signal  shift_pb3	:  std_logic_vector(3 downto 0);
	signal  hit       :  std_logic;
	signal  hold      :  std_logic;
	signal  cnt2Clk	  :  std_logic_vector(23 downto 0) := "000000000000000000000000";
	signal  clk256    :  std_logic;
	signal  clk_100Hz	:  std_logic;
	signal  point     :  integer;
  
  
BEGIN

   process (CLK_32MHZ, rst)
     begin
       if CLK_32MHZ = '1' and CLK_32MHZ'Event then 
 				 cnt2Clk <= cnt2Clk + 1;
       end if;
     end process;

	clk256 <= cnt2Clk(23); 
	clk_100Hz <= cnt2Clk(17);

	process
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
	rst <= debounced_PB_ENTER;

	process
		begin
  			WAIT UNTIL (clk_100Hz'EVENT) AND (clk_100Hz = '1');
		-- Use a shift register to filter switch contact bounce
  			SHIFT_PB2(2 DOWNTO 0) <= SHIFT_PB2(3 DOWNTO 1);
  			SHIFT_PB2(3) <= NOT pbutton(0);
  			IF SHIFT_PB2(3 DOWNTO 0)="0000" THEN
   				debounced_pbutton15 <= '0';
  			ELSE 
   	 			debounced_pbutton15 <= '1';
  			END IF;
		end process;
	hit <= debounced_pbutton15;

	process
		begin
  			WAIT UNTIL (clk_100Hz'EVENT) AND (clk_100Hz = '1');
		-- Use a shift register to filter switch contact bounce
  			SHIFT_PB3(2 DOWNTO 0) <= SHIFT_PB3(3 DOWNTO 1);
  			SHIFT_PB3(3) <= NOT pbutton(10);
  			IF SHIFT_PB3(3 DOWNTO 0)="0000" THEN
   				debounced_pbutton14 <= '0';
  			ELSE 
   	 			debounced_pbutton14 <= '1';
  			END IF;
		end process;
	hold <= debounced_pbutton14;

  process (clk256, right_hex)
    begin
      if (clk256'event and clk256 = '1') then
        if (right_hex = "0000") then
          deck <= "01010";
        elsif (right_hex = "0001") then
          deck <= "01011";
        elsif (right_hex < "1010") then
          deck <= '0' & right_hex;
        else
          deck <= "01010";
        end if;
      end if;
    end process;
                        
  process (clk256, playerAdd, dealerAdd, deck)
    begin
      if (clk256'event and clk256 = '0') then
        if (playerAdd = '1' and dealerAdd ='1') then
          player <= "00000";
          dealer <= "00000";
        elsif (playerAdd = '1') then
          if (deck = "01011" and player > "01010") then
            player <= player + "00001";
          elsif (deck > "01011") then
            player <= player + "01010";
          else
            player <= player + deck;
          end if;
          dealer <= dealer;
        elsif (dealerAdd = '1') then
          if (deck = "01011" and dealer > "01010") then
            dealer <= dealer + "00001";
          elsif (deck > "01011") then
            player <= player + "01010";
          else
            dealer <= dealer + deck;
          end if;
          player <= player;
        else
          dealer <= dealer;
          player <= player;
        end if;
      end if;
    end process;        

  process (clk256, curStage)
    begin
     case curStage is
        when stReset =>
          LEDin <= "1000000000000000";
          point <= 8;
        when stInit =>
          playerAdd <= '1';
          dealerAdd <= '1';
          plUpdate <= '1';
          dlUpdate <= '1';
        when stDeal1 =>
          playerAdd <= '1';
          dealerAdd <= '0';
          plUpdate <= '1';
          dlUpdate <= '0';
          LEDin <= "0100000000000000";
        when stDeal2 =>
          dealerAdd <= '1';
          playerAdd <= '0';
          plUpdate <= '0';
          dlUpdate <= '1';
          LEDin <= "0010000000000000";
        when stDeal3 =>
          playerAdd <= '1';
          dealerAdd <= '0';
          dlUpdate <= '0';
          plUpdate <= '1';
          LEDin <= "0001000000000000";			 
        when stDeal4 =>
          playerAdd <= '0';
          dealerAdd <= '1';
          dlUpdate <= '0';
          plUpdate <= '0';
          LEDin <= "0000100000000000";
        when plPrompt =>
          LEDin <= "0000010000000000";
          dealerAdd <= '0';
          playerAdd <= '0';
        when plHit =>
          playerAdd <= '1';
          dealerAdd <= '0';
          plUpdate <= '1';
          LEDin <= "0000001000000000";
        when plComp21 =>
          LEDin <= "0000000100000000";
          playerAdd <= '0';
          dealerAdd <= '0';
          plUpdate <= '0';
        when pldlComp =>
          playerAdd <= '0';
          dealerAdd <= '0';
          dlUpdate <= '1';
          LEDin <= "0000000010000000";
        when dlHit => 
          dealerAdd <= '1';
          playerAdd <= '0';
          plUpdate <= '0';
          dlUpdate <= '1';
          LEDin <= "0000000001000000";
        when dlComp21 =>
          dealerAdd <= '0';
          playerAdd <= '0';
          dlUpdate <= '0';
          LEDin <= "0000000000100000";
        when plWin =>
          LEDin <= "0000111100000000";
          point <= point - 1;
        when dlWin =>
          LEDin <= "0000000000001111";
          point <= point + 1;
        when gameDraw =>
          LEDin <= "0000000011110000";
        when gameOver =>
--          pt0 : for A in point downto 0 loop
--            LEDin(A) <= '0';
--          end loop pt0;
--          pt1 : for B in 15 downto point loop
--            LEDin(B) <= '1';
--          end loop pt1;
          point <= 0;
				when others =>
				  LEDin <= "1111111111111111";
			end case;
    end process;

  process (clk256, curStage, nextStage)
    begin
      if (rst = '1') then
        nextStage <= stReset;
      else
        case  curStage is
          when stReset =>
            nextStage <= stInit;
          when stInit =>
            nextStage <= stDeal1;
          when stDeal1 =>
            nextStage <= stDeal2;
          when stDeal2 =>
            nextStage <= stDeal3;
          when stDeal3 =>
            nextStage <= stDeal4;
          when stDeal4 =>
            nextStage <= plPrompt;
          when plPrompt =>
            if (hit = '0') then
              nextStage <= plHit;
            elsif (hold = '0') then
              nextStage <= pldlComp;
            else
              nextStage <= plPrompt;
            end if;
          when plHit =>
            nextStage <= plComp21;
          when plComp21 =>
            if (player < "10110") then
              nextStage <= plPrompt;
            else
              nextStage <= dlWin;
            end if;
          when pldlComp =>
            if (dealer > player) then
              nextStage <= dlWin;
            elsif (dealer < "10001") then
              nextStage <= dlHit;
            elsif (player > dealer) then
              nextStage <= plWin;
            else
              nextStage <= gameDraw;
            end if;
          when dlHit =>
            nextStage <= dlComp21;
          when dlComp21 =>
            if (dealer < "10110") then
              nextStage <= pldlComp;
            else
              nextStage <= plWin;
            end if;
          when gameOver =>
            if (hit = '0') then
              nextStage <= stInit;
            else
              nextStage <= gameOver;
            end if;
          when others =>
            nextStage <= gameOver;
        end case;
      end if;
      if (clk256'event and clk256 = '1') then
        curStage <= nextStage;
      end if;
    end process;

  process (clk256, dlUpdate, plUpdate, dealer, player)
    begin
      if (clk256'event and clk256 = '1') then
        if (dlUpdate = '1') then
          if (dealer < "01010") then
            dlDisp <= "000" & dealer;
          elsif (dealer < "10100") then
            dlDisp <= ("000" & dealer) + "00000110";
          elsif (dealer < "11110") then
            dlDisp <= ("000" & dealer) + "00001100";
          else
            dlDisp <= ("000" & dealer) + "00010010";
          end if;
        end if;
        if (plUpdate = '1') then
          if (player < "01010") then
            plDisp <= "000" & player;
          elsif (player < "10100") then
            plDisp <= ("000" & player) + "00000110";
          elsif (player < "11110") then
            plDisp <= ("000" & player) + "00001100";
          else
            plDisp <= ("000" & player) + "00010010";
          end if;
        end if;
      end if;
    end process;
    
    SSD1 <= plDisp(3 downto 0);
    SSD2 <= plDisp(7 downto 4);
    SSD3 <= dlDisp(3 downto 0);
    SSD4 <= dlDisp(7 downto 4);
    
    DebugOut(0) <= clk256;
    DebugOut(4 downto 1) <= right_hex;
    DebugOut(5) <= hit;
    DebugOut(6) <= hold;
    DebugOut(11 downto 7) <= dealer;
    DebugOut(16 downto 12) <= player;
    DebugOut(17) <= dlUpdate;
    DebugOut(18) <= plUpdate;
    DebugOut(23 downto 19) <= deck;    
    DebugOut(24) <= '0';
  
END ARCHITECTURE untitled;




