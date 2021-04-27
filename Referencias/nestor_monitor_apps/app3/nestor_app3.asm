/*****************************
  NESTOR - aplicativo demo 3
    Revista 86 - Abril/84
   Conta de 1 a 9  e exibe
      no último display

        Digitado por
      Fábio Belavenuto
       em 12/12/2013

     Compilar com SJASM
*****************************/

	output	app3.bin
	defpage	0, 2000h, *
	
	page 0

	include	"../monitor/defs.inc"
	include	"../monitor/nestor.inc"

delay	= 32

	code @ 2000h

inicio:
	ld		hl, buffer
a1:
	ld		(hl), DIG_APAG
	inc		hl
	ld		a, l
	cp		LOW (buffer + 6)
	jp nz,	a1
a2:
	ld		hl, mencon
	ld		(hl), 0
a4:
	ld		hl, mencon
	inc		(hl)
	ld		d, delay
	ld		a, (hl)
	cp		10
	jp z,	a2
	call	FORMAT
	ld		hl, dig6
	ld		(hl), a
a3:
	ld		hl, buffer
	call	REST
	dec		d
	jp nz,	a3
	jp		a4

buffer:
	ds		5
dig6:
	ds		1
mencon:
	ds		1
