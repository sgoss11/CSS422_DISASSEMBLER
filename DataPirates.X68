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
        LEA         FILENAME,A1 *Open file
        MOVE        #51,D0
        TRAP        #15
        
        LEA         BUFFER,A1   *Read file
        MOVE        #53,D0
        TRAP        #15
        
        MOVE.L      #filesize,D2
        
        MOVE.B      #56,D0       *Close file
        TRAP         #15
        
*-----------------------------------------------------------

*   MESSAGES   

*-----------------------------------------------------------
INTRO   DC.B    '------------------------------------------',CR,LF
        DC.B    CR,LF,'           Program Disassembler',CR,LF,CR,LF
        DC.B    '------------------------------------------',CR,LF,0
        
FILENAME DC.B   'testfile.txt',0
BUFFER   DS.B   100
FILESIZE DS.B   100

        END    START        ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
