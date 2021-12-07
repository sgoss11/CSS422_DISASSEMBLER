*-----------------------------------------------------------
* Title      : CSS422_DISASSEMBLER
* Written by : Data Pirates
* Date       : Autumn 2021
* Description: Scans a section of memory and attempts to
*              convert the memory’s contents to a listing 
*              of valid assembly language instructions
*-----------------------------------------------------------


*-------------------------------------------------------------------------------------------------------------------------------------------------------------------
*=================================================================I/O_ROUTINES======================================================================================
*-------------------------------------------------------------------------------------------------------------------------------------------------------------------

START       ORG         $1000               ; Start program at $1000

*--------------------------------------------------------------------------------------------------------------
*   START OF PROGRAM
*--------------------------------------------------------------------------------------------------------------
            
INTRODUCTION
            MOVE.B      #14,D0              ; Program starting message
            LEA         INTRO,A1
            TRAP        #15      
            
MAIN_START  
            BSR         CLEAR_REG1          ; Clear all data registers    
            LEA         stack,SP            ; Load stack pointer  
            LEA         main_buff,A2        ; Load buffer in A2
            MOVEA.L     A2,A6               ; Reference start of main buffer
            
            
*--------------------------------------------------------------------------------------------------------------
*   USER INPUT: User inputs upper and lower bound for dissasembler, from
*               there it will be added to a stack and checked if address 
*               is valid and will execute               
*
*   Registers used:
*       - A0: starting address (INPUT1)
*       - A4: ending address (INPUT2)
*       - D2: copy of address
*       - D3: helper register
*       - D5: boolean
*--------------------------------------------------------------------------------------------------------------
    
GET_INPUT    
            MOVE        #01,D0              ; Display string at A1
            LEA         INPUT1,A1           ; Prompt user to enter start boundary
            MOVE.W      INPUT1_len,D1         
            TRAP        #15
            ADDA        #INPUT1_len,A1      ; Adds user input after prompt
            MOVE        #02,D0              ; Read string from keyboard and store at A1      
            TRAP        #15
            JSR         ASCII_TO_HEX        ; Save info to stack, checks if valid
            CMP.B       #$00,D5             ; Check if boolean is false
            
            MOVEA.L     A0,A4         
            MOVE.B      #01,D0              ; Display string at A1
            LEA         INPUT2,A1           ; Prompt user to enter end boundary
            MOVE.W      INPUT2_len,D1         
            TRAP        #15         
            ADDA.L      #INPUT2_len,A1      ; Add user input after prompt
            MOVE.B      #02,D0              ; Read string from keyboard and store at A1
            TRAP        #15
            JSR         ASCII_TO_HEX        ; Save info to stack, checks if valid
            CMP.B       #$00,D5             ; Check if boolean is false
            
            MOVEA.L     A4,A3               ; Stores starting address into A3
            MOVEA.L     A0,A4               ; Stores endinging address into A4
            MOVEA.L     A3,A0               ; Stores starting address into A0 to be swapped                   
            
            BSR         CHECK_ADDRESS       ; Check if address is valid           
            CMP         #FALSE,D5           ; If not valid, Bool = False
            BEQ         GET_INPUT           ; Return to input prompts
            
            BSR         BUFFER              ; To fill buffer with current address
            
            MOVE.B      #01,D0
            LEA         REPEAT,A1           ; Asks if user wants to enter new boundaries
            MOVE.W      REPEAT_len,D1
            TRAP        #15
            
            MOVE.B      #02,D0              ; Read string from keyboard and store at A1
            TRAP        #15
            
            MOVE.B      (A1),D3             ; Copies user input to D3
            
            MOVE.B      #$57,(A1)+          ; Write in 'W'
            MOVE.B      #$6F,(A1)           ; Write in 'u'
            
            CMP.B       #$31,D3             ; Compares ASCII values to D3
            BEQ         MAIN_START
             
            BEQ         MAIN_START          ; Restart input prompts
            
            BSR         EXIT_PROGRAM        ; Exit program                  
            JMP         END        
        
        
*--------------------------------------------------------------------------------------------------------------
*   CHECK ADDRESS VALIDITY: Checks if address is even, is within boundaries, and if
*                           the starting address isn't greater than the ending
*   
*   Registers used:
*       - A0: starting address (INPUT1)
*       - A4: ending address (INPUT2)
*       - D2: copy of address
*       - D3: helper register
*       - D5: boolean
*--------------------------------------------------------------------------------------------------------------
               
CHECK_ADDRESS:

CHECK_START
            CMP.B       #$00,D5             ; Check if boolean is false
            BEQ         CHECK_ERROR         ; Address error
            MOVE.B      #TRUE,D5            ; Set boolean to true

ADD1        MOVE.L      A0,D2               ; Loads start boundary to D regs
            MOVE.L      D2,D3
            ANDI.B      #1,D3               ; Checks last bit in D2
            CMP.B       #1,D3
            BNE         ADD2                ; Last bit = 0; go to even branch
            
SUB1        SUBI.B      #$1,D2              ; Allows odd address to be even
            MOVE.L      D2,A0    
            
ADD2        MOVE.L      A4,D2               ; Loads ending boundary to D regs
            MOVE.L      D2,D3
            ANDI.B      #1,D3               ; Checks last bit in D2
            CMP.B       #1,D3
            BNE         EQU1 
            
SUB2        SUBI.B      #$1,D2              ; Allows odd address to be even
            MOVE.L      D2,A4
              
EQU1        CMP.L       #maxBOUND,A0        ; Checks if starting address < $00FFFFFF
            BLT         EQU2                ; If so, branch to EQU2        
            JMP         CHECK_ERROR         ; If not, address error
                
EQU2        CMP.L       #maxBOUND,A4        ; checks if ending address <= $00FFFFFF
            BLE         EQU3                ; If so, branch to EQU3
            JMP         CHECK_ERROR         ; If not, address error               
            
EQU3        CMPA.L      A0,A4               ; Checks if ending address > starting address
            BGT         CHECK_END
               
CHECK_ERROR
            MOVE.B      #00,D0
            LEA         ERRPARAM,A1         ; Display invalid parameter msg
            MOVE.W      PARAM_len,D1
            TRAP        #15        
            MOVE.B      #FALSE,D5           ; Bool = False
                        
CHECK_END   RTS


*--------------------------------------------------------------------------------------------------------------
*   Ascii To Hex: Add data to stack, converts to hex, and checks length of address
*   
*   Registers used:
*       - D3: placeholder for current ascii byte   
*       - D4: translated address
*       - D5: boolean
*       - A0: stores the converted address
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
            ADD.B       D3,D4               ; updates D4
            JMP         NEXT_STEP           ; goes to loop

INVALID_HEX 
            MOVE.B      #00,D5              ; Checks if bool is FALSE      
            JMP         return              ; Exits subroutine

RETURN      MOVE.L      D4,A0               ; Moves the final address to A0
            CLR         D6                  ; Clears counter
            MOVEM.L     (SP)+,D0-D4         ; Load D registers from stack      
            RTS                             ; Return from subroutine
               
               
*--------------------------------------------------------------------------------------------------------------
*   BUFFER: gets buffer ready for current address, OpCode, and EA
*
*   Registers used:   
*       - A0: current address
*       - A1: trap address
*       - A2: buffer pointer
*       - A4: ending address
*       - D0: task number
*       - D1: length for MORE_DATA
*       - D7: counter for number of lines printed
*--------------------------------------------------------------------------------------------------------------

BUFFER      MOVEA.L     A6,A2         
            MOVEA.L     A2,A1               ; Loads trap address with A2            
            JSR         FORMAT_ADD          ; Print out address lines
            MOVE.B      #$09,(A2)+          ; Fills buffer with current address
            JSR         DECODE_OP
            MOVE.B      #00,(A2)            ; Null terminater
            MOVE.B      #13,D0
            TRAP        #15                 ; Print decoded op
                              
            CMPA.L      A0,A4               ; Continues to end of address range
            BLE         END_BUFFER
            
            ADDI        #1,D7               ; Increments a counter
            CMP         #lineCount,D7       ; Checks how many lines to increment
            BNE         BUFFER
            
            MOVE.B      #01,D0              ; Display string at A1
            LEA         MORE_DATA,A1        ; Asks user to press enter for more data
            MOVE.W      MORE_len,D1
            TRAP        #15
            
            MOVE.B      #02,D0              ; Read string from keyboard and store at A1
            TRAP        #15
            
            MOVE.B      #$50,(A1)
            
            CLR         D7                  ; Resets the counter
            JMP         BUFFER
            
END_BUFFER  RTS     


*--------------------------------------------------------------------------------------------------------------
*   Exit Method
*--------------------------------------------------------------------------------------------------------------

EXIT_PROGRAM            
            MOVE.B      #01,D0              ; Display string at A1
            LEA         EXIT,A1
            MOVE.W      EXIT_len,D1
            TRAP        #15
            RTS   


*-------------------------------------------------------------------------------------------------------------------------------------------------------------------
*==============================================================OPCODE_ROUTINES======================================================================================
*-------------------------------------------------------------------------------------------------------------------------------------------------------------------

*--------------------------------------------------------------------------------------------------------------
*   START OF DECODE
*
*   Registers used:   
*       - A0/A5: Memory pointer
*       - A2: buffer pointer
*       - A5: index for jump tables
*       - A6: holds previous buffer spot
*       - A7: SP
*       - D2: size returned from GET_SIZE
*       - D5: boolean
*       - D6: copy of D7 to shift
*       - D7: current word value
*       - (A1, D0, D1: trap funtions)
*--------------------------------------------------------------------------------------------------------------
          
DECODE_OP   MOVEM.L     A4-A6/D0-D4/D6-D7,-(SP)      ; Registers to be saved using MOVEM
            JSR         CLEAR_REG2                   ; Registers are cleared to be used
            MOVE.B      #TRUE,D5                     ; Bool = TRUE
            MOVE.W      (A0)+,D7            ; Move instructions to D7 and increment pointer
            MOVEA.L     A2,A3               ; Stores buffer location                 
            JSR         GET_OP              ; Decode instruction to get opcode

INVALID_OP 
            MOVE.B      #00,D5              ; Checks if bool is FALSE      
            JMP         RETURN_OP           ; Exits subroutine

RETURN_OP   MOVEM.L     (SP)+,D6-D7/D0-D4/A4-A6      ; Clean and restore registers
            RTS                    
                 
GET_OP      MOVE.W      D7,D6               ; Move instruction to shift
            MOVE.B      #12,D4              ; Load shift register for 12 bits
            LSR.W       D4,D6               ; Shift register 12 bits right
            MULU        #6,D6               ; Forms offset           
            LEA         OP_TABLE,A5         ; Access table                                                                                   
            JSR         00(A5,D6)           ; Jump indirect with index (00 indicates word movement)
            RTS


*--------------------------------------------------------------------------------------------------------------
*   MAIN OPCODE TABLE (first 4 bits)
*--------------------------------------------------------------------------------------------------------------

OP_TABLE      
            JMP         GROUP1_0000            
            JMP         GROUP1_0001            
            JMP         GROUP1_0010
            JMP         GROUP1_0011
            JMP         GROUP1_0100
            JMP         GROUP1_0101
            JMP         GROUP1_0110
            JMP         GROUP1_0111
            JMP         GROUP1_1000
            JMP         GROUP1_1001
            JMP         GROUP1_1010
            JMP         GROUP1_1011
            JMP         GROUP1_1100
            JMP         GROUP1_1101
            JMP         GROUP1_1110
            JMP         GROUP1_1111
            

*--------------------------------------------------------------------------------------------------------------
*   OPCODE: 0000 (ORI, ANDI, SUBI, ADDI, EORI, CMP)
*--------------------------------------------------------------------------------------------------------------

GROUP1_0000 
            MOVE.W      D7,D6               ; Copy of instruction to shift
            ANDI.W      #$0F00,D6           ; Gets second last bit of address
            MOVE.B      #08,D4              ; Assigns D4 with 8 bits to shift
            LSR.L       D4,D6               ; Shift D6 by 8 bits
            CMP.B       #$0,D6              ; Is instruction ORI?
            BEQ         OP_ORI              ; Puts ORI into buffer
            CMP.B       #$2,D6              ; Is instruction ANDI?
            BEQ         OP_ANDI             ; Puts ANDI into buffer
            CMP.B       #$4,D6              ; Is instruction SUBI?
            BEQ         OP_SUBI             ; Puts SUBI into buffer
            CMP.B       #$6,D6              ; Is instruction ADDI?
            BEQ         OP_ADDI             ; Puts ADDI into buffer
            CMP.B       #$A,D6              ; Is instruction EORI?
            BEQ         OP_EORI             ; Puts opEORI into buffer
            CMP.B       #$C,D6              ; Is instruction CMPI?
            BNE         INVALID_INST        ; If not one of these instructions, return DATA                 

OP_CMPI     MOVE.B      #'C',(A2)+          ; Put CMPI into buffer
            MOVE.B      #'M',(A2)+
            MOVE.B      #'P',(A2)+
            MOVE.B      #'I',(A2)+
            MOVE.B      #'.',(A2)+
            JSR         FIND_SIZE           ; Decides whether B,W,L
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+            
            MOVE.B      #'#',(A2)+
            JSR         LOAD_SIZE           ; Load size amount into buffer
            MOVE.B      #',',(A2)+          ; Adds comma between data
            JSR         GET_EA              ; Prints desitination operand
            JMP         END0000             ; Jumps to end of subroute GROUP1_0000
                        
OP_ORI      MOVE.B      #'O',(A2)+          ; Put ORI into buffer
            MOVE.B      #'R',(A2)+
            MOVE.B      #'I',(A2)+
            MOVE.B      #'.',(A2)+
            JSR         FIND_SIZE           ; Decides whether B,W,L
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+            
            MOVE.B      #'#',(A2)+            
            JSR         LOAD_SIZE           ; Load size amount into buffer
            MOVE.B      #',',(A2)+          ; Adds comma between data
            JSR         GET_EA              ; Prints desitination operand
            JMP         END0000             ; Jumps to end of subroute GROUP1_0000

OP_ANDI     MOVE.B      #'A',(A2)+          ; Put ANDI into buffer
            MOVE.B      #'N',(A2)+
            MOVE.B      #'D',(A2)+
            MOVE.B      #'I',(A2)+
            MOVE.B      #'.',(A2)+
            JSR         FIND_SIZE           ; Decides whether B,W,L
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+            
            MOVE.B      #'#',(A2)+           
            JSR         LOAD_SIZE           ; Load size amount into buffer            
            MOVE.B      #',',(A2)+          ; Adds comma between data
            JSR         GET_EA              ; Prints desitination operand
            JMP         END0000             ; Jumps to end of subroute GROUP1_0000
            
OP_SUBI     MOVE.B      #'S',(A2)+          ; Put SUBI into buffer
            MOVE.B      #'U',(A2)+
            MOVE.B      #'B',(A2)+
            MOVE.B      #'I',(A2)+
            MOVE.B      #'.',(A2)+
            JSR         FIND_SIZE           ; Decides whether B,W,L
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+            
            MOVE.B      #'#',(A2)+
            
            JSR         LOAD_SIZE           ; Load size amount into buffer
            MOVE.B      #',',(A2)+          ; Adds comma between data
            JSR         GET_EA              ; Prints desitination operand
            JMP         END0000             ; Jumps to end of subroute GROUP1_0000
            
OP_ADDI     MOVE.B      #'A',(A2)+          ; Put ADDI into buffer
            MOVE.B      #'D',(A2)+
            MOVE.B      #'D',(A2)+
            MOVE.B      #'I',(A2)+
            MOVE.B      #'.',(A2)+
            JSR         FIND_SIZE           ; Decides whether B,W,L
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+            
            MOVE.B      #'#',(A2)+
            JSR         LOAD_SIZE           ; Load size amount into buffer
            MOVE.B      #',',(A2)+          ; Adds comma between data
            JSR         GET_EA              ; Prints desitination operand
            JMP         END0000             ; Jumps to end of subroute GROUP1_0000

OP_EORI     MOVE.B      #'E',(A2)+          ; Put EORI into buffer
            MOVE.B      #'O',(A2)+
            MOVE.B      #'R',(A2)+
            MOVE.B      #'I',(A2)+
            MOVE.B      #'.',(A2)+
            JSR         FIND_SIZE           ; Decides whether B,W,L
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+            
            MOVE.B      #'#',(A2)+
            JSR         LOAD_SIZE           ; Load size amount into buffer
            MOVE.B      #',',(A2)+          ; Adds comma between data
            JSR         GET_EA              ; Prints desitination operand
            JMP         END0000             ; Jumps to end of subroute GROUP1_0000
            
END0000     RTS


*--------------------------------------------------------------------------------------------------------------
*   OPCODE: 0001 (MOVE.B)
*--------------------------------------------------------------------------------------------------------------

GROUP1_0001 
            MOVE.B      #'M',(A2)+          ; Puts MOVE.B into buffer
            MOVE.B      #'O',(A2)+
            MOVE.B      #'V',(A2)+
            MOVE.B      #'E',(A2)+
            MOVE.B      #'.',(A2)+
            MOVE.B      #'B',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+  
            JSR         GET_EA              ; Prints desitination operand
            MOVE.B      #',',(A2)+          ; Adds comma between data
            JSR         MOVE_SWAP           ; Swap the destination and source regs for GET_EA
            JSR         GET_EA
            
END0001     RTS 
            
            
*--------------------------------------------------------------------------------------------------------------
*   OPCODE: 0010 (MOVE.L, MOVEA.L)
*--------------------------------------------------------------------------------------------------------------

GROUP1_0010 
            MOVE.B      #'M',(A2)+          ; Puts MOVE/A sized L into buffer
            MOVE.B      #'O',(A2)+
            MOVE.B      #'V',(A2)+
            MOVE.B      #'E',(A2)+
            MOVE.B      D7,D6               ; Copies instruction to shift
            LSR.L       #6,D6               ; Shift by 6 bits
            ANDI.W      #$07,D6
            CMP.B       #$1,D6              ; Is instruction MOVEA?
            BNE         MOVEL               ; If not, it is MOVE
            MOVE.B      #'A',(A2)+          ; Adds A to make MOVEA
            MOVE.B      #'.',(A2)+
            MOVE.B      #'L',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            JMP         GET_EA              ; Continue making source destination
MOVEL       MOVE.B      #'.',(A2)+
            MOVE.B      #'L',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+  
MOVEL_EA    JSR         GET_EA              ; Prints desitination operand
            MOVE.B      #',',(A2)+          ; Adds comma between data
            JSR         MOVE_SWAP           ; Swap the destination and source regs for GET_EA
            JSR         GET_EA     
END0010     RTS
 
 
*--------------------------------------------------------------------------------------------------------------
*   OPCODE: 0011 (MOVE.W, MOVEA.W)
*-------------------------------------------------------------------------------------------------------------- 

GROUP1_0011 
            MOVE.B      #'M',(A2)+          ; Puts MOVE/A.W into buffer
            MOVE.B      #'O',(A2)+
            MOVE.B      #'V',(A2)+
            MOVE.B      #'E',(A2)+
            MOVE.B      D7,D6               ; Copies instruction to shift
            LSR.L       #6,D6               ; Shift by 6 bits
            ANDI.W      #$07,D6             
            CMP.B       #$1,D6              ; Is instruction MOVEA?
            BNE         MOVEW               ; If not, it is MOVE
            MOVE.B      #'A',(A2)+          ; Adds A to make MOVEA
            MOVE.B      #'.',(A2)+
            MOVE.B      #'W',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            JMP         MOVEWEA             ; Continue making source destination
MOVEW       MOVE.B      #'.',(A2)+
            MOVE.B      #'W',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+  
MOVEWEA     JSR         GET_EA              ; Prints desitination operand
            MOVE.B      #',',(A2)+          ; Adds comma between data
            JSR         MOVE_SWAP           ; Swap the destination and source regs for GET_EA 

            JSR         GET_EA     
END0011     RTS 


*--------------------------------------------------------------------------------------------------------------
*   OPCODE: 0100 (CLR, NEG, NOT, MOVEM, SWAP, JMP, JSR, NOP, RTS, LEA) *Continues to OP_TABLE4*
*--------------------------------------------------------------------------------------------------------------

GROUP1_0100 
            MOVE.W      D7,D6               ; Copies instruction to shift
            ANDI.W      #$0100,D6           ; Gets eighth bit of address
            CMP.W       #$0100,D6           ; Is instruction LEA?
            BEQ         OP_LEA              ; If yes, continue for LEA
            MOVE.W      D7,D6               ; Copies instruction to shift
            MOVE.B      #08,D4              ; Assigns 8 bits to shift register
            LSR.W       D4,D6               ; Shift instruction 8 bits left
            ANDI.W      #$000F,D6           ; Gets last 4 bits of address
            MULU        #6,D6               ; Forms offset for next JMP table
            LEA         OP_TABLE4,A5        ; Loads next JMP table 
            JSR         00(A5,D6)           ; Jumps to next instruction per next 4 bits
            JMP         END0100             ; Skip to end once back from table
            
OP_LEA      MOVE.B      #'L',(A2)+          ; Puts LEA into buffer
            MOVE.B      #'E',(A2)+
            MOVE.B      #'A',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #$09,(A2)+ 
            JSR         GET_EA              ; Determines address to go to buffer
            MOVE.B      #',',(A2)+          ; Adds comma between data
            MOVE.B      #'A',(A2)+          ; Adds A for address
            MOVE.W      D7,D6               ; Copies instruction to shift
            MOVE.B      #9,D4               ; Assigns 9 bits to shift register
            LSR.W       D4,D6               ; Shift instruction 9 bits left
            ANDI.W      #$000F,D6           ; Gets last 4 bits of address
            ADD.B       #$30,D6             ; convert D register # to hex
            MOVE.B      D6,(A2)+            ; register # goes into buffer
END0100     RTS

GROUP1_0101 
            JSR         INVALID_INST        ; Instruction becomes placeholder
            RTS
            
GROUP1_0110 
            JSR         INVALID_INST        ; For MOVEM
            ADDQ.W      #2,A0
            RTS

GROUP1_0111 
            JSR         INVALID_INST        ; Instruction becomes placeholder
            RTS
            
            
*--------------------------------------------------------------------------------------------------------------
*   OPCODE: 1000 (OR)
*-------------------------------------------------------------------------------------------------------------- 
 
GROUP1_1000 
            MOVE.W      D7,D6               ; Copies DIV instruction to shift
            LSR.L       #6,D6               ; Shift instruction 6 bits left
            ANDI.W      #$03,D6             ; Mask last 2 bits
            CMP.B       #$3,D6              ; Is this instruction invalid?
            BNE         OP_OR               ; If not, continue for OR
            JMP         INVALID_INST            

OP_OR       MOVE.B      #'O',(A2)+          ; Puts OR into buffer
            MOVE.B      #'R',(A2)+
            MOVE.B      #'.',(A2)+            
            JSR         FIND_SIZE           ; Decides whether B,W,L
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            JSR         DIR_BIT             ; get Direction Bit 0 = EA 1 = regs
            CMP.B       #%0,D6              ; Is this EA first?
            BNE         OP_OR01             ; If not, go to register mode first
            JSR         GET_EA              ; Print effective address
            MOVE.B      #',',(A2)+          ; Adds comma between data
            MOVE.B      #'D',(A2)+          ; Adds D for data register
            JSR         HIGH_ADD            ; Add register number to buffer
            JMP         END1000             ; Exit subroute 1000
            
OP_OR01     MOVE.B      #'D',(A2)+          ; Adds D for data register
            JSR         HIGH_ADD            ; Add register number to buffer
            MOVE.B      #',',(A2)+          ; Adds comma between data
            JSR         GET_EA              ; Insert EA        

END1000     RTS


*--------------------------------------------------------------------------------------------------------------
*   OPCODE: 1001 (SUB, SUBA)
*-------------------------------------------------------------------------------------------------------------- 

GROUP1_1001 
            MOVE.B      #'S',(A2)+          ; Puts SUB into buffer
            MOVE.B      #'U',(A2)+
            MOVE.B      #'B',(A2)+
            JSR         GET_SIZE            ; Gets size data and puts into D6
            CMP.B       #%11,D6             ; Is instruction SUBA?
            BNE         OP_SUBA             ; If not, it is SUB
            MOVE.B      #'A',(A2)+          ; Adds A to make SUBA
            MOVE.B      #'.',(A2)+
            MOVE.W      D7,D6               ; Copies instruction to shift
            LSR.L       #08,D6              ; Shift instruction 6 bits left
            ANDI.W      #$0001,D6           ; Gets size bit
            CMP.B       #%1,D6              ; Compare to determine size
            BEQ         SUBAL               ; Goes to SUBAL if long
            MOVE.B      #'W',(A2)+          ; Becomes word and enters buffer
            JMP         OP_SUBA
SUBAL       MOVE.B      #'L',(A2)+          ; Adds long to buffer           
OP_SUBA     MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+

            JSR         GET_EA              ; Gets source operand
            MOVE.B      #',',(A2)+          ; Adds comma between data
            MOVE.B      #'A',(A2)+          ; Adds A for address
            JSR         HIGH_ADD            ; Add register number to buffer
            JMP         END1101
            
OP_SUB      MOVE.B      #'.',(A2)+
            JSR         FIND_SIZE           ; Decides whether B,W,L
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            JSR         DIR_BIT             ; Get Direction Bit 0 = EA 1 = regs
            CMP.B       #%0,D6              ; Is this EA first?
            BNE         OP_SUB01            ; If not, go to register mode first
            JSR         GET_EA              ; Print effective address
            MOVE.B      #',',(A2)+          ; Adds comma between data
            MOVE.B      #'D',(A2)+          ; Adds D for data register
            JSR         HIGH_ADD            ; Add register number to buffer
            JMP         END1001             ; Exit subroute 1001
            
OP_SUB01    MOVE.B      #'D',(A2)+          ; Adds D for data register
            JSR         HIGH_ADD            ; Add register number to buffer
            MOVE.B      #',',(A2)+          ; Adds comma between data
            JSR         GET_EA              ; Insert EA          
            
END1001     RTS            

GROUP1_1010 
            JSR         INVALID_INST        ; Instruction  is invalid
            RTS


*--------------------------------------------------------------------------------------------------------------
*   OPCODE: 1011 (CMP, CMPA, EOR)
*-------------------------------------------------------------------------------------------------------------- 

GROUP1_1011 
            JSR         GET_SIZE            ; Gets size data and puts into D6
            CMP.B       #%11,D6             ; Is instruction CMPA?
            BNE         OP_CMPEOR           ; If not, it is EOR
            MOVE.B      #'C',(A2)+          ; Puts CMPA into buffer
            MOVE.B      #'M',(A2)+
            MOVE.B      #'P',(A2)+
            MOVE.B      #'A',(A2)+
            MOVE.B      #'.',(A2)+
            MOVE.W      D7,D6               ; Copies instruction to shift
            LSR.L       #08,D6              ; Gets eighth bit of address
            ANDI.W      #$0001,D6           ; Gets size bit
            CMP.B       #%1,D6              ; Compare to determine size
            BEQ         CMPAL               ; Goes to CMPAL if long
            MOVE.B      #'W',(A2)+          ; Becomes word and enters buffer
            JMP         OP_CMPA
CMPAL       MOVE.B      #'L',(A2)+          ; Adds long to buffer           
OP_CMPA     MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+          
            MOVE.B      #' ',(A2)+

            JSR         GET_EA              ; Gets source operand
            MOVE.B      #',',(A2)+          ; Adds comma between data
            MOVE.B      #'A',(A2)+          ; Adds A for address
            JSR         HIGH_ADD            ; Add register number to buffer
            JMP         END1011
            
OP_CMPEOR   MOVE.W      D7,D6               ; Get new instruction
            JSR         DIR_BIT             ; Get Direction Bit 1 = eor 0 = cmp
            CMP.B       #%0,D6              ; Is this EA first?
            BNE         OP_EOR              ; If not, go to register mode first            
                   
OP_CMP      MOVE.B      #'C',(A2)+          ; Puts CMP into buffer
            MOVE.B      #'M',(A2)+
            MOVE.B      #'P',(A2)+
            MOVE.B      #'.',(A2)+
            JSR         FIND_SIZE           ; Decides whether B,W,L
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            JSR         GET_EA              ; Gets source operand
            MOVE.B      #',',(A2)+          ; Adds comma between data
            MOVE.B      #'D',(A2)+          ; Adds D for data register
            JSR         HIGH_ADD            ; Add register number to buffer
            JMP         END1011             ; Exit subroute 1011
      
                        
OP_EOR      MOVE.B      #'E',(A2)+          ; Puts EOR into buffer
            MOVE.B      #'O',(A2)+
            MOVE.B      #'R',(A2)+
            MOVE.B      #'.',(A2)+
            JSR         FIND_SIZE           ; Decides whether B,W,L
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #'D',(A2)+          ; Adds D for data register
            JSR         HIGH_ADD            ; Add register number to buffer            
            MOVE.B      #',',(A2)+          ; Adds comma between data
            JSR         GET_EA              ; Insert EA     
                             
END1011     RTS


*--------------------------------------------------------------------------------------------------------------
*   OPCODE: 1100 (EXG, AND)
*-------------------------------------------------------------------------------------------------------------- 

GROUP1_1100 
            MOVE.W      D7,D6               ; Copies instruction to shift
OP_MULU     LSR.L       #6,D6               ; Shift instruction 6 bits left
            ANDI.W      #$3,D6              ; Mask last 3 bits
            CMP.B       #$3,D6              ; Is instruction MULU or MULS?
            BEQ         MULU_MODE           ; If yes, continue for MULU to determine immediate   
            JMP         OP_ANDEXG           ; If no, go to OP_ANDEXG
MULU_MODE   MOVE.W      D7,D6               ; Get new instruction
            LSR.L       #3,D6               ; Shift instruction 3 bits left
            ANDI.W      #$7,D6              ; Mask last mode bits
            CMP.B       #$7,D6
            BEQ         MOVE_PTR            ; Have pointer go by word
            JMP         INVALID_INST        ; Invalid instruction

MOVE_PTR    ADDQ.W      #2,A0               ; Increment pointer
            JMP         INVALID_INST        ; Invalid instruction
        
OP_ANDEXG   MOVE.W      D7,D6               ; Copies EXG and AND instruction to shift         
            LSR.L       #3,D6               ; Shift instruction 3 bits left
            ANDI.B      #$1F,D6             ; Mask last 5 bits
            CMP.B       #$08,D6             ; Is instruction EXG D to D?
            BEQ         OP_EXGd2d           ; If yes, go to OP_EXGd2d
            CMP.B       #$09,D6             ; Is instruction EXG A to A?
            BEQ         OP_EXGa2a           ; If yes, go to OP_EXGa2a
            CMP.B       #$11,D6             ; Is instruction EXG D to A?
            BEQ         OP_EXGd2a           ; If yes, go to OP_EXGd2a
            
            
OP_AND      MOVE.B      #'A',(A2)+          ; Puts AND into buffer
            MOVE.B      #'N',(A2)+
            MOVE.B      #'D',(A2)+
            MOVE.B      #'.',(A2)+            
            JSR         FIND_SIZE           ; Decides whether B,W,L
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            JSR         DIR_BIT             ; Get Direction Bit 0 = EA 1 =regs
            CMP.B       #%0,D6              ; Is this EA first?
            BNE         OP_AND01            ; If not, go to register mode first
            JSR         GET_EA              ; Print EA
            MOVE.B      #',',(A2)+          ; Adds comma between data
            MOVE.B      #'D',(A2)+          ; Adds D for data register
            JSR         HIGH_ADD            ; Add register number to buffer
            JMP         END1100             ; Exit subroute 1100
            
OP_AND01    MOVE.B      #'D',(A2)+          ; Adds D for data register
            JSR         HIGH_ADD            ; Add register number to buffer
            MOVE.B      #',',(A2)+          ; Adds comma between data
            JSR         GET_EA              ; Insert EA                   
            JMP         END1100

OP_EXGd2d   MOVE.B      #'E',(A2)+          ; Puts EXG D to D into buffer
            MOVE.B      #'X',(A2)+           
            MOVE.B      #'G',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #'D',(A2)+          ; Put D reg, then D reg
            JSR         HIGH_ADD            ; Add register number to buffer
            MOVE.B      #',',(A2)+          ; Adds comma between data
            JSR         GET_EA              ; Get Destination register
            JMP         END1100             ; Exit subroute 1011
                        
OP_EXGa2a   MOVE.B      #'E',(A2)+          ; Puts EXG A to A into buffer
            MOVE.B      #'X',(A2)+           
            MOVE.B      #'G',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #'A',(A2)+          ; Put A reg, then A reg
            JSR         HIGH_ADD            ; Add register number to buffer
            MOVE.B      #',',(A2)+          ; Adds comma between data
            JSR         GET_EA              ; Get Destination register
            JMP         END1100             ; Exit subroute 1011
            
OP_EXGd2a   MOVE.B      #'E',(A2)+          ; Puts EXG D to A into buffer
            MOVE.B      #'X',(A2)+           
            MOVE.B      #'G',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #'D',(A2)+          ; Put D reg, then A reg
            JSR         HIGH_ADD            ; Add register number to buffer
            MOVE.B      #',',(A2)+          ; Adds comma between data
            JSR         GET_EA              ; Get Destination register
            JMP         END1100             ; Exit subroute 1011

END1100     RTS


*--------------------------------------------------------------------------------------------------------------
*   OPCODE: 1101 (ADD,ADDA)
*-------------------------------------------------------------------------------------------------------------- 

GROUP1_1101 
            MOVE.B      #'A',(A2)+          ; Puts ADD into buffer
            MOVE.B      #'D',(A2)+
            MOVE.B      #'D',(A2)+
            JSR         GET_SIZE            ; Gets size data and puts into D6
            CMP.B       #%11,D6             ; Is instruction ADDA?
            BNE         OP_ADD              ; If not, it is ADD
            MOVE.B      #'A',(A2)+          ; Adds A to make ADDA
            MOVE.B      #'.',(A2)+
            MOVE.W      D7,D6               ; Get new instruction
            LSR.L       #08,D6              ; Gets eighth bit of address
            ANDI.W      #$0001,D6           ; Gets size bit
            CMP.B       #%1,D6              ; Compare to determine size
            BEQ         ADDAL               ; Goes to ADDAL if long
            MOVE.B      #'W',(A2)+          ; Becomes word and enters buffer
            JMP         OP_ADDA
ADDAL       MOVE.B      #'L',(A2)+          ; Adds long to buffer          
OP_ADDA     MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            
            JSR         GET_EA              ; Gets source operand
            MOVE.B      #',',(A2)+          ; Adds comma between data
            MOVE.B      #'A',(A2)+          ; Adds A for address register
            JSR         HIGH_ADD            ; Add register number to buffer
            JMP         END1101
            
OP_ADD      MOVE.B      #'.',(A2)+
            JSR         FIND_SIZE           ; Decides whether B,W,L
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            JSR         DIR_BIT             ; Get Direction Bit 0 = EA 1 =regs
            CMP.B       #%0,D6              ; Is this EA first?
            BNE         OP_ADD01            ; If not, go to register mode first
            JSR         GET_EA              ; Print EA
            MOVE.B      #',',(A2)+          ; Adds comma between data
            MOVE.B      #'D',(A2)+          ; Adds D for data register
            JSR         HIGH_ADD            ; Add register number to buffer
            JMP         END1101             ; Exit subroute 1101
            
OP_ADD01    MOVE.B      #'D',(A2)+          ; Adds D for data register
            JSR         HIGH_ADD            ; Add register number to buffer
            MOVE.B      #',',(A2)+          ; Adds comma between data
            JSR         GET_EA              ; Get Destination register

END1101     RTS


*--------------------------------------------------------------------------------------------------------------
*   OPCODE: 1110 (ASd, LSd, ROd)
*-------------------------------------------------------------------------------------------------------------- 

GROUP1_1110 
            JSR         GET_SIZE            ; Gets size data and puts into D6
            CMP.B       #%11,D6             ; Is instruction ASd, LSd, ROd?
            BEQ         OP_ShMem
OP_SHIFT    MOVE.W      D7,D6               ; Copies instruction to shift
            LSR.B       #3,D6               ; Shift instruction 3 bits left
            ANDI.B      #$03,D6             ; Mask bits
            CMP.B       #%00,D6             ; Is instruction AS(d)?
            BEQ         OP_ASd              ; If yes, go to AS
            CMP.B       #%01,D6             ; Is instruction LS(d)?
            BEQ         OP_LSd              ; If yes, go to LS
            CMP.B       #%11,D6             ; Is instruction RO(d)?
            BNE         INVALID_INST        ; If no, invalid instruction
OP_ROd      MOVE.B      #'R',(A2)+          ; Puts RO into buffer
            MOVE.B      #'O',(A2)+          
            JSR         GET_DIR             ; Adds direction to buffer
            MOVE.B      #'.',(A2)+
            JSR         FIND_SIZE           ; Decides whether B,W,L
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            JSR         GET_IR              ; Determine register and EA
            JMP         END1110 
    
OP_ASd      MOVE.B      #'A',(A2)+          ; Puts AS into buffer
            MOVE.B      #'S',(A2)+          
            JSR         GET_DIR             ; Adds direction to buffer
            MOVE.B      #'.',(A2)+
            JSR         FIND_SIZE           ; Decides whether B,W,L
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            JSR         GET_IR              ; Determine register and EA
            JMP         END1110     

OP_LSd      MOVE.B      #'L',(A2)+          ; Puts LS into buffer
            MOVE.B      #'S',(A2)+          
            JSR         GET_DIR             ; Adds direction to buffer
            MOVE.B      #'.',(A2)+
            JSR         FIND_SIZE           ; Decides whether B,W,L
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            JSR         GET_IR              ; Determine register and EA
            JMP         END1110     

OP_ShMem    MOVE.W      D7,D6               ; Copies instruction to shift
            LSR.L       #08,D6              ; Shift instruction 8 bits left
            LSR.L       #1,D6               ; Shift instruction 1 extra to total 9
            ANDI.W      #$0007,D6           ; Get bits 9-11
            CMP.B       #%00,D6             ; Is this AS?
            BEQ         OP_ASm              ; If yes, go to AS location
            CMP.B       #%01,D6             ; Is this LS?
            BEQ         OP_LSm              ; If yes, go to LS location
            CMP.B       #%11,D6             ; Is this RO?
            BNE         INVALID_INST        ; If no, invalid instruction
            
OP_ROm      MOVE.B      #'R',(A2)+          ; Start RO opcode location
            MOVE.B      #'O',(A2)+          
            JSR         GET_DIR             ; Adds direction to buffer
            MOVE.B      #'.',(A2)+
            MOVE.B      #'W',(A2)+          ; Size is word for memory shift
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            JSR         GET_EA              ; Insert EA 
            JMP         END1110             ; Exit subroute 1110
            
OP_ASm      MOVE.B      #'A',(A2)+          ; Start AS opcode location
            MOVE.B      #'S',(A2)+          
            JSR         GET_DIR             ; Adds direction to buffer
            MOVE.B      #'.',(A2)+
            MOVE.B      #'W',(A2)+          ; Size is word for memory shift
            MOVE.B      #' ',(A2)+ 
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            JSR         GET_EA              ; Insert EA 
            JMP         END1110             ; Exit subroute 1110

OP_LSm      MOVE.B      #'L',(A2)+          ; Start AS opcode location
            MOVE.B      #'S',(A2)+          
            JSR         GET_DIR             ; Adds direction to buffer
            MOVE.B      #'.',(A2)+
            MOVE.B      #'W',(A2)+          ; Size is word for memory shift
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            JSR         GET_EA              ; Insert EA         
END1110     RTS


  

            
GROUP1_1111 
            JSR         INVALID_INST        ; Instruction  is invalid
            RTS


*--------------------------------------------------------------------------------------------------------------
*   SECOND OPCODE TABLE (4xxx opcodes)
*--------------------------------------------------------------------------------------------------------------
 
OP_TABLE4
            JMP         GROUP4_0000            
            JMP         GROUP4_0001            
            JMP         GROUP4_0010
            JMP         GROUP4_0011
            JMP         GROUP4_0100
            JMP         GROUP4_0101
            JMP         GROUP4_0110
            JMP         GROUP4_0111
            JMP         GROUP4_1000
            JMP         GROUP4_1001
            JMP         GROUP4_1010
            JMP         GROUP4_1011
            JMP         GROUP4_1100
            JMP         GROUP4_1101
            JMP         GROUP4_1110
            JMP         GROUP4_1111
            
GROUP4_0000 
            JSR         INVALID_INST        ; Instruction  is invalid
            RTS
            
GROUP4_0001 
            JSR         INVALID_INST        ; Instruction  is invalid
            RTS
            
GROUP4_0010 
            MOVE.B      #'C',(A2)+          ; Puts CLR into buffer
            MOVE.B      #'L',(A2)+
            MOVE.B      #'R',(A2)+
            MOVE.B      #'.',(A2)+
            JSR         FIND_SIZE           ; Decides whether B,W,L
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+         
            JSR         GET_EA              ; Insert EA
            RTS
            
GROUP4_0011 
            JSR         INVALID_INST        ; Instruction  is invalid
            RTS
                          
GROUP4_0100 
            MOVE.B      #'N',(A2)+          ; Puts NEG into buffer
            MOVE.B      #'E',(A2)+
            MOVE.B      #'G',(A2)+
            MOVE.B      #'.',(A2)+
            JSR         FIND_SIZE           ; Decides whether B,W,L
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+         
            JSR         GET_EA              ; Insert EA
            RTS
            
GROUP4_0101 
            JSR         INVALID_INST        ; Instruction  is invalid
            RTS
            
GROUP4_0110 
            MOVE.B      #'N',(A2)+          ; Puts NOT into buffer
            MOVE.B      #'O',(A2)+
            MOVE.B      #'T',(A2)+
            MOVE.B      #'.',(A2)+
            JSR         FIND_SIZE           ; Decides whether B,W,L
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #' ',(A2)+         
            JSR         GET_EA              ; Insert EA      
            RTS
            
GROUP4_0111 
            JSR         INVALID_INST        ; Instruction  is invalid
            RTS
            

*--------------------------------------------------------------------------------------------------------------
*   OPCODE: 0100 1000 (SWAP,MOVEM)
*-------------------------------------------------------------------------------------------------------------- 

GROUP4_1000 
            MOVE.W      D7,D6               ; Get new instruction
            LSR.L       #04,D6              ; Shift instruction by 4 bits
            ANDI.W      #$000F,D6           ; Get last byte
            CMP.B       #$4,D6              ; Is instruction SWAP?
            BNE         OP_MOVEM            ; If no, it is MOVEM
            MOVE.B      #'S',(A2)+          ; Puts SWAP into buffer
            MOVE.B      #'W',(A2)+
            MOVE.B      #'A',(A2)+
            MOVE.B      #'P',(A2)+
            MOVE.B      #$09,(A2)+
            MOVE.B      #'D',(A2)+          ; Adds D for data register
            MOVE.W      D7,D6               ; Get new instruction
            ANDI.W      #$000F,D6           ; Get last byte
            ADD.B       #$30,D6             ; Convert shift register to ASCII
            MOVE.B      D6,(A2)+            ; Puts reg number into buffer

            RTS            

OP_MOVEM    JSR         INVALID_INST        ; Instruction  is invalid
            RTS   

GROUP4_1001 
            JSR         INVALID_INST        ; Instruction  is invalid
            RTS   
GROUP4_1010 
            JSR         INVALID_INST        ; Instruction  is invalid
            RTS   
GROUP4_1011 
            JSR         INVALID_INST        ; Instruction  is invalid
            RTS
GROUP4_1100 
            JSR         INVALID_INST        ; Instruction  is invalid
            RTS
GROUP4_1101 
            JSR         INVALID_INST        ; Instruction  is invalid
            RTS
GROUP4_1111 
            JSR         INVALID_INST        ; Instruction  is invalid
            RTS   


*--------------------------------------------------------------------------------------------------------------
*   OPCODE: 0100 1110 (NOP, RTS, JSR, JMP)
*-------------------------------------------------------------------------------------------------------------- 

GROUP4_1110 
            JSR         GET_SIZE            ; Gets size for JSR and JMP instructions
            CMP.B       #%10,D6             ; Is instruction JSR?
            BEQ         OP_JSR              ; If yes, go to JSR
            CMP.B       #%11,D6             ; Is instruction JMP?
            BEQ         OP_JMP              ; If yes, go to JMP
            CMP.W       #$4E75,D7           ; Is instruction RTS?
            BEQ         OP_RTS              ; If yes, go to RTS           
            CMP.W       #$4E71,D7           ; Is instruction NOP?
            BNE         INVALID_INST        ; Instruction  is invalid
             
            MOVE.B      #'N',(A2)+          ; Puts NOP into buffer
            MOVE.B      #'O',(A2)+
            MOVE.B      #'P',(A2)+
            RTS
                                      
OP_JSR      MOVE.B      #'J',(A2)+          ; Puts JSR into buffer
            MOVE.B      #'S',(A2)+
            MOVE.B      #'R',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #$09,(A2)+          ; Adds 5 extra spacings
            JMP         GET_EA              ; Insert EA 

            RTS
                       
OP_JMP      MOVE.B      #'J',(A2)+          ; Puts JMP into buffer
            MOVE.B      #'M',(A2)+
            MOVE.B      #'P',(A2)+
            MOVE.B      #' ',(A2)+
            MOVE.B      #$09,(A2)+          ; Adds 5 extra spacings
            JSR         GET_EA              ; Insert EA             
            RTS
                                 
OP_RTS      MOVE.B      #'R',(A2)+          ; Puts RTS into buffer
            MOVE.B      #'T',(A2)+
            MOVE.B      #'S',(A2)+             
            RTS
            
GROUP2_1111 
            RTS    
            

*--------------------------------------------------------------------------------------------------------------
*   OPCODE SIZE METHODS: Checks size of instruction
*--------------------------------------------------------------------------------------------------------------    

GET_SIZE    MOVE.W      D7,D6               ; Copies current instruction to shift register
            LSR.W       #6,D6               ; Shifts instruction left 6 bits 
            ANDI.W      #$0003,D6           ; Removes non-size bits to store result into D6
            RTS

FIND_SIZE   JSR         GET_SIZE
            CMP.B       #%00,D6             ; Is value a byte?
            BEQ         IS_B                ; If yes, add B to buffer
            CMP.B       #%01,D6             ; Is value a word?
            BEQ         IS_W                ; If yes, add W to buffer
            CMP.B       #%10,D6             ; Is value a long?
            BNE         INVALID_INST        ; If no, instruction invalid
      
            MOVE.B      #'L',(A2)+          ; Adds L to buffer
            JMP         FIND_END            ; End Find  
            
IS_B        MOVE.B      #'B',(A2)+          ; Adds B to buffer
            JMP         FIND_END            ; End Find
            
IS_W        MOVE.B      #'W',(A2)+          ; Adds W to buffer

FIND_END    RTS     


*--------------------------------------------------------------------------------------------------------------
*   OPCODE MOVE/MOVEA METHODS: Swap destination and source regsisters
*--------------------------------------------------------------------------------------------------------------    
 
MOVE_SWAP   CLR.L       D3                  ; Clears D3 to hold swap value
            MOVE.W      D7,D6               ; Get copy of instruction to shift
            LSR.W       #08,D6              ; Shifts 8 bits left
            LSR.W       #1,D6               ; Shifts 1 extra time to total 9
            ANDI.W      #$0007,D6           ; Mask last 3 bits
            OR.W        D6,D3               ; Place bits in D3 to swap
            MOVE.W      D7,D6               ; Get copy of instruction to shift
            LSR.W       #3,D6               ; Shifts back into normal position
            ANDI.W      #$0038,D6           ; Mask bits 3-5
            OR.W        D6,D3               ; Place bits in D3
            JSR         MOVE_SIZE           ; Add move size bits 6-7 into D3 for ea
            MOVE.W      D3,D7               ; Swap register mode to determine destination from ea
            RTS
            
            
MOVE_SIZE   MOVE.W      D7,D6               ; Get copy of instruction to shift
            LSR.W       #08,D6              ; Shifts 8 bits left
            LSR.W       #04,D6              ; Shifts 6 bits left
            ANDI.W      #$0003,D6           ; Isolate move bits
            CMP.B       #$1,D6              ; Is value a byte?
            BEQ         SIZE_END            ; If yes, byte size already in bits 6-7 of D3
            CMP.B       #$2,D6              ; Is value a long?
            BEQ         SIZE_L              ; If yes, L size to D3 bits 6-7
            CMP.B       #$3,D6              ; Is value a word?
            BNE         INVALID_INST        ; If no, instruction invalid
        
SIZE_W      ORI.W       #$0040,D3           ; Add size 01 in bits 6-7, 4 into D3
            JMP         SIZE_END            ; End Size
            
SIZE_L      ORI.W       #$0080,D3           ; Add size 10 in bits 6-7, 4 into D3

SIZE_END    RTS 
                  
*--------------------------------------------------------------------------------------------------------------
*   OPCODE ASd, LSd, ROd METHODS: Finds bit direction and helps insert/print data
*-------------------------------------------------------------------------------------------------------------- 

GET_DIR     JSR         DIR_BIT             ; Gets direction bit returned in D6
            CMP.B       #%0,D6              ; Is this Right?
            BEQ         IS_dirR             ; If yes, populate right  
IS_dirL     MOVE.B      #'L',(A2)+          ; If no, populate L for left
            JMP         END_DIR             ; Jump to end
IS_dirR     MOVE.B      #'R',(A2)+
END_DIR     RTS


GET_IR      MOVE.W      D7,D6               ; Get new instruction
            LSR.L       #5,D6               ; Shift bit 5 into LSB
            ANDI.W      #$0001,D6           ; Get fifth bit
            CMP.B       #%0,D6              ; Is this the count shift?
            BEQ         VAL_SRC             ; If yes, insert value source
            MOVE.B      #'D',(A2)+          ; Adds D for data register
            JMP         VAL_SIZ             ; Insert value size
VAL_SRC     MOVE.B      #'#',(A2)+          ; Print value source
VAL_SIZ     JSR         HIGH_ADD            ; Add register number to buffer
            MOVE.B      #',',(A2)+          ; Adds comma between data
            MOVE.B      #'D',(A2)+          ; Adds D for data register
            MOVE.W      D7,D6               ; Get new instruction
            ANDI.W      #$0007,D6           ; Get bits 0-2
            ADD.B       #$30,D6             ; Convert shift reg to ASCII
            MOVE.B      D6,(A2)+            ; Add low reigster number to buffer
END_IR      RTS


*--------------------------------------------------------------------------------------------------------------
*   OPCODE PRINT DATA: Adds upper register data to buffer
*--------------------------------------------------------------------------------------------------------------

HIGH_ADD    MOVE.W      D7,D6               ; Get new instruction
            LSR.L       #08,D6              ; Shifts 8 bits left
            LSR.L       #1,D6               ; Shifts 1 extra time to total 9
            ANDI.B      #$7,D6              ; Get last 7 bits for register number
            ADD.B       #$30,D6             ; Convert register number to ascii
            MOVE.B      D6,(A2)+            ; Number into buffer
            RTS

DIR_BIT     MOVE.W      D7,D6               ; Get new instruction
            LSR.L       #08,D6              ; Shifts to get eighth bit
            ANDI.B      #01,D6              ; Get last bit
            RTS  
            
LOAD_SIZE   CMP.B       #%00,D6             ; Is value a byte?
            BEQ         BYTE_BUFFER         ; If yes, insert B amount of address into buffer
            CMP.B       #%01,D6             ; Is value a word?
            BEQ         WORD_BUFFER         ; If yes, insert W amount of address into buffer
            CMP.B       #%10,D6             ; Is value a long?
            BEQ         LONG_BUFFER         ; If yes, insert L amount of address into buffer
            RTS


*--------------------------------------------------------------------------------------------------------------
*   OPCODE INVALID: Puts DATA as placeholder for instruction
*--------------------------------------------------------------------------------------------------------------
            
INVALID_INST
            MOVE.B      #FALSE,D5           ; Boolean = FALSE
            MOVEA.L     A3,A2               ; Resets buffer pointer 
            MOVE.B      #'D',(A2)+          ; Add DATA to buffer as placeholder
            MOVE.B      #'A',(A2)+
            MOVE.B      #'T',(A2)+
            MOVE.B      #'A',(A2)+
            MOVE.B      #$09,(A2)+
            MOVE.B      #'$',(A2)+          ; ADD $ for address
            JSR         GET_INVALID         ; Insert cooresponding data to buffer
            RTS          

GET_INVALID
            MOVEQ       #$0,D6              ; Clear D6 for copying word
            MOVE.W      D7,D6               ; Copy word instruction to D6
            MOVE.B      #12,D4              ; Add 12 bytes to be shifted
            LSR.L       D4,D6               ; Shift D^ 12 bytes left
            ANDI.W      #$000F,D6           ; Get last 4 bits
            JSR         HEX_TO_ASCII        ; Add first value to buffer
            MOVE.W      D7,D6
            MOVE.B      #08,D4
            LSR.L       D4,D6
            ANDI.W      #$000F,D6
            JSR         HEX_TO_ASCII        ; Add second value to buffer
            MOVE.W      D7,D6
            MOVE.B      #04,D4
            LSR.L       D4,D6
            ANDI.W      #$000F,D6
            JSR         HEX_TO_ASCII        ; Add third value to buffer
            MOVE.W      D7,D6
            ANDI.W      #$000F,D6
            JSR         HEX_TO_ASCII        ; Add fourth value to buffer
            RTS
          

*--------------------------------------------------------------------------------------------------------------
*   Hex to ASCII: converts hex to ascii
*--------------------------------------------------------------------------------------------------------------

HEX_TO_ASCII
            CMP.B       #$A,D6              ; Confirm is value is a hex character
            BGE         LETTER              ; Checks if value is a letter or number
            ADDI.B      #$30,D6             ; Converts value to ASCII
            BRA         TO_BUFFER           ; Save to buffer
            
LETTER      ADDI.B      #$37,D6             ; Checks if value is a letter or number

TO_BUFFER   MOVE.B      D6,(A2)+            ; Save to buffer
            RTS


*--------------------------------------------------------------------------------------------------------------
*   FORMAT ADDRESS OUTPUT: for data to be displayed next to each corresponding address
*--------------------------------------------------------------------------------------------------------------

FORMAT_ADD  JSR         SHIFT1              ; Clears D6 to load new value
            MOVE.B      #12,D4              ; Assigns D4 with 12 bits to shift
            JSR         SHIFT2              ; Shifts 12 bits
            MOVE.B      #08,D4              ; Assigns D4 with 8 bits to shift
            JSR         SHIFT2              ; Shifts 8 bits
            MOVE.B      #04,D4              ; Assigns D4 with 4 bits to shift
            JSR         SHIFT2              ; Shifts 4 bits
            MOVE.B      #0,D4               ; Clear D4 register
            JSR         SHIFT4              ; Shifts no bits
            
            MOVE.B      #12,D4              ; Assigns D4 with 12 bits to shift
            JSR         SHIFT4              ; Shifts 12 bits
            MOVE.B      #08,D4              ; Assigns D4 with 8 bits to shift
            JSR         SHIFT4              ; Shifts 8 bits
            MOVE.B      #04,D4              ; Assigns D4 with 4 bits to shift
            JSR         SHIFT4              ; Shifts 4 bits
            MOVE.B      #0,D4               ; Clear D4 register
            LSR.L       D4,D6               ; Shifts address left 0 bits
            
            ANDI.L      #$0000000F,D6       ; Gets last bit of address
            JSR         HEX_TO_ASCII        ; Places value in buffer

SHIFT1      MOVEQ       #$0,D6              ; Clears D6 register
            MOVE.L      A0,D6               ; Loads current address to print in output
            SWAP        D6                  ; Swaps high and low words
            RTS

SHIFT2      LSR.L       D4,D6               ; Shifts address left x bits
            ANDI.L      #$0000000F,D6       ; Gets last bit of address
            JSR         HEX_TO_ASCII        ; Places value in buffer
            JSR         SHIFT1              ; Reset address for next shift
            RTS

SHIFT3      MOVEQ       #$0,D6              ; Clears D6 address register
            MOVE.L      A0,D6               ; Loads current address to print in output
            RTS
            
SHIFT4      LSR.L       D4,D6               ; Shifts address left x bits
            ANDI.L      #$0000000F,D6       ; Gets last bit of address
            JSR         HEX_TO_ASCII        ; Place address value into buffer
            JSR         SHIFT3              ; Reset address for next shift
            RTS


*--------------------------------------------------------------------------------------------------------------
*   CLEAR METHODS
*--------------------------------------------------------------------------------------------------------------    
      
CLEAR_REG1
            CLR         D0                  ; Clears all data registers
            CLR         D1
            CLR         D2
            CLR         D3
            CLR         D4
            CLR         D5
            CLR         D6
            CLR         D7            
            MOVEA.L     #$0, A0             ; Clears all address registers
            MOVEA.L     #$0, A1
            MOVEA.L     #$0, A2
            MOVEA.L     #$0, A3
            MOVEA.L     #$0, A4
            MOVEA.L     #$0, A5
            MOVEA.L     #$0, A6            
            RTS
             
CLEAR_REG2  
            CLR.L       D0                  ; Clears each register except boolean (D5)
            CLR.L       D1
            CLR.L       D2
            CLR.L       D3
            CLR.L       D4
            CLR.L       D6
            CLR.L       D7
            RTS     


*-------------------------------------------------------------------------------------------------------------------------------------------------------------------
*===============================================================EA_ROUTINES=========================================================================================
*-------------------------------------------------------------------------------------------------------------------------------------------------------------------

*--------------------------------------------------------------------------------------------------------------
*   START OF EA ROUTINE
*--------------------------------------------------------------------------------------------------------------            

GET_EA       
            LEA         EA_Modes,A5         ; Load EA_modes into D5
            CLR.L       D2                  ; Clear registers
            CLR.L       D3
            CLR.L       D4           
            CLR.L       D6
            MOVE.W      D7,D6               ; Move word into D6
            ANDI.W      #$003F,D6           ; Leave mode bits
            MOVE.B      #3,D1               ; Load D1 with bits to shift            
            LSR.W       D1,D6               ; Shifts D6 Right with valuein D1            

            MULU        #6,D6               ; Becomes offset for Index table            
            JSR         00(A5,D6)           ; Go back to Index table        

            RTS                             ; Return from EA routine
        
            JMP         END


*--------------------------------------------------------------------------------------------------------------
*   EA TABLE AND MODES
*-------------------------------------------------------------------------------------------------------------- 
   
EA_Modes                             
            JMP         EA_000              ; Data Register Dn
            JMP         EA_001              ; Address Register An
            JMP         EA_010              ; Indirect Address Register (An)
            JMP         EA_011              ; Indirect w/ Post Increment (An)+
            JMP         EA_100              ; Indirect w/ Pre Decrement -(An)
            JMP         EA_101              ; Indirect Address Register using Index
            JMP         EA_110              ; Address Register w/ Index
            JMP         EA_111              ; Absolute (.W or .L) or Immediate EA

 
EA_000      MOVE.W      D7,D6               ; Move current word value into temp
            ANDI.W      #$7,D6              ; Get last 3 register bits
            MOVE.B      #$44,(A2)+          ; Adds D for data register to buffer
            ADD.B       #$30,D6             ; Convert data value to hex
            MOVE.B      D6,(A2)+            ; Add number to buffer                  
            
            RTS
  
EA_001
            MOVE.W      D7,D6               ; Move current word value into temp
            ANDI.W      #$7,D6              ; Get last 3 register bits
            MOVE.B      #$41,(A2)+          ; Adds A for address register to buffer
            ADD.B       #$30,D6             ; Convert data value to hex
            MOVE.B      D6,(A2)+            ; Add number to buffer
              
            RTS
  
EA_010
            MOVE.W      D7,D6               ; Move current word value into temp
            ANDI.W      #$7,D6              ; Get last 3 register bits
            MOVE.B      #$28,(A2)+          ; Adds ( to buffer            
            MOVE.B      #$41,(A2)+          ; Adds A for address register to buffer
            ADD.B       #$30,D6             ; Convert data value to hex
            MOVE.B      D6,(A2)+            ; Add number to buffer
            MOVE.B      #$29,(A2)+          ; Adds ) to buffer
             
            RTS

EA_011
            
            MOVE.W      D7,D6               ; Move current word value into temp
            ANDI.W      #$7,D6              ; Get last 3 register bits
            MOVE.B      #$28,(A2)+          ; Adds ( to buffer              
            MOVE.B      #$41,(A2)+          ; Adds A for address register to buffer
            ADD.B       #$30,D6             ; Convert data value to hex
            MOVE.B      D6,(A2)+            ; Add number to buffer
            MOVE.B      #$29,(A2)+          ; Adds ) to buffer
            MOVE.B      #$2B,(A2)+          ; Adds + to buffer
                 
            RTS
  
EA_100
           
            MOVE.W      D7,D6               ; Move current word value into temp
            ANDI.W      #$7,D6              ; Get last 3 register bits
            MOVE.B      #$2D,(A2)+          ; Adds - to buffer
            MOVE.B      #$28,(A2)+          ; Adds ( to buffer            
            MOVE.B      #$41,(A2)+          ; Adds A for address register to buffer
            ADD.B       #$30,D6             ; Convert data value to hex
            MOVE.B      D6,(A2)+            ; Add number to buffer
            MOVE.B      #$29,(A2)+          ; Adds ) to buffer
            
            RTS

EA_101
            JMP         INVALID_INST        ; Instruction is invalid

EA_110
            JMP         INVALID_INST        ; Instruction is invalid

EA_111
            JSR         REG_BITS            ; Get register bits
            CMPI.B      #$0,D6              ; Is bit a word?
            BEQ         WORD_BUFFER         ; Insert word address in buffer
            CMPI.B      #$1,D6              ; Is bit a long?
            BEQ         LONG_BUFFER         ; Insert long address in buffer
            CMPI.B      #$2,D6

            CMPI.B      #$2,D6              ; Is it PC w/ Displacement?
            BEQ         PRINT_PC            ; If yes, print PC
            CMPI.B      #$4,D6              ; Is it Immediate?
            BEQ         IM_BUFFER           ; If yes, go to immediate buffer
           
            RTS


*--------------------------------------------------------------------------------------------------------------
*   EA SUBROUTINES
*--------------------------------------------------------------------------------------------------------------

REG_BITS    MOVE.W  D7,D6                   ; Value in D2 becomes what is in A0
            ANDI.W  #$07,D6
            RTS
            
IM_BUFFER 
            MOVE.B      #'#',(A2)+
            JSR         MOVE_SIZE
            CMPI.B      #$1,D6              ; Is value a word?
            BEQ         BYTE_BUFFER         ; If yes, put word address in buffer
            CMPI.B      #$3,D6              ; Is value a long?
            BEQ         WORD_BUFFER         ; If yes, put word address in buffer            
            CMPI.B      #$2,D6
            BEQ         LONG_BUFFER
            RTS
            
PRINT_PC
            JSR         WORD_BUFFER
            MOVE.B      #$28,(A2)+          ; Adds ( to buffer            
            MOVE.B      #$50,(A2)+          ; Adds P to buffer
            MOVE.B      #$43,(A2)+          ; Adds C to buffer
            MOVE.B      #$29,(A2)+          ; Adds ) to buffer                        
            RTS


*--------------------------------------------------------------------------------------------------------------
*   BYTE_BUFFER
*--------------------------------------------------------------------------------------------------------------
            
BYTE_BUFFER   
            MOVE.B      #'$',(A2)+          ; To add $ before address
            CLR.L       D4                  ; Clear D4
            MOVE.W      (A0),D2             ; Move current value into D2
            CLR.L       D4                  ; Clear D4
            MOVE.B      #2,D4               ; Start counter in D4

b2bLOOP                 
            CMP.B       #$00,D4             ; Compares counter with 0
            BEQ         RETURN_EA0          ; If counter = 0, return
            ROL.B       #4,D2               ; roll the bits in D2 to the left
            MOVE.W      D2,D6               ; Rolled bits go into temp
            ANDI.W      #$000F,D6           ; Get the ascii value   
            JSR         HEX_TO_ASCII        ; Insert ascii value into buffer            
            SUBQ.B      #$1,D4              ; Subtract from counter
            JMP         b2bLoop             ; Continue looping until counter = 0
            
RETURN_EA0  MOVE.W      D7,D6               ; Load current word for temp            
            ADDQ.W      #2,A0               ; Move memory pointer by word   
            RTS
            
            
*--------------------------------------------------------------------------------------------------------------
*   WORD_BUFFER
*--------------------------------------------------------------------------------------------------------------

WORD_BUFFER 
            MOVE.B      #'$',(A2)+          ; To add $ before address
            CLR.L       D4                  ; Clear D4
            MOVE.B      #$24,(A2)+          ; Put $ before address in buffer
            MOVE.W      (A0),D2             ; Move current value into D2
            CLR.L       D4                  ; Clear D4
            MOVE.B      #4,D4               ; Start counter in D4

w2bLOOP                 
            CMP.B       #$00,D4             ; Compares counter with 0
            BEQ         RETURN_EA1          ; If counter = 0, return
            ROL.W       #4,D2               ; roll the bits in D2 to the left
            MOVE.W      D2,D6               ; Rolled bits go into temp
            ANDI.W      #$000F,D6           ; Get the ascii value      
            JSR         HEX_TO_ASCII        ; Insert ascii value into buffer           
            SUBQ.B      #$1,D4              ; Subtract from counter
            JMP         w2bLoop             ; Continue looping until counter = 0
            
RETURN_EA1  
            MOVE.W      D7,D6               ; Load current word for temp            
            ADDQ.W      #2,A0               ; Move memory pointer by word    
            RTS


*--------------------------------------------------------------------------------------------------------------
*   LONG_BUFFER
*--------------------------------------------------------------------------------------------------------------

LONG_BUFFER
            MOVE.B      #'$',(A2)+          ; To add $ before address
            CLR.L       D4                  ; Clear D4
            MOVE.L      (A0),D2             ; Move current value into D2
            CLR.L       D4                  ; Clear D4
            MOVE.B      #8,D4               ; Start counter in D4

l2bLOOP                 
            CMP.B       #$00,D4             ; Compares counter with 0
            BEQ         RETURN_EA2          ; If counter = 0, return
            ROL.L       #4,D2               ; roll the bits in D2 to the left
            MOVE.W      D2,D6               ; Rolled bits go into temp
            ANDI.W      #$000F,D6           ; Get the ascii value      
            JSR         HEX_TO_ASCII        ; Insert ascii value into buffer             
            SUBQ.B      #$1,D4              ; Subtract from counter
            JMP         l2bLoop             ; Continue looping until counter = 0
            
RETURN_EA2  MOVE.W      D7,D6               ; Load current word for temp 
            ADDQ.W      #4,A0               ; Move memory pointer by word
            RTS


*--------------------------------------------------------------------------------------------------------------
*   MESSAGES   
*--------------------------------------------------------------------------------------------------------------
            
INTRO       DC.B        '------------------------------------------',CR,LF
            DC.B        CR,LF,'           Program Disassembler',CR,LF,CR,LF
            DC.B        '------------------------------------------',CR,LF,0
        
INPUT1      DC.B        'Enter starting address: $',0        ; Ask user for lower boundary
INPUT1_len  DC.W        INPUT1_len-INPUT1                    ; Gets the length of input string

INPUT2      DC.B        'Enter ending address: $',0          ; Ask user for higher boundary
INPUT2_len  DC.W        INPUT2_len-INPUT2                    ; Gets the length of input string

ERRPARAM    DC.B        'Error: input parameters are invalid.',0
PARAM_len   DC.W        PARAM_len-ERRPARAM

ERRSTART    DC.B        'Error: starting hexadecimal address invalid.',0
START_len   DC.W        ERRSTART-START_len

ERREND      DC.B        'Error: ending hexadecimal address invalid.',0
END_len     DC.W        ERREND-END_len

MORE_DATA   DC.B        'Press enter for more data',0
MORE_len    DC.W        MORE_DATA-MORE_len

REPEAT      DC.B        'Would you like to continue disassembling? (Y = 1, N = 0): ',0
REPEAT_len  DC.W        REPEAT_len-REPEAT      

EXIT        DC.W        'End of program',0
EXIT_len    DC.W        EXIT_len-EXIT           

main_buff   DC.B        1


*--------------------------------------------------------------------------------------------------------------
*   VARIABLES & CONSTANTS
*--------------------------------------------------------------------------------------------------------------

CR          EQU         $0D
LF          EQU         $0A

minBOUND    EQU         $00000000           ; Minimum bound
maxBOUND    EQU         $00FFFFFF           ; Maximum bound
stack       EQU         $A000               ; Stack Address
data        EQU         $4000               ; Data Address
lineCount   EQU         25                  ; Total lines to be displayed
length      EQU         0                   ; Effective address length to be stored in D reg
TRUE        EQU         1                   ; Boolean - is true
FALSE       EQU         0                   ; Boolean - is false

                                 
*--------------------------------------------------------------------------------------------------------------
*   END OF PROGRAM
*--------------------------------------------------------------------------------------------------------------

END         STOP        #$2700
            END         start


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
