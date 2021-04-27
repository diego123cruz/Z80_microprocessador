/*****************************
  NESTOR - aplicativo demo 1
    Revista 86 - Abril/84
 Exibe uma mensagem constante

        Digitado por
      Fábio Belavenuto
       em 12/12/2013

     Compilar com SJASM
*****************************/

	output	app1.bin
	defpage	0, 2000h, *
	
	page 0

	include	"../monitor/defs.inc"
	include	"../monitor/nestor.inc"

	code @ 2000h

inicio:
	ld		hl, palavra
	call	REST
	jp		inicio

palavra:
	db		DIG_N, DIG_E, DIG_S, DIG_T, DIG_O, DIG_R

