; ShiftLeft
; 
; Diego Cruz - Abril 2021

.org 0

#define porta 1

inicio:
    ld a, 08h
loop:
    out (porta), a
    call delay
    bit 7, a
    jp nz, inicio
    rlca
    jp loop

; Delay
delay:
    ld b, 0FFh				
loop_delay:	
	dec b					
    jp nz, loop_delay		
    ret	 	