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
INTRODUCTION
            LEA         INTRO,A1      ;Program starting message
            MOVE.B      #14,D0
            TRAP        #15
        
*-----------------------------------------------------------

*   INPUT   

*-----------------------------------------------------------

            LEA         PROMPT,A1   *Prompt user to ender hex data
            MOVE.W      #14,D0
            TRAP        #15
            MOVE.L      #2,D0       *User Input as string (ASCII)
            TRAP        #15
            MOVE.L      A1,FILENAME  *'testfile.txt',0
            CLR         D0
            
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


* i think we are not allowed to use trap task higher than 15, c        
*-------------------------------------------------------------
*   Conversion to HEX 
*   ASCII VALUE - (30 - 39) is number ranging from (0- 9)
*   ASCII VALUE - (40)
*--------------------------------------------------------------

CONVERT_TO_HEX
            JSR         CLEAR_REG   *clears the data registers before starting
            MOVE.B      (A1)+, D2   * post increment address reg and move each byte to D2
            CMPI.B      #$30, D2    * if equal to 30 and greater its valid 
            BLT         INVALID_HEX * if less than 30, that is error in hex number, branches if less than
            CMPI.B      #$39, D2    * greater than or equal to 30 and less than or equal to 39 would be numbers (0- 9) 
                           
CLEAR_REG
            CLR D2      *clears all data registers 
            CLR D3
            CLR D4
            CLR D6
            CLR D7
            RTS
            
INVALID_HEX 
            *NEED TO BARNCH TO  RESTART THE PROGRAM/ ASKK USER TO ENTER NEW VALUE 
          
DONE        SIMHALT                   ; Halt simulator

*-----------------------------------------------------------

*   MESSAGES   

*-----------------------------------------------------------
INTRO       DC.B        '------------------------------------------',CR,LF
            DC.B        CR,LF,'           Program Disassembler',CR,LF,CR,LF
            DC.B        '------------------------------------------',CR,LF,0
PROMPT      DC.B        'Please enter a file of type .txt : ',0

FILENAME    DS.B        30           *'testfile.txt',0
BUFFER      DS.B        100
FILESIZE    DS.B        100
*   FTYPE       DC.L        #$2E747874      *.txt in hex [ Idea to check 
                                            * file type, .txt, may not be 
                                            * implemented in final though ] 

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


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
