* -- Preconditions: The instruction as read from memory is stored in D6


* -- Preconditions: The instruction as read from memory is stored in D6

DECODE_OPCODE       MOVE.W      D6, D5                  * -- make copy
                    AND.W       #$F000, D5              * -- mask opcode
                    MOVE.B      #12, D1
                    LSR.L       D1, D5 

IDENT_OPCODE        CMP.B       #%0110, D5
                    BEQ         DECODE_GROUP_6
                    CMP.B       #%0100, D5
                    BEQ         DECODE_GROUP_4
                    CMP.B       #%1100, D5
                    BEQ         DECODE_GROUP_C
                    CMP.B       #%1101, D5
                    BEQ         DECODE_GROUP_D
                    CMP.B       #%1001, D5
                    BEQ         DECODE_GROUP_9
                    CMP.B       #%0101, D5
                    BEQ         DECODE_GROUP_5
                    CMP.B       #%1000, D5
                    BEQ         DECODE_GROUP_8
                    CMP.B       #%0001, D5
                    BEQ         DECODE_GROUP_MOVE
                    CMP.B       #%0010, D5
                    BEQ         DECODE_GROUP_MOVE
                    CMP.B       #%0011, D5
                    BEQ         DECODE_GROUP_MOVE
                    BRA         INVALID_OPCODE

INVALID_OPCODE      BRA         DECODE_OPCODE_DONE

DECODE_OPCODE_DONE  BRA         MAIN_LOOP_END

DECODE_GROUP_MOVE   MOVE.W      D6, D5
                    AND.W       #$01C0, D5
                    LSR.W       #6, D5
                    CMP.B       #%001, D5
                    BEQ         DECODE_MOVEA
                    BRA         DECODE_MOVE

DECODE_GROUP_8      MOVE.W      D6, D5
                    AND.W       #$01C0, D5
                    LSR.W       #6, D5
                    CMP.B       #%111, D5
                    BEQ         DECODE_DIVS
                    BRA         INVALID_OPCODE 

DECODE_GROUP_5      MOVE.W      D6, D5
                    AND.W       #$0100, D5
                    LSR.W       #8, D5
                    CMP.B       #0, D5
                    BEQ         DECODE_ADDQ
                    BRA         INVALID_OPCODE  

DECODE_GROUP_9      MOVE.W      D6, D5
                    AND.W       #$00C0, D5
                    LSR.W       #6, D5
                    CMP.B       #%11, D5
                    BEQ         DECODE_SUBA
                    BRA         DECODE_SUB                                                         

DECODE_GROUP_D      MOVE.W      D6, D5
                    AND.W       #$00C0, D5
                    LSR.W       #6, D5
                    CMP.B       #%11, D5
                    BEQ         DECODE_ADDA
                    BRA         DECODE_ADD

DECODE_GROUP_C      MOVE.W      D6, D5
                    AND.W       #$00C0, D5
                    LSR.W       #6, D5
                    CMP.B       #%11, D5
                    BEQ         DECODE_MULS
                    BRA         DECODE_AND

DECODE_GROUP_4      MOVE.W      D6, D5                  * -- recover the data
                    CMP.W       #$4E75, D5
                    BEQ         DECODE_RTS

                    AND.W       #$0FC0, D5              * -- mask #1
                    LSR.W       #6, D5

                    CMP.W       #%111010, D5
                    BEQ         DECODE_JSR

                    AND.W       #$07, D5                * -- mask #2

                    CMP.W       #%111, D5
                    *BEQ         DECODE_LEA

                    MOVE.W      D6, D5                  * -- recover data
                    AND.W       #$0800, D5              * -- mask #3
                    MOVE.B      #11, D1
                    LSR.W       D1, D5
                    CMP.B       #1, D5
                    *BEQ         DECODE_MOVEM

                    MOVE.W      D6, D5                  * -- recover data
                    AND.W       #$0E00, D5              * -- mask #4
                    MOVE.B      #9, D1
                    LSR.W       D1, D5
                    CMP.B       #%010, D5
                    BEQ         DECODE_NEG
                    CMP.B       #%011, D5
                    BEQ         DECODE_NOT
                    BRA         INVALID_OPCODE

DECODE_GROUP_6      MOVE.W      D6, D5
                    AND.W       #$0F00, D5
                    LSR.W       #8, D5
                    CMP.B       #0, D5
                    BNE         DECODE_Bcc
                    BRA         DECODE_BRA
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
