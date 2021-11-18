*-----------------------------------------------------------
* Title      : CSS422_DISASSEMBLER
* Written by : Data Pirates
* Date       : Autumn 2021
* Description: Scans a section of memory and attempts to
*              convert the memory’s contents to a listing 
*              of valid assembly language instructions
*-----------------------------------------------------------


START   ORG             $1000         ;Start program at $1000

*-----------------------------------------------------------

*   Starting Prompt

*-----------------------------------------------------------

            LEA         INTRO,A1      ;Program starting message
            MOVE.B      #14,D0
            TRAP        #15
        
*-----------------------------------------------------------

*   INPUT   

*-----------------------------------------------------------
            LEA         FILENAME,A1   ; Open file
            MOVE        #51,D0
            TRAP        #15
            MOVE        D1,DATA
        
            MOVE.L      #FILESIZE,D2
            LEA         BUFFER,A1
            MOVE        #53,D0        ; Trap task #53, read from file
            TRAP        #15      
        
            MOVE        #5,D3         ; Counter
        
READ        TST.B       D3            ; Checks when counter is 0
            BEQ         CLOSE
            SUB.B       #$30,(A1)+
            SUB.B       #1,D3
            BRA         READ
        
        
CLOSE       MOVE        #56,D0        ; Close file
            TRAP        #15
        
DONE        SIMHALT                   ; Halt simulator

*-----------------------------------------------------------

*   MESSAGES   

*-----------------------------------------------------------
INTRO       DC.B        '------------------------------------------',CR,LF
            DC.B        CR,LF,'           Program Disassembler',CR,LF,CR,LF
            DC.B        '------------------------------------------',CR,LF,0

FILENAME    DC.B        'testfile.txt',0
BUFFER      DS.B        100
FILESIZE    DS.B        100

*-----------------------------------------------------------

*   VARIABLES

*-----------------------------------------------------------

CR          EQU         $0D
LF          EQU         $0A
DATA        DS.L        1              ;Variable storage

            END         START          ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
