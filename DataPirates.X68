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
            BSR         CLEAR_REG       ; Clear all data registers    
            LEA         stack,SP        ; Load stack pointer  
            LEA         main_buff,A2    ; Load buffer in A2
            MOVEA.L     A2,A6           ; Reference start of main buffer

*--------------------------------------------------------------------------------------------------------------
*   USER INPUT   
*--------------------------------------------------------------------------------------------------------------

GET_INPUT    
            MOVE        #task1,D0
            LEA         INPUT1,A1       ; Prompt user to enter start boundary
            MOVE.W      INPUT1_len,D1         
            TRAP        #15
            ADDA        #INPUT1_len,A1  ; Adds user input after prompt
            MOVE        #task2,D0      
            TRAP        #15
            JSR         asciiTOhex      ; Save info to stack, checks if valid
            CMP.B       #$00,D5         ; Check if boolean is false
            
            MOVEA.L     A0,A4         
            MOVE.B      #task1,D0
            LEA         INPUT2,A1       ; Prompt user to enter end boundary
            MOVE.W      INPUT2_len,D1         
            TRAP        #15         
            ADDA.L      #INPUT2_len,A1  ; Add user input after prompt
            MOVE.B      #task2,D0
            TRAP        #15
            JSR         asciiTOhex      ; Save info to stack, checks if valid
            CMP.B       #$00,D5         ; Check if boolean is false
            
            MOVEA.L     A4,A3           ; Stores starting address into A3
            MOVEA.L     A0,A4           ; Stores endinging address into A4
            MOVEA.L     A3,A0           ; Stores starting address into A0 to be first 
            
            BSR         CHECK_ADDRESS   ; Check if address is valid           
            CMP         #FALSE,D5       ; If not valid, Bool = False
            BEQ         GET_INPUT       ; Return to input prompts

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
*   CHECK ADDRESS VALIDITY
*--------------------------------------------------------------------------------------------------------------

CHECK_ADDRESS

CHECK_START
            CMP.B       #$00,D5         ; Check if boolean is false
            BEQ         CHECK_END       ; Address error
            MOVE.B      #TRUE,D5        ; Set boolean to true
            
CHECK_END   RTS


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
            
            
                   

RETURN    
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

MORE_DATA   DC.B        'Press enter for more data',0
MORE_len    DC.W        MORE_DATA-MORE_len

CONTINUE    DC.B        'Would you like to continue disassembling? Y = 1, N = 0: ',0
CONT_len    DC.W        CONT_len-CONTINUE

EXIT        DC.B        'End of program',0
EXIT_len    DC.W        EXIT_len-EXIT  

main_buff   DC.B        1


*--------------------------------------------------------------------------------------------------------------
*   VARIABLES & CONSTANTS
*--------------------------------------------------------------------------------------------------------------

CR          EQU         $0D
LF          EQU         $0A

minBOUND    DC.W        $00000000       ; Minimum bound
minBOUND    DC.W        $FFFFFFFF       ; Maximum bound

CURRENTADDR DC.L        1               ; holds the address of instruscion

stack       EQU         $A000           ; Stack Address
length      EQU         0               ; Effective address length to be stored in D reg
TRUE        EQU         1               ; Boolean - is true
FALSE       EQU         0               ; Boolean - is false
task0       EQU         00              ; output command
task1       EQU         01              ; output command



   

            END         START           ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
