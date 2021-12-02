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
            BSR         CLEAR_REG1      ; Clear all data registers    
            LEA         stack,SP        ; Load stack pointer  
            LEA         main_buff,A2    ; Load buffer in A2
            MOVEA.L     A2,A6           ; Reference start of main buffer

*--------------------------------------------------------------------------------------------------------------
*   USER INPUT: User inputs upper and lower bound for dissasembler, from
*               there it will be added to a stack and checked if address 
*               is valid and will execute               
*
*   Registers used:
*       - A0: starting address (INPUT1)
*       - A4: ending address (INPUT2)
*       - D2: copy of address
*       - D3: utility register
*       - D5: boolean
*--------------------------------------------------------------------------------------------------------------

GET_INPUT    
            MOVE        #task1,D0
            LEA         INPUT1,A1       ; Prompt user to enter start boundary
            MOVE.W      INPUT1_len,D1         
            TRAP        #15
            ADDA        #INPUT1_len,A1  ; Adds user input after prompt
            MOVE        #task2,D0      
            TRAP        #15
            JSR         ASCII_TO_HEX    ; Save info to stack, checks if valid
            CMP.B       #$00,D5         ; Check if boolean is false
            
            MOVEA.L     A0,A4         
            MOVE.B      #task1,D0
            LEA         INPUT2,A1       ; Prompt user to enter end boundary
            MOVE.W      INPUT2_len,D1         
            TRAP        #15         
            ADDA.L      #INPUT2_len,A1  ; Add user input after prompt
            MOVE.B      #task2,D0
            TRAP        #15
            JSR         ASCII_TO_HEX    ; Save info to stack, checks if valid
            CMP.B       #$00,D5         ; Check if boolean is false
            
            MOVEA.L     A4,A3           ; Stores starting address into A3
            MOVEA.L     A0,A4           ; Stores endinging address into A4
            MOVEA.L     A3,A0           ; Stores starting address into A0 to be first 
            
            BSR         CHECK_ADDRESS   ; Check if address is valid           
            CMP         #FALSE,D5       ; If not valid, Bool = False
            BEQ         GET_INPUT       ; Return to input prompts
            
            BSR         BUFFER          ; To fill buffer with current address
            
            MOVE.B      #task1,D0
            LEA         REPEAT,A1       ; Asks if user wants to enter new boundaries
            MOVE.W      REPEAT_len,D1
            TRAP        #15            
            MOVE.B      #task2,D0
            TRAP        #15
            
            MOVE.B      (A1),D3         ; Copies user input to D3
            
            MOVE.B      #$57,(A1)+      ; Write in "W"
            MOVE.B      #$6F,(A1)       ; Write in "u"
            
            CMP.B       #$31,D3         ; Compares ASCII values to D3
            BEQ         MAIN_START
             
            BEQ         MAIN_START      ; Restart input prompts
            
            BSR         EXIT_PROGRAM    ; Exit program                  
            JMP         END


*--------------------------------------------------------------------------------------------------------------
*   CHECK ADDRESS: Checks if address is even, is within boundaries, and if
*                  the starting address isn't greater than the ending
*   
*   Registers used:
*       - A0: starting address (INPUT1)
*       - A4: ending address (INPUT2)
*       - D2: copy of address
*       - D3: utility register
*       - D5: boolean
*--------------------------------------------------------------------------------------------------------------

CHECK_ADDRESS:

CHECK_START
            CMP.B       #$00,D5         ; Check if boolean is false
            BEQ         CHECK_ERROR     ; Address error
            MOVE.B      #TRUE,D5        ; Set boolean to true

ADD1        MOVE.L      A0,D2           ; Loads start boundary to D regs
            MOVE.L      D2,D3
            ANDI.B      #1,D3           ; Checks last bit in D2
            CMP.B       #1,D3
            BNE         minBOUND        ; Last bit = 0; go to even branch
            
SUB1        SUBI.B      #$1,D2          ; Allows odd address to be even
            MOVE.L      D2,A0    
            
ADD2        MOVE.L      A4,D2           ; Loads ending boundary to D regs
            MOVE.L      D2,D3
            ANDI.B      #1,D3           ; Checks last bit in D2
            CMP.B       #1,D3
            BNE         EQU1 
            
SUB2        SUBI.B      #$1,D2          ; Allows odd address to be even
            MOVE.L      D2,A4
              
EQU1        CMP.L       #maxBOUND,A0      ; Checks if starting address < $00FFFFFF
            BLT         EQU2            ; If so, branch to EQU2        
            JMP         CHECK_ERROR     ; If not, address error
            
EQU2        CMP.L       #maxBOUND,A4      ; checks if ending address <= $00FFFFFF
            BLE         EQU3            ; If so, branch to EQU3
            JMP         CHECK_ERROR     ; If not, address error               
            
EQU3        CMPA.L      A0,A4           ; Checks if ending address > starting address
            BGT         CHECK_END
               
CHECK_ERROR
            MOVE.B      #task0,D0
            LEA         ERRPARAM,A1
            MOVE.W      PARAM_len,D1
            TRAP        #15        
            MOVE.B      #FALSE,D5
                        
CHECK_END   RTS


*--------------------------------------------------------------------------------------------------------------
*   Ascii To Hex: Add data to stack, converts to hex, and checks length of address
*   
*   Registers used:
*       - D3: Placeholder for current ascii byte (based off of user's input address)   
*       - D4: Translated Address
*       - D5: Boolean
*       - A0: At the end of the routine, store the converted address here
*--------------------------------------------------------------------------------------------------------------

ASCII_TO_HEX

            MOVEM.L     D0-D4,-(SP)         ; Saves data registers to stack
            MOVE.B      #TRUE,D5            ; Bool = true
            JSR         CLEAR_REG2
            MOVE        #length,D6      
      
CONVERT_TO_HEX
            MOVE.B      (A1)+,D3            ; Post increment address reg and move each byte to D3 (user's input)
            CMP.B       #$30,D3             ; If ascii byte < 30 and greater, its valid
            BLT         INVALID_HEX
            CMP.B       #$3A,D3             ; If ascii byte < 3A, convert to num
            BLT         GET_NUMBER      
            CMP.B       #$41,D3             ; If ascii byte < 41, error
            BLT         INVALID_HEX
            CMP.B       #$47,D3             ; If ascii byte < 47, convert to cap
            BLT         GET_CAPITAL
            CMP.B       #$61,D3             ; If ascii byte < 61, error
            BLT         INVALID_HEX
            CMP.B       #$67,D3             ; If ascii byte < 67, convert to lowercase
            BLT         GET_LOWERCASE
            CMP.B       #$66,D3             ; If ascii byte > 66, error
            BGT         INVALID_HEX 
      
NEXT_STEP    
            ADD         #1,D6               ; if  the length of input in d1 is 0, then done
            CMP         #6,D6               ; compare to 6
            BEQ         RETURN              ; if length is 6 digits long, jump to return              
            CMP.B       #$00,(A1)           ; in case its null, done
            BEQ         RETURN              ; move to exit subroutine
            ASL.L       #4,D4               ; shift D4 left by 4 bits for next value            
            JMP         CONVERT_TO_HEX      ; goes back to converting to hex for new val

GET_NUMBER
            SUBI.B      #$30,D3             ; converts val of d2 to hex number val
            ADD.B       D3,D4               ; updates d4 with the latest hex
            JMP         NEXT_STEP           ; goes to loop

GET_CAPITAL
            SUBI.B      #$37,D3             ; converts to capital hex letter
            ADD.B       D3,D4               ; updates the D4 with latest hex
            JMP         NEXT_STEP           ; goes to loop

GET_LOWERCASE
            SUBI.B      #$57,D3             ; converts lowercase hex value
            ADD.B       D3,D4               ; updates d4
            JMP         NEXT_STEP           ; goes to loop

INVALID_HEX 
            MOVE.B      #00,D5              ; Boolean = FALSE      
            JMP         return              ; Exits subroutine

RETURN      MOVE.L      D4,A0               ; Moves the final address to a0
            CLR         D6                  ; Clears counter
            MOVEM.L     (SP)+,D0-D4         ; Load D registers from stack      
            RTS                             ; Return from subroutine

    

*--------------------------------------------------------------------------------------------------------------
*   BUFFER 
*--------------------------------------------------------------------------------------------------------------

BUFFER      
            
endBuff     RTS   


*--------------------------------------------------------------------------------------------------------------
*   Exit and Clear Methods
*--------------------------------------------------------------------------------------------------------------
            
EXIT_PROGRAM            
            MOVE.B      #task1,D0
            LEA         EXIT,A1
            MOVE.W      EXIT_len,D1
            TRAP        #15
            RTS  
            
CLEAR_REG1
            CLR         D0              ; clears all data registers
            CLR         D1
            CLR         D2
            CLR         D3
            CLR         D4
            CLR         D5
            CLR         D6
            CLR         D7
            
            MOVEA.L     #$0, A0
            MOVEA.L     #$0, A1
            MOVEA.L     #$0, A2
            MOVEA.L     #$0, A3
            MOVEA.L     #$0, A4
            MOVEA.L     #$0, A5
            MOVEA.L     #$0, A6            
            RTS
             
CLEAR_REG2  
            CLR.L   D0                  ; Clears all data registers, except boolean (D5)
            CLR.L   D1
            CLR.L   D2
            CLR.L   D3
            CLR.L   D4
            CLR.L   D6
            CLR.L   D7
            RTS     
            
            
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

ERRPARAM    DC.B        'Error: input parameters are invalid.',0
PARAM_len   DC.W        PARAM_len-ERRPARAM

MORE_DATA   DC.B        'Press enter for more data',0
MORE_len    DC.W        MORE_DATA-MORE_len

REPEAT     DC.B        'Would you like to continue disassembling? Y = 1, N = 0: ',0
REPEAT_len  DC.W        REPEAT_len-REPEAT

EXIT        DC.B        'End of program',0
EXIT_len    DC.W        EXIT_len-EXIT  

main_buff   DC.B        1


*--------------------------------------------------------------------------------------------------------------
*   VARIABLES & CONSTANTS
*--------------------------------------------------------------------------------------------------------------

CR          EQU         $0D
LF          EQU         $0A

minBOUND    EQU         $00000000       ; Minimum bound
maxBOUND    EQU         $00FFFFFF       ; Maximum bound

CURRENTADDR DC.L        1               ; holds the address of instruscion

stack       EQU         $A000           ; Stack Address
length      EQU         0               ; Effective address length to be stored in D reg
TRUE        EQU         1               ; Boolean - is true
FALSE       EQU         0               ; Boolean - is false
task0       EQU         00              ; output command
task1       EQU         01              ; output command
task2       EQU         02              ; output command

*-----------------------------------------------------------
*   END OF PROGRAM
*-----------------------------------------------------------        

END         STOP    #$2700
            END     start


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
