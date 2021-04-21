; Teclado e led
; 
; Diego Cruz - Abril 2021

porta	= 01h
portb	= 02h
en	= 01h
rw	= 02h
rs	= 04h

.org 0


; setup lcd 16x2
	; ++ CLEAR LCD ++ 

	ld	a,00000001b	;envia byte 01h para o acc
	out	(portb),a	;carrega acc no portb
	ld	a,00h		;envia byte 00h para o acc
	out	(porta),a	;carrega acc no porta
	ld	a,en		;envia bit de enable para o acc
	out	(porta),a	;carrega en no porta
	ld	a,00h		;envia byte 00h para o acc
	out	(porta),a	;carrega acc no porta

	; ++ MODO de 8 BITS ++

	ld	a,00111000b	;envia byte 38h para o acc
	out	(portb),a	;carrega acc no portb
	ld	a,00h		;envia byte 00h para o acc
	out	(porta),a	;carrega acc no porta
	ld	a,en		;envia bit de enable para o acc
	out	(porta),a	;carrega en no porta
	ld	a,00h		;envia byte 00h para o acc
	out	(porta),a	;carrega acc no porta
 
	; ++ LIGA LCD, LIGA CURSOR, DESLIGA BLINK ++

	ld	a,00001110b	;envia byte 0Eh para o acc
	out	(portb),a	;carrega acc no portb
	ld	a,00h		;envia byte 00h para o acc
	out	(porta),a	;carrega acc no porta
	ld	a,en		;envia bit de enable para o acc
	out	(porta),a	;carrega en no porta
	ld	a,00h		;envia byte 00h para o acc
	out	(porta),a	;carrega acc no porta

	; ++ HABILITA INCREMENTO E DESLIGA SCROLL ++

	ld	a,00000110b	;envia byte 06h para o acc
	out	(portb),a	;carrega acc no portb
	ld	a,00h		;envia byte 00h para o acc
	out	(porta),a	;carrega acc no porta
	ld	a,en		;envia bit de enable para o acc
	out	(porta),a	;carrega en no porta
	ld	a,00h		;envia byte 00h para o acc
	out	(porta),a	;carrega acc no porta
    
    
    ;; PROGRAMA PRINCIPAL
    
    ld a, 0 ; teste
	ld (8000H), a
	
	ld a, 0 ; teste
	ld (8001H), a
	
	ld a, 0 ; teste
	ld (8002H), a
	
	ld a, 0 ; teste
	ld (8003H), a
    
    ld a, 0 ; teste
	ld (8004H), a
    
    ld a, 0 ; status dos leds
    ld (8005H), a


	ld hl, 8000H
	
	
inicio:
	; ++ CLEAR LCD ++ 

	ld	a,00000001b	;envia byte 01h para o acc
	call send_command
    
    
	ld a, (8000H)
    cp 0
    call z, desliga_led1
    call nz, liga_led1
    ld a, (8000H)
    add a, 48
    call send_lcd
    
    ld a, (8001H)
    cp 0
    call z, desliga_led2
    call nz, liga_led2
    ld a, (8001H)
    add a, 48
    call send_lcd
    
    ld a, (8002H)
    cp 0
    call z, desliga_led3
    call nz, liga_led3
    ld a, (8002H)
    add a, 48
    call send_lcd
    
    ld a, (8003H)
    cp 0
    call z, desliga_led4
    call nz, liga_led4
    ld a, (8003H)
    add a, 48
    call send_lcd
    
    ld a, (8004H)
    cp 0
    call z, desliga_led5
    call nz, liga_led5
    ld a, (8004H)
    add a, 48
    call send_lcd
    
    ld a, 80h
    call send_command
    
    ; Ajusta a posicao do cursor
    ld a, L
    ld (8010h), a
    nop
    nop
ajuste_cursor:
	ld a, (8010h)
    cp 0
	jp z, inicio_loop
    dec a
    ld (8010h), a
    nop
    nop
    ld a, 14h
    call send_command
    nop
    jp ajuste_cursor

inicio_loop:
	ld a, (8005h)
    out (porta), a
    call delay
    call delay
    call delay
    
loop:
	
	in a, (1)
	bit 0, a ;up
	jp z, pr0
	
	bit 2, a ; down
	jp z, pr1
	
	bit 1, a ; right
	jp z, pr2
	
	bit 3, a ; left
	jp z, pr3
    
	
	jp loop
	
pr0:
	ld a, (HL)
	inc a
	ld (HL), a
	jp inicio
	
pr1:
	ld a, (HL)
	dec a
	ld (HL), a
    
	jp inicio
	
pr2:
	ld a, L
	inc a
	ld L, a
	jp inicio
	
pr3:
	ld a, L
	dec a
	ld L, a

	jp inicio
    
    

liga_led1:
	ld a, (8005H)
    set 7, a
    ld (8005H), a
    ret
    

desliga_led1:
	ld a, (8005H)
    res 7, a
    ld (8005H), a
    ret
    
    
    
liga_led2:
	ld a, (8005H)
    set 6, a
    ld (8005H), a
    ret
    

desliga_led2:
	ld a, (8005H)
    res 6, a
    ld (8005H), a
    ret
    
    
liga_led3:
	ld a, (8005H)
    set 5, a
    ld (8005H), a
    ret
    

desliga_led3:
	ld a, (8005H)
    res 5, a
    ld (8005H), a
    ret
    
liga_led4:
	ld a, (8005H)
    set 4, a
    ld (8005H), a
    ret
    

desliga_led4:
	ld a, (8005H)
    res 4, a
    ld (8005H), a
    ret
    
    
liga_led5:
	ld a, (8005H)
    set 3, a
    ld (8005H), a
    ret
    

desliga_led5:
	ld a, (8005H)
    res 3, a
    ld (8005H), a
    ret
    
    
delay:
	ld b, 0FFh
loop_delay:
	dec b
    jp nz, loop_delay
    ret
    
send_command:
	out	(portb),a	;carrega acc no portb
	ld	a,00h		;envia byte 00h para o acc
	out	(porta),a	;carrega acc no porta
    ld a, (8005h)
	or	en		;envia bit de enable para o acc
	out	(porta),a	;carrega en no porta
    ld a, (8005h)
	or 00h		;envia byte 00h para o acc
	out	(porta),a	;carrega acc no porta
    ret

send_lcd:
	out	(portb),a	;carrega acc no portb
    ld a, (8005h)
	or rs		;envia bit de rs para o acc
	out	(porta),a	;carrega acc no porta
    ld a,(8005h)
	or en|rs		;envia bit de en com rs para o acc
	out	(porta),a	;carrega acc no porta
    ld a, (8005h)
	or	rs		;envia bit de rs para o acc
	out	(porta),a	;carrega acc no porta
    ret

