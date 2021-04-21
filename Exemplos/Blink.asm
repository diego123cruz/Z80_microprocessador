; Blink
; 
; Diego Cruz - Abril 2021

.org 0

#define porta 1

    ld a, 80h
loop:
    out (porta), a
    xor 80h

; Delay
    ld b, 0FFh				
loop_delay:	
	dec b					
    jp nz, loop_delay		
    jp loop		 	