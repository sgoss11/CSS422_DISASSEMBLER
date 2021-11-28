*-----------------------------------------------------------
* Title      : CSS422_DISASSEMBLER
* Written by : Data Pirates
* Date       : Autumn 2021
* Description: Scans a section of memory and attempts to
*              convert the memory’s contents to a listing 
*              of valid assembly language instructions
*-----------------------------------------------------------


START   ORG             $1000           ;Start program at $1000
demo_test  INCLUDE    "demo_test.X68"


*-----------------------------------------------------------

*   Starting Prompt

*-----------------------------------------------------------
INTRODUCTION
            LEA         INTRO,A1        ; Program starting message
            MOVE.B      #14,D0
            TRAP        #15
        
*-----------------------------------------------------------

*   INPUT   

*-----------------------------------------------------------
            
            NOP                         ; To prevent instruction overlap
            LEA         INPUT1,A1       ; Prompt user to enter first boundary
            MOVE        #14,D0
            TRAP        #15
            MOVE.L      #2,D0       
            TRAP        #15
            
            JSR         CONVERT_TO_HEX  ; Get first address
            MOVE.B      #14,D0
            TRAP        #15
            MOVE.W      D1,BOUND1       ; Move address to start of memory

            LEA         INPUT2,A1       ; Prompt user to enter second boundary
            MOVE        #14,D0
            TRAP        #15
            MOVE.L      #2,D0       
            TRAP        #15
            
            JSR         CONVERT_TO_HEX  ; Get second address
            MOVE.B      #14,D0
            TRAP        #15
            MOVE.W      D1,BOUND2       ; move address to end of memory
            
CONVERT_TO_HEX
            JSR         CLEAR_REG       ; clears the data registers before starting
            MOVE.B      (A1)+, D2       ; post increment address reg and move each byte to D2
            CMPI.B      #$30, D2        ; if equal to 30 and greater its valid 
            BLT         INVALID_HEX     ; if less than 30, that is error in hex number, branches if less than
            CMPI.B      #$39, D2        ; greater than or equal to 30 and less than or equal to 39 would be numbers (0- 9) 
                           
CLEAR_REG
            CLR D2                      ; clears all data registers 
            CLR D3
            CLR D4
            CLR D6
            CLR D7
            RTS
            
INVALID_HEX 
            *NEED TO BARNCH TO  RESTART THE PROGRAM/ ASK USER TO ENTER NEW VALUE

DONE        SIMHALT                     ; Halt simulator

*-----------------------------------------------------------

*   MESSAGES   

*-----------------------------------------------------------
INTRO       DC.B        '------------------------------------------',CR,LF
            DC.B        CR,LF,'           Program Disassembler',CR,LF,CR,LF
            DC.B        '------------------------------------------',CR,LF,0
            
INPUT1      DC.B        'Please enter start boundary: ',0
INPUT2      DC.B        'Please enter end boundary: ',0

*-----------------------------------------------------------

*   VARIABLES

*-----------------------------------------------------------

CR          EQU         $0D
LF          EQU         $0A

BOUND1      DC.W        $0000           ; Start of memory address
BOUND2      DC.W        $0000           ; End of memory address

            END         START           ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
