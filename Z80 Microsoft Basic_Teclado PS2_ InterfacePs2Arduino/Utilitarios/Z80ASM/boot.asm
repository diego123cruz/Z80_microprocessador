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

;
;   DIEGO CRUZ - 08/2021
;   ----------------------------------
;               ROM MAP
;   
;   Monitor     0000H - ????
;
;   Basic       6000H - 7D00H
;   LIVRE       7D00H - 7FF0
;
;   ===================================
;
;               RAM MAP
;
;   Monitor vars        8000H - 80FFH
;   Basic work stace    8200H - TOP
;
;

;   -------   HARDWARE   -------
porta       =   $01
portb       =   $02

SER_BUFSIZE     .EQU     3FH
SER_FULLSIZE    .EQU     30H
SER_EMPTYSIZE   .EQU     5

serBuf          .EQU     $8000
serInPtr        .EQU     serBuf+SER_BUFSIZE
serRdPtr        .EQU     serInPtr+2
serBufUsed      .EQU     serRdPtr+2
basicStarted    .EQU     serBufUsed+1
TEMPSTACK       .EQU     $80ED ; Top of BASIC line input buffer so is "free ram" when BASIC resets

LCD_A		=    $80EE

LCD_BUFFER_POINT    =   $80F1
LCD_DELETE_CHAR     =   $80F2 ; start 0, if delete = ff

LCD_BUFFER          =   $8100
LCD_BUFFER_END      =   $8150

LCD_BUFFER_SIZE     =   $50 ;   0 - 80


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

                IN       A,(porta)

                call delay  ; esse precisa para nao pegar varias vezes o mesmo char, ajustar

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

                LD       (serRdPtr),HL
                LD       A,(serBufUsed)
                DEC      A
                LD       (serBufUsed),A
                CP       SER_EMPTYSIZE
                JR       NC,rts1

rts1:
                LD       A,(HL)
                EI
                POP      HL
                RET                      ; Char ready in A

;------------------------------------------------------------------------------
TXA:            
				; CHAR IN A
                ; out (2), a    ; debug
ver_enter:       

                ; trata dados para o lcd
                CP      $0D                     ; compara com ENTER
                jr      nz, ver_limpa

                call    shift_lcd_up
                call    show_lcd_screen
                RET

ver_limpa:
                CP      $0C                     ; compara com limpar tela
                jr      NZ, ver_line
                
                call    clear_lcd_screen
                call    show_lcd_screen
                RET

ver_line:
                CP      $0A                     ; retorna começo da linha
                jr      NZ, print_lcd      

                    ;----- verificar se precisa add algo aqui
                ;call    shift_lcd_up
                ;call    show_lcd_screen
                RET   

print_lcd:
                call    print_to_lcd_screen
                call    show_lcd_screen

                RET



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
;   INIT AFTER RESET
;------------------------------------------------------------------------------
INIT:

               LD        HL,TEMPSTACK    ; Temp stack
               LD        SP,HL           ; Set up a temporary stack
               LD        HL,serBuf
               LD        (serInPtr),HL
               LD        (serRdPtr),HL
               XOR       A               ;0 to accumulator
               LD        (serBufUsed),A
               call      lcd_init            ; init hardware
               call      init_lcd_screen    ; init logical

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
               JP        $0390           ; Start BASIC COLD
CHECKWARM:
               CP        'W'
               JR        NZ, CORW
               RST       08H
               LD        A,$0D
               RST       08H
               LD        A,$0A
               RST       08H
               JP        $0393           ; Start BASIC WARM
              
SIGNON1:       
               .BYTE     "Z80 - Diego Cruz",CR,LF,0
SIGNON2:       
               .BYTE     "(C)old or (W)arm? ",0

















; =======================================================================
;
;                        DISPLAY LOGICO
;
; =======================================================================

; =======================================================================
; Inicia LCD screen
; =======================================================================
init_lcd_screen:
        PUSH    AF
        LD      A, $0
        LD      (LCD_DELETE_CHAR), A
        LD      (LCD_BUFFER_POINT), A       ; reset pointer buffer to zero
        call    clear_lcd_screen
        call    show_lcd_screen
        POP     AF
        RET


; =======================================================================
; Limpa buffer
; =======================================================================
clear_lcd_screen:
        PUSH    AF
        PUSH    HL
        LD      HL, LCD_BUFFER
        LD      A,  LCD_BUFFER_SIZE
clear_lcd_loop:
        LD      (HL), $1B           ; char espace
        INC     HL
        DEC     A
        CP      $00
        JR      NZ, clear_lcd_loop

        POP     HL
        POP     AF

        RET

; =======================================================================
; Shift buffer  "enter"
; =======================================================================
shift_lcd_up:
        PUSH    AF
        PUSH    HL
        PUSH    DE

        LD      HL, LCD_BUFFER
        LD      A, (LCD_BUFFER_POINT)
        LD      L, A
        LD      (HL), $1B

        LD      A, $00
        LD      (LCD_BUFFER_POINT), A   ; zera buffer size max 20 - LCD 20x4
        
        LD      HL, LCD_BUFFER_END-$28 ; buffer end menos 40 - source
        LD      DE, LCD_BUFFER_END-$14 ; buffer end menos 20 - destination

        LD      A, $14                 ; A contem size of line
copy_line2_to1:
        PUSH    AF
        LD      A, (HL)
        LD      (DE), A
        POP     AF
        inc     HL
        inc     DE
        dec     A
        CP      $00
        JR      NZ, copy_line2_to1

        LD      HL, LCD_BUFFER_END-$3C ; buffer end menos 60 - source
        LD      DE, LCD_BUFFER_END-$28 ; buffer end menos 40 - destination

        LD      A, $14                 ; A contem size of line
copy_line3_to2:
        PUSH    AF
        LD      A, (HL)
        LD      (DE), A
        POP     AF
        inc     HL
        inc     DE
        dec     A
        CP      $00
        JR      NZ, copy_line3_to2

        LD      HL, LCD_BUFFER_END-$50 ; buffer end menos 80 - source
        LD      DE, LCD_BUFFER_END-$3C ; buffer end menos 60 - destination

        LD      A, $14                 ; A contem size of line
copy_line4_to3:
        PUSH    AF
        LD      A, (HL)
        LD      (DE), A
        POP     AF
        inc     HL
        inc     DE
        dec     A
        CP      $00
        JR      NZ, copy_line4_to3

;------- limpa line 4
        LD      HL, LCD_BUFFER
        LD      A,  $14 ; 20
limpa_line4:
        LD      (HL), $1B           ; char espace
        INC     HL
        DEC     A
        CP      $00
        JR      NZ, limpa_line4

        POP     DE
        POP     HL
        POP     AF

        RET

; =======================================================================
; FUNCAO PARA PRINTAR A CHAR IN A
; =======================================================================
print_to_lcd_screen:
    ; char in register A
    PUSH    HL
    PUSH    AF  ; guarda char

    LD      A, (LCD_DELETE_CHAR)
    CP      $FF         ; delete char in screen
    JP      NZ, check_is_delete

    ; delete char
    LD      A, (LCD_BUFFER_POINT)
    dec     A
    LD      (LCD_BUFFER_POINT), A
    LD      HL, LCD_BUFFER
    LD      L, A
    LD      (HL), $1B           ; char espace

    INC     HL                  ; coloca _ para mostrar onde esta o cursor
    LD      (HL), $1B           ; coloca _ para mostrar onde esta o cursor

    LD      A, $0
    LD      (LCD_DELETE_CHAR), A

    DEC     HL           ; coloca _ para mostrar onde esta o cursor
    LD      A, '_'       ; coloca _ para mostrar onde esta o cursor
    LD      (HL), A      ; coloca _ para mostrar onde esta o cursor

    POP     AF
    POP     HL
    RET



check_is_delete:
    POP     AF
    PUSH    AF
    CP      $00          ; if $0, delete next char
    JP      NZ, continue_print
    LD      A, (LCD_BUFFER_POINT)
    CP      $0
    JP      Z, continue_print
    LD      A, $FF
    LD      (LCD_DELETE_CHAR), A
    POP     AF
    POP     HL
    RET


continue_print:
    LD      A,  (LCD_BUFFER_POINT)
    CP      $14 ; 20
    call    Z,  shift_lcd_up

    LD      HL, LCD_BUFFER

    LD      A, (LCD_BUFFER_POINT)
    LD      L, A

    POP     AF  ; recupera char in A
    LD      (HL),  A
    INC     HL
    LD      A, L
    LD      (LCD_BUFFER_POINT), A

    LD      A, '_'       ; coloca _ para mostrar onde esta o cursor
    LD      (HL), A      ; coloca _ para mostrar onde esta o cursor

    POP     HL

    RET

; =======================================================================
; Show buffer to LCD Display
; =======================================================================
show_lcd_screen:
        PUSH    AF
        PUSH    HL
        LD      HL, LCD_BUFFER

        LD      A, lcd_line4
        call lcd_send_command

print_line4:
        LD      A, (HL)
        call    lcd_send_data
        LD      A, L
        inc     A
        inc     HL
        CP      $14 ; 20
        JR      NZ, print_line4

        ;  vai para linha 3
        LD      A, lcd_line3
        call    lcd_send_command
print_line3:
        LD      A, (HL)
        call    lcd_send_data
        LD      A, L
        inc     A
        inc     HL
        CP      $28 ; 40
        JR      NZ, print_line3

        ;   vai para a linha 2
        LD      A, lcd_line2
        call    lcd_send_command
print_line2:
        LD      A, (HL)
        call    lcd_send_data
        LD      A, L
        inc     A
        inc     HL
        CP      $3C ; 60
        JR      NZ, print_line2

        ;   vai para a linha 1
        LD      A, lcd_line1
        call    lcd_send_command
print_line1:
        LD      A, (HL)
        call    lcd_send_data
        LD      A, L
        inc     A
        inc     HL
        CP      $50 ; 80
        JR      NZ, print_line1

        POP     HL
        POP     AF
        RET















;***************************************************************************
;
;	                   LCD Display 20x4 - Hardware
;
;***************************************************************************
en	= 01h
rw	= 02h
rs	= 04h

; commands
lcd_line1	=	$80
lcd_line2	=	$C0
lcd_line3	=	$94
lcd_line4	=	$D4

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
	push bc                          ; 2.75 us
	ld c, 55                         ; 1.75 us
lcd_delay_loop:
	dec c                            ; 1 us
    jp nz, lcd_delay_loop            ; true = 3 us, false 1.75 us
    pop bc                           ; 2.50 us
    ret                              ; 2.50 us

;***************************************************************************
;	lcd_init:
;	Function: Init display lcd 16x2
;***************************************************************************
lcd_clear:
    push af
    ld a, 01h 				; limpa lcd
    call lcd_send_command
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
    
    ;ld a, 0Eh 				; Display on, cursor blinking 
    ld  a, 0Ch              ; Display on, cursor off
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
