;==================================================================================
; Contents of this file are copyright Grant Searle
;
; You have permission to use this for NON COMMERCIAL USE ONLY
; If you wish to use it elsewhere, please include an acknowledgement to myself.
;
; http://searle.hostei.com/grant/index.html
;
; eMail: home.micros01@btinternet.com
;
; If the above don't work, please perform an Internet search to see if I have
; updated the web page hosting service.
;
;==================================================================================

; Minimum 6850 ACIA interrupt driven serial I/O to run modified NASCOM Basic 4.7
; Full input buffering with incoming data hardware handshaking
; Handshake shows full before the buffer is totally filled to allow run-on from the sender

SER_BUFSIZE     .EQU     3FH
SER_FULLSIZE    .EQU     30H
SER_EMPTYSIZE   .EQU     5

;RTS_HIGH        .EQU     0D6H
;RTS_LOW         .EQU     096H

serBuf          .EQU     $8000
serInPtr        .EQU     serBuf+SER_BUFSIZE
serRdPtr        .EQU     serInPtr+2
serBufUsed      .EQU     serRdPtr+2
basicStarted    .EQU     serBufUsed+1
TEMPSTACK       .EQU     $80ED ; Top of BASIC line input buffer so is "free ram" when BASIC resets

LCD_A		=    $EF13
LCD_COL     =    $EF14
LCD_ROW     =    $EF15


CR              .EQU     0DH            ; enter
LF              .EQU     0AH            ; retorna o cursor
CS              .EQU     0CH             ; Clear screen

                .ORG $0000
;------------------------------------------------------------------------------
; Reset
           
				DI                       ;Disable interrupts
                JP       INIT            ;Initialize Hardware and go

;------------------------------------------------------------------------------
; TX a character over RS232 

                .ORG     0008H
	            JP      TXA

;------------------------------------------------------------------------------
; RX a character over RS232 Channel A [Console], hold here until char ready.

                .ORG 0010H
                JP      RXA

;------------------------------------------------------------------------------
; Check serial status

                .ORG 0018H
                JP      CKINCHAR

;------------------------------------------------------------------------------
; RST 38 - INTERRUPT VECTOR [ for IM 1 ]

                .ORG     0038H
                JR      serialInt       

;------------------------------------------------------------------------------
serialInt:      
		        PUSH     AF
                PUSH     HL

                IN       A,($01)
                ;cp      $0C         ; CTRL-L
                ;call    z, lcd_clear
                ;jr      z, rts0

                cp      $0D             ; ENTER
                call      z, lcd_clear

                call delay

                PUSH     AF
                LD       A,(serBufUsed)
                CP       SER_BUFSIZE     ; If full then ignore
                JR       NZ,notFull
                POP      AF
                JR       rts0

notFull:        
				LD       HL,(serInPtr)
                INC      HL
                LD       A,L             ; Only need to check low byte becasuse buffer<256 bytes
                CP       (serBuf+SER_BUFSIZE) & $FF
                JR       NZ, notWrap
                LD       HL,serBuf
notWrap:        
				LD       (serInPtr),HL
                POP      AF
                LD       (HL),A
                LD       A,(serBufUsed)
                INC      A
                LD       (serBufUsed),A
                CP       SER_FULLSIZE
                JR       C,rts0
                ;LD       A,RTS_HIGH
                ;OUT      ($80),A
rts0:           
				POP      HL
                POP      AF
                EI
                RETI

;------------------------------------------------------------------------------
RXA:
waitForChar:    
				LD       A,(serBufUsed)
                CP       $00
                JR       Z, waitForChar
                PUSH     HL
                LD       HL,(serRdPtr)
                INC      HL
                LD       A,L             ; Only need to check low byte becasuse buffer<256 bytes
                CP       (serBuf+SER_BUFSIZE) & $FF
                JR       NZ, notRdWrap
                LD       HL,serBuf
notRdWrap:      
				DI         ; disable int
                call delay

                LD       (serRdPtr),HL
                LD       A,(serBufUsed)
                DEC      A
                LD       (serBufUsed),A
                CP       SER_EMPTYSIZE
                JR       NC,rts1
                ;LD       A,RTS_LOW
                ;OUT      ($80),A
rts1:
                LD       A,(HL)
                EI
                POP      HL
                RET                      ; Char ready in A

;------------------------------------------------------------------------------
TXA:            
				; CHAR IN A 
ver_enter:       

                ; trata dados para o lcd
                CP      $0D                     ; compara com ENTER
                jr      nz, ver_limpa

                push    hl
                LD      A, (LCD_ROW)
                INC     A
                ld      (LCD_ROW), A

                cp      $04
                call    z, ajusta_line_zero

                LD      HL, lines
                LD      A, (LCD_ROW)
                cp      0
                call    nz, ajusta_hl_in_a                

                LD      A, (HL)
                call    lcd_send_command
                pop     hl
                RET

ver_limpa:
                CP      $0C                     ; compara com limpar tela
                jr      NZ, ver_line
                ld a, 0
                ld (LCD_COL), A
                ld (LCD_ROW), A
                LD A, 01h 				; limpa lcd
                call lcd_send_command
                RET

ver_line:
                CP      $0A                     ; retorna começo da linha
                jr      NZ, print_lcd      

                push    hl
                LD      A, 0
                LD      (LCD_COL), A

                LD      HL, lines
                LD      A, (LCD_ROW)
                cp      0
                call    nz, ajusta_hl_in_a
                LD      A, (HL)
                call    lcd_send_command
                pop     hl
                RET   

print_lcd:
                push    af
                ld a, (LCD_COL)
                cp      $13 ; 19 decimal
                jr nz, print_lcd_ok   ; se não esta no final da linha

                ;; enter
                LD      A, (LCD_ROW)
                INC     A
                LD      (LCD_ROW), a

                cp      $04
                call    z, ajusta_line_zero


                LD      HL, lines
                LD      A, (LCD_ROW)
                cp      0
                call    nz, ajusta_hl_in_a
                
                LD      A, (HL)
                call    lcd_send_command

print_lcd_ok:
                ld A, (LCD_COL)
                inc A
                ld (LCD_COL), A
                pop     af
				call lcd_send_data
                RET


;   ----------------------------------------------------------
ajusta_line_zero:
                ld a, 0
                ld (LCD_ROW), A
                ld (LCD_COL), A
                ret


ajusta_hl_in_a:
                dec     a
                inc     HL
                cp 0
                jp nz, ajusta_hl_in_a
                RET

lines:          .BYTE       $80
                .BYTE       $C0
                .BYTE       $94
                .BYTE       $D4

;------------------------------------------------------------------------------
CKINCHAR:
				LD       A,(serBufUsed)
                CP       $0
                RET

PRINT:          
				LD       A,(HL)          ; Get character
                OR       A               ; Is it $00 ?
                RET      Z               ; Then RETurn on terminator
                RST      08H             ; Print it
                INC      HL              ; Next Character
                JR       PRINT           ; Continue until $00
                RET
;------------------------------------------------------------------------------
INIT:
                LD      A, 0
                LD      (LCD_COL), a
                LD      (LCD_ROW), a
               LD        HL,TEMPSTACK    ; Temp stack
               LD        SP,HL           ; Set up a temporary stack
               LD        HL,serBuf
               LD        (serInPtr),HL
               LD        (serRdPtr),HL
               XOR       A               ;0 to accumulator
               LD        (serBufUsed),A
               call      lcd_init
               IM        1
               EI
               LD        HL,SIGNON1      ; Sign-on message
               CALL      PRINT           ; Output string
               LD        A,(basicStarted); Check the BASIC STARTED flag
               CP        'Y'             ; to see if this is power-up
               JR        NZ,COLDSTART    ; If not BASIC started then always do cold start
               LD        HL,SIGNON2      ; Cold/warm message
               CALL      PRINT           ; Output string
CORW:
               CALL      RXA
               AND       %11011111       ; lower to uppercase
               CP        'C'
               JR        NZ, CHECKWARM
               RST       08H
               LD        A,$0D
               RST       08H
               LD        A,$0A
               RST       08H
COLDSTART:     
				LD        A,'Y'           ; Set the BASIC STARTED flag
               LD        (basicStarted),A
               JP        $0300           ; Start BASIC COLD
CHECKWARM:
               CP        'W'
               JR        NZ, CORW
               RST       08H
               LD        A,$0D
               RST       08H
               LD        A,$0A
               RST       08H
               JP        $0303           ; Start BASIC WARM
              
SIGNON1:       
			    ;.BYTE     CS
               ;.BYTE     "Z80 SBC By Grant Searle",CR,LF,0
               .BYTE     "Z80 - Diego Cruz",CR,LF,0
SIGNON2:       
				;.BYTE     CR,LF
               .BYTE     "(C)old or (W)arm? ",0
               
;; ---------------------- LCD ----------------------
; Ports
porta	= 01h
portb	= 02h
en	= 01h
rw	= 02h
rs	= 04h

;***************************************************************************
;	delay:
;	Function: Delay
;***************************************************************************

delay:
	push bc
    ld b, 40
delay_loop_b:
	ld c, 255
delay_loop:
	dec c
    jp nz, delay_loop
    dec b
    jp nz, delay_loop_b
    pop bc
    ret

;***************************************************************************
;	lcd_delay:
;
;***************************************************************************
lcd_delay:
	push bc
	ld c, 160
lcd_delay_loop:
	dec c
    jp nz, lcd_delay_loop
    pop bc
    ret

;***************************************************************************
;	lcd_init:
;	Function: Init display lcd 16x2
;***************************************************************************
lcd_clear:
    push af
    ld a, 01h 				; limpa lcd
    call lcd_send_command
    ld a, $FF
    ld (LCD_ROW), A
    ld (LCD_COL), A
    pop af
    ret
    
    
;***************************************************************************
;	lcd_init:
;	Function: Init display lcd 16x2
;***************************************************************************
lcd_init:
	push af
    
    ; reset lcd
    ld a, 30h 				; limpa lcd
    call lcd_send_command4
    
    ld a, 30h 				; limpa lcd
    call lcd_send_command4
    
    ld a, 30h 				; limpa lcd
    call lcd_send_command4
    
    ld a, 20h 				; Mode 4 bit
    call lcd_send_command4
    
	ld a, 28h 				; func set
    call lcd_send_command
    
    ld a, 0Eh 				; Display on, cursor blinking 
    call lcd_send_command
    
    ld a, 06h 				; Increment cursor (shift cursor to right)
    call lcd_send_command
    
    ld a, 01h 				; limpa lcd
    call lcd_send_command
    
    pop af
    ret
    
    
;***************************************************************************
;	lcd_send_command4:
;	Function: Send command to lcd
;***************************************************************************
lcd_send_command4:
	push af

    ; send x xxxxyyyy
    srl a
    srl a
    srl a
    srl a
    
    call lcd_delay
    call lcd_delay
    
	out	(porta),a	;carrega acc no portb
    call lcd_delay
    
    set 7, a		;envia bit de enable para o acc
	out	(porta),a
    call lcd_delay
    
    res 7, a
	out	(porta),a
    call lcd_delay
    
    pop af
    ret    
    
    

;***************************************************************************
;	lcd_send_command:
;	Function: Send command to lcd
;***************************************************************************
lcd_send_command:
	call lcd_delay
	push af
    
    ld (LCD_A),a ; preserva a
    
    ; send x xxxxyyyy
    srl a
    srl a
    srl a
    srl a
    
	out	(porta),a	;carrega acc no portb
    call lcd_delay
    
    set 7, a		;envia bit de enable para o acc
	out	(porta),a
    call lcd_delay
    
    res 7, a
	out	(porta),a
    call lcd_delay
    
    ; send y xxxxyyyy
    ld a,(LCD_A)
    and $0f
    
    set 7, a		;envia bit de enable para o acc
	out	(porta),a
    call lcd_delay
    
    res 7, a
	out	(porta),a
    call lcd_delay
    
    pop af
    ret
    

;***************************************************************************
;	lcd_send_command:
;	Function: Send command to lcd
;***************************************************************************
lcd_send_data:
	call lcd_delay
	push af
    
    ld (LCD_A),a ; preserva a
    
    ; send x xxxxyyyy
    srl a
    srl a
    srl a
    srl a
    
    set 6,a
	out	(porta),a	;carrega acc no portb
    call lcd_delay
    
    set 6,a
    set 7, a		;envia bit de enable para o acc
	out	(porta),a
    call lcd_delay
    
    set 6,a
    res 7, a
	out	(porta),a
    call lcd_delay
    
    ; send y xxxxyyyy
    ld a,(LCD_A)
    and $0f
    
    set 6,a
    set 7, a		;envia bit de enable para o acc
	out	(porta),a
    call lcd_delay
    
    set 6,a
    res 7, a
	out	(porta),a
    call lcd_delay
    
    pop af
    ret
              
.END
