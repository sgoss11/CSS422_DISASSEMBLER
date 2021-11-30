*--------------------------------------------------------------------------------------------------------------
* Title      : CSS422_DISASSEMBLER
* Written by : Data Pirates
* Date       : Autumn 2021
* Description: Scans a section of memory and attempts to
*              convert the memory’s contents to a listing 
*              of valid assembly language instructions
*--------------------------------------------------------------------------------------------------------------


START       ORG        $1000            ; Start program at $1000

*--------------------------------------------------------------------------------------------------------------
*   Start Program
*--------------------------------------------------------------------------------------------------------------

INTRODUCTION
            LEA         INTRO,A1        ; Program starting message
            MOVE.B      #14,D0
            TRAP        #15    
            
MAIN_START  
            LEA         stack,SP        ; Load stack pointer  
            LEA         main_buff,A2    ; Load buffer in A2
            MOVEA.L     A2,A6           ; reference start of main buffer

*--------------------------------------------------------------------------------------------------------------
*   Exit and Clear Methods
*--------------------------------------------------------------------------------------------------------------
            
EXIT_PROGRAM            
            MOVE.B      #task1,D0
            LEA         EXIT,A1
            MOVE.W      EXIT_len,D1
            TRAP        #15
            RTS  
            
CLEAR_REG
            CLR D0                      ; clears all data registers
            CLR D1
            CLR D2                       
            CLR D3
            CLR D4
            CLR D6
            CLR D7
            
            MOVEA.L #$0, A0
            MOVEA.L #$0, A1
            MOVEA.L #$0, A2
            MOVEA.L #$0, A3
            MOVEA.L #$0, A4
            MOVEA.L #$0, A5
            MOVEA.L #$0, A6
            RTS
        
*--------------------------------------------------------------------------------------------------------------
*   USER INPUT   
*--------------------------------------------------------------------------------------------------------------

GET_INPUT            
            JSR         CLEAR_REG       ; clears all registers before starting
            NOP                         ; To prevent instruction overlap
            LEA         INPUT1,A1       ; Prompt user to enter first boundary
            MOVE        #14,D0
            TRAP        #15
            MOVE.L      #2,D0       
            TRAP        #15
            
            JSR         CONVERT_TO_HEX  ; Get first address
            MOVE.B      #14,D0                          --------> WHAT IS THIS DOING??
            TRAP        #15
            MOVE.W      A0,CURADR        ;copies the address to currnet address 

            LEA         INPUT2,A1       ; Prompt user to enter second boundary
            MOVE        #14,D0
            TRAP        #15
            LEA         BOUND2
            MOVE.L      #2,D0       
            TRAP        #15
            
            JSR         CONVERT_TO_HEX  ; Get second address
            MOVE.B      #14,D0
            TRAP        #15
            MOVE.W      D1,BOUND2       ; move address to end of memory
      

*--------------------------------------------------------------------------------------------------------------
*   Ascii To Hex   
*--------------------------------------------------------------------------------------------------------------

ASCII_TO_HEX

            MOVEM.L     D0-D4,-(SP)     ; saves data registers to stack
            MOVE.B      #TRUE,D5        ; bool = true 
            JSR         CLEAR_REG
            MOVE        #length,D6 
            
CONVERT_TO_HEX
            *JSR        CLEAR_REG       ; clears the data registers before starting
            MOVE.B      (A1)+, D2       ; post increment address reg and move each byte to D2
            CMPI.B      #$30, D2        ; if equal to 30 and greater its valid 
            BLT         INVALID_HEX     ; if less than 30, that is error in hex number, branches if less than
            CMPI.B      #$39, D2        ; greater than or equal to 30 and less than or equal to 39 would be numbers (0- 9) 
            BLE         GET_NUMBER      ; branches to get number if less than or equal to 39
            CMPI.B      #$40, D2        ; less than or equal to 40 would be the error inp
            BLE         INVALID_HEX     
            CMPI.B      #$46, D2        ; converts to capital 
            BLE         GET_CAP
            CMPI.B      #$66, D2        ; converts lowercase letters
            BLE         GET_LOWERCASE
            CMPI.B      #$66, D2        
            BGT         INVALID_HEX     ; if greater than 66, input error
                          

            
INVALID_HEX 
            *NEED TO BARNCH TO  RESTART THE PROGRAM/ ASK USER TO ENTER NEW VALUE
            LEA         ERRMSG, A1
            MOVE.B      #14,D0
            TRAP        #15
            
            MOVE.L      CURRENTADDR, D1
            MOVE.B      #3, D0      *Prints in decimal
            TRAP        #15
            
            BRA         GET_INPUT    *goes back to get the input 
            
            
GET_NUMBER
            SUBI.B      #$30, D2    *converts val of d2 to hex number val
            ADD.B       D2, D4      * updates d4 with the latest hex
            BRA         NEXT_STEP   *goes to loop
            
GET_CAP
            SUBI.B      #$37,D2     *converts to capital hex letter
            ADD.B       D2, D4      * updates the d4 with latest hex
            BRA         NEXT_STEP
            
            
GET_LOWERCASE

            SUBI.B      #$57, D2    *converts lowercase
            ADD.B       D2, D4      * updates d4
            BRA         NEXT_STEP
            
NEXT_STEP
            CMPI.W  #0, D1          *if  the length of input in d1 is 0, then done
            BEQ     DONE
            CMPI.B  #$0, (A1)       *in case its null, done
            BEQ     DONE
            *LSR    #4, D4          *shifts 4 bits to the right for new val
            LSL     #4, D4          *SHIFTS 4 BITS TO THE LEFT
            SUBI.W  #1, D1          *cuts off the input length
            BRA     CONVERT_TO_HEX  * goes back to converting to hex for new val
            
            
                   

DONE    
            MOVE.L  #0, A0          *basucally empties
            MOVE.L  D4, A0          *moves the final address to a0
            RTS                     *goes back to subroutine    

*--------------------------------------------------------------------------------------------------------------
*   MESSAGES   
*--------------------------------------------------------------------------------------------------------------

INTRO       DC.B        '------------------------------------------',CR,LF
            DC.B        CR,LF,'           Program Disassembler',CR,LF,CR,LF
            DC.B        '------------------------------------------',CR,LF,0
            
INPUT1      DC.B        'Enter starting address: $',0        ; Ask user for lower boundary
INPUT1_len  DC.W        INPUT1_len-INPUT1                    ; Gets the length of input string

INPUT2      DC.B        'Enter ending address: $',0          ; Ask user for upper boundary
INPUT2_len  DC.W        INPUT2_len-INPUT2                    ; Gets the length of input string

ERRMSG      DC.B        'Error! The input given is invalid!', 0
ERRADD      DC.B        'Error! The address given is invalid', 0

EXIT        DC.B        'End of program',0
EXIT_len    DC.W        EXIT_len-EXIT  


*--------------------------------------------------------------------------------------------------------------
*   VARIABLES & CONSTANTS
*--------------------------------------------------------------------------------------------------------------

CR          EQU         $0D
LF          EQU         $0A

BOUND1      DC.W        $0000           ; Start of memory address
BOUND2      DC.W        $0000           ; End of memory address
CURRENTADDR DC.L        1               ; holds the address of instruscion

stack       EQU         $A000           ; Stack Address
length      EQU         0               ; Effective address length to be stored in D reg
TRUE        EQU         1               ; Boolean - is true
FALSE       EQU         0               ; Boolean - is false
task0       EQU         00              ; output command
task1       EQU         01              ; output command

main_buff   DC.B        1

   

            END         START           ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
