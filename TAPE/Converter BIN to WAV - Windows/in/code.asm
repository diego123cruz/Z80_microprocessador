	output	out/code.bin
	defpage	0, 8000h, *
	
	page 0

	code @ 8000h

	call $000a 		; clear display
    
    ld hl,GAY
    call $000e
    halt
    
    
GAY:
	db "GAY!!!", $ff




inicio:
	ld a, $80
loop:
	out (2), a
    rrc a
    call $0006 ; delay
	jp c, back
    jp loop
back:
	ld a, $01
loop2:
	out (2), a
	rlc a
    call $0006 ; delay
	jp c, inicio
    jp loop2