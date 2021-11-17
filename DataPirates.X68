*-----------------------------------------------------------
* Title      : 
* Written by : 
* Date       : 
* Description: 
*-----------------------------------------------------------

CR      EQU         $0D
LF      EQU         $0A
DATA    DS.L        1           *Variable storage


START   ORG         $1000       *Start program at $1000
*-----------------------------------------------------------

*   Starting Prompt

*-----------------------------------------------------------

        LEA         INTRO,A1    *Program starting message
        MOVE.B      #14,D0
        TRAP        #15
        
*-----------------------------------------------------------

*   INPUT   

*-----------------------------------------------------------

        LEA         PROMPT,A1   *Prompt user to ender hex data
        MOVE.W      #14,D0
        TRAP        #15
        
        
*-----------------------------------------------------------

*   MESSAGES   

*-----------------------------------------------------------
INTRO   DC.B    'Disassembler',0  

        END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
