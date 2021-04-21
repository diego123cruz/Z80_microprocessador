; Diego Cruz
; Abril - 2021
; Blink


; ---------------- Outputs - Port -----------------
porta		= 01h 	; in/out
portb		= 02h	; out

;----------------- Buttons - bit ------------------
btnUp		= 0
btnRight	= 1
btnDown		= 2
btnLeft		= 3
btnCenter	= 4

; --------------- Memory Map ----------------------
delayButtonRead = 8000h
delayTimer		= 8001h
delayTmp		= 8002h
portaStatus		= 8003h

; --------------- Code ----------------------------

.org 0

	ld a, 10				
    ld (delayTimer), a		
    ld (delayButtonRead) , a
    ld a, 00001000b
    ld (portaStatus), a
main_loop:
	ld a, (portaStatus) 	
    out (porta), a 			
    xor 00001000b
    ld (portaStatus), a
    call delay
    jp main_loop
    
delay:
	ld a, (delayTimer)
    ld (delayTmp), a
loop_delay:
	call read_keys
	ld a, (delayTmp)
	dec a
    ld (delayTmp), a
    jp nz, loop_delay
    ret
    
read_keys:
	ld a, (delayButtonRead)
    dec a
    ld (delayButtonRead), a
    ret nz
    ld a, 100
    ld (delayButtonRead), a
    in a, (porta)
    bit btnUp, a
    jp z, up
    bit btnDown, a
    jp z, down
    ret
    
up:
	ld a, (delayTimer)
    inc a
    ld (delayTimer), a
    jp main_loop
    
down:
	ld a, (delayTimer)
    dec a
    ld (delayTimer), a
    jp main_loop