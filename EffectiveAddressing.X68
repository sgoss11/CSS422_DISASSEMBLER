*-----------------------------------------------------------
*       Effective Addressing 
*       Using: 
*              A5 = Storing the EA Modes
*              D7 = Current instruction
*              data = working instruction
*-----------------------------------------------------------

*       Instruction to analyze will be stored in D7

data        DC.W    1
counter     DC.B    0

BEGIN_EA:
            MOVE.B  #0,counter   * counter to check if done
            CMP.B
            
            LEA     EA_Modes,A5  * load the modes into A5 
            CLR     D2
            CLR     D3    
            CLR     D4           
            CLR     D6
            MOVE.W  D7,data       * moves the data into D2
            ANDI.W  #00F3,data    * leaves the needed bits 
                                  * by adding 000000
            LSR.W   #3,data       * shift 3 bits
            
            MULU    #6,data       *offset by 6
            
            *ADD an index and counter to check each op mode table
*-----------------------------------------------------------
*       EA Modes 
*-----------------------------------------------------------

EA_Modes    
            JMP     EA_000      * Data Register Dn
            JMP     EA_001      * Address Register An
            JMP     EA_010      * Indirect Address Register (An)
            JMP     EA_011      * Indirect Post Increment (An)+
            JMP     EA_100      * Indirect Pre Decrement -(An)  
            JMP     EA_111      * Absolute(.W or .L) or Immediate EA 
            
*-----------------------------------------------------------
*       Data Register Dn 
*-----------------------------------------------------------
EA_000

*-----------------------------------------------------------
*       Address Register An 
*-----------------------------------------------------------
EA_001

*-----------------------------------------------------------
*       Indirect Address Register (An) 
*-----------------------------------------------------------
EA_010

*-----------------------------------------------------------
*       Indirect Post Increment (An)+
*-----------------------------------------------------------
EA_011

*-----------------------------------------------------------
*       Indirect Pre Decrement -(An) 
*-----------------------------------------------------------
EA_100

*-----------------------------------------------------------
*       Absolute(.W or .L) or Immediate EA 
*-----------------------------------------------------------
EA_111







*-----------------------------------------------------------
*   END










*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
