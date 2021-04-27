/*****************************
  NESTOR - aplicativo demo 2
    Revista 86 - Abril/84
  Exibe uma frase com rolagem

        Digitado por
      Fábio Belavenuto
       em 12/12/2013

     Compilar com SJASM
*****************************/

	output	app2.bin
	defpage	0, 2000h, *
	
	page 0

	include	"../monitor/defs.inc"
	include	"../monitor/nestor.inc"

delay	= 32

	code @ 2000h

inicio:
	ld		bc, mensagem		// endereco inicial buffer mensagem do display
L2:
	ld		d, delay			// fixa tempo (velocidade avanco display)
	inc		bc					// avanca buffer da mensagem
	ld		a, c				// carrega A com final do buffer
	cp		LOW fim_msg			// compara com final da mensagem
	jp z,	inicio				// recicla, se chegou ao fim
L1:
	ld		h, b				// carrega HL com indicador do buffer p/ utilizar rotina de restauracao
	ld		l, c				//
	push	bc					// salva par BC
	call	REST				// chama rotina p/ display
	pop		bc					// restaura BC
	dec		d					// decrementa a constante de tempo
	jp nz,	L1					// nao sendo zero, continua na mensagem
	jp		L2					// sendo zero, evolui de 1 digito

mensagem:
	db		DIG_APAG, DIG_APAG, DIG_APAG, DIG_APAG, DIG_APAG, DIG_APAG	// 6 caracteres apagados
	db		DIG_E, DIG_U												// "EU"
	db		DIG_APAG, DIG_APAG											// 2 apagados
	db		DIG_S, DIG_O, DIG_U											// "SOU"
	db		DIG_APAG, DIG_APAG											// 2 apagados
	db		DIG_N, DIG_E, DIG_S, DIG_T, DIG_O, DIG_R					// "NESTOR"
	db		DIG_APAG
fim_msg:
	db		DIG_APAG, DIG_APAG, DIG_APAG, DIG_APAG, DIG_APAG			// 1 + 5 = 6 apagados
