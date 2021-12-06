*-----------------------------------------------------------
*       Effective Addressing 
*       Using: 
*              A5 = Storing the EA Modes
*              D7 = Current instruction
*              data = working instruction
*              temp = manipulated instruction
*              A2 = stack used


******* HELP *******
*   Should the output be in hex or Ascii
*       Currently in HEX
*-----------------------------------------------------------


data        DC.W       1
temp        DC.W       1
counter     DC.B       0

            MOVE.B     #0,counter       * counter to check if done

BEGIN_EA:
            CMP.B      #5,counter       * check if equal to number of 
                                        * values in EA table
            BEQ        RTS
            
            
            LEA        EA_Modes,A5      * load the modes into A5 
            CLR        D2
            CLR        D3    
            CLR        D4           
            CLR        D6
            MOVE.W     D7,data         * moves the data into D2
            ANDI.W     #00F3,data      * leaves the needed bits 
                                       * by adding 000000
            LSR.W      #3,data         * shift 3 bits
            
            MULU       #6,data         *offset by 6
            
            ADD.I      #1,counter      * add 1 to counter
            
            JMP        END             * return to main code
            
            *ADD an index and counter to check each op mode table
*-----------------------------------------------------------
*       EA Modes 
*-----------------------------------------------------------

EA_Modes    
            JMP        EA_000          * Data Register Dn
            JMP        EA_001          * Address Register An
            JMP        EA_010          * Indirect Address Register (An)
            JMP        EA_011          * Indirect Post Increment (An)+
            JMP        EA_100          * Indirect Pre Decrement -(An)  
            JMP        EA_111          * Absolute(.W or .L) or Immediate EA 
            
*-----------------------------------------------------------
*       Data Register Dn 
*-----------------------------------------------------------
EA_000
            MOVE.W     D7,temp         * move value to temp
            *****   HELP   *****
            * Should I AND with #$7 (111) or #$000 (000)
            ANDI.W     #$7,temp        * AND 111 (isolating last 3 bits)
            
            MOVE.B     #$44,(A2)+      * move letter D into storage
            ADD.B      #$30,temp       * convert to hex
            MOVE.B     temp,(A2)+      * add the number to storage
            
            RTS
            
*-----------------------------------------------------------
*       Address Register An 
*-----------------------------------------------------------
EA_001
            MOVE.W     D7,temp         * move value to temp
            *****   HELP   *****
            * Should I AND with #$7 (111) or #$000 (000)
            ANDI.W     #$7,temp        * AND 111 (isolating last 3 bits)
            
            MOVE.B     #$41,(A2)+      * move letter A to storage
            ADD.B      #$30,temp       * convert data # to hex
            MOVE.B     temp,(A2)+      * add number to storage
            
            RTS            

*-----------------------------------------------------------
*       Indirect Address Register (An) 
*-----------------------------------------------------------
EA_010
            MOVE.W     D7,temp         * move value to temp 
            *****   HELP   *****
            * Should I AND with #$7 (111) or #$000 (000)
            ANDI.W     #$7,temp        * AND 111 (isolating last 3 bits)
            
            JMP        opcode_Par      * jumps to SR that does (A#)
            
            RTS

*-----------------------------------------------------------
*       Indirect Post Increment (An)+
*-----------------------------------------------------------
EA_011
            MOVE.W     D7,temp         * move value to temp 
            *****   HELP   *****
            * Should I AND with #$7 (111) or #$000 (000)
            ANDI.W     #$7,temp        * AND 111 (isolating last 3 bits)
            
            JMP        opcode_Par      * jumps to SR that does (A#)  
            MOVE.B     #$2B,(A2)+      * move '+' to storage

            RTS
   
*-----------------------------------------------------------
*       Indirect Pre Decrement -(An) 
*-----------------------------------------------------------
EA_100
            MOVE.W     D7,temp         * move value to temp 
            *****   HELP   *****
            * Should I AND with #$7 (111) or #$000 (000)
            ANDI.W     #$7,temp        * AND 111 (isolating last 3 bits)
            
            MOVE.B     #$2D,(A2)+      * move '-' to storage           
            JMP        opcode_Par      * jumps to SR that does (A#)

            RTS
*-----------------------------------------------------------
*       Absolute(.W or .L) or Immediate EA 
*       Needs 3 smaller subroutines to account
*       for the different data types
*-----------------------------------------------------------
EA_111
            ***** NEED TO GET THE ACTUAL BITS ******
            * 111 000   .W
            * 111 001   .L
            * 111 #     Immediate
            *   Compare the last digit with 0 and 1 
            *   to determine the size, if neither, 
            *   then it is immediate. 
EA_long

EA_word

EA_immediate




opcode_Par
            MOVE.B     #$28,(A2)+      * move '(' to storage
            MOVE.B     #$41,(A2)+      * move A to storage
            ADD.B      #$30,temp       * convert data # to hex
            MOVE.B     temp,(A2)+      * move number to storage
            MOVE.B     #$29,(A2)+      * move ')' to storage    
            
            RTS


*-----------------------------------------------------------
*   END












*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
