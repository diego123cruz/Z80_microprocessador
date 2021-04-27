/***************************************

       PROGRAMA MONITOR NESTOR
           NOVA ELETRONICA
    SAO PAULO S.P. 01/84 MSCS/JRP

            Digitado por
          Fábio Belavenuto
            em 27/11/2012

***************************************/

/*******************
  NOVA ELETRONICA
 INTERFACE CASSETE
   MICRO NESTOR

   Digitado por
 Fábio Belavenuto
  em 15/04/2013

********************/

/**********************************

 Firmware do Nestor+ fabricado por
 Victor Trucco @ 2013

 Contém o código do monitor em 0000h
 e o código da interface K7 em 0800h

 Alguns bugs dos códigos foram
 corrigidos, que vieram com erros
 na listagem original das revistas

 Montar com o assembler SJASM

***********************************/

	output NESTOR.ROM
	defpage 0,0000h,4096
	page 0

	include "defs.inc"

/*        MONITOR          */

	code @ 0000h

RESET:
		ld		sp, PILHAI
		push	bc
		push	de
		push	hl
		push	af
		ld		hl, FLAG
		ld		(hl), 19h
		ld		hl, MENS
		ld		de, BUFDIS
		ld		bc, 6
		ldir
INICIO:
		ld		sp, PILHAT
		ld		hl, BUFDIS
		ld		b, 0
		ld		e, 6
		ld		a, 1
NE1:
		call	VARR
		ld		a, c
		add		a, a
		dec		e
		jp		nz, NE1
		ld		a, b
		cp		0
		jp		z, INICIO
NE2:
		ld		hl, BUFDIS
		call	REST
		ld		a, d
		out		(PDIG), a
		in		a, (PTEC)
		cp		0
		jp		nz, NE2
		call	AJCOL
		call	AJTEC
		cp		KEY_QUAD
		jp		nz, P1
		jp		K7
P1:
		cp		KEY_ER
		jp		z, NE3
		cp		KEY_PERM
		jp		c, NE4
NE5:
		call	ALTCOM
NE6:
		ld		hl, FLAG
		ld		a, (hl)
		jp		RECCOM

/***************************************
  PONTO DE ENTRADA DE INTERRUPCAO NMI
***************************************/

	code @ 66h

		jp		ROTINT

MENS:
		db		DIG_N, DIG_E, DIG_S, DIG_T, DIG_O, DIG_R

RECCOM:
		ld		hl, TABCOM
		add		a, l
		ld		l, a
		ld		a, (hl)
		ld		c, a
		ld		a, 0Ah
		add		a, l
		ld		l, a
		ld		l, (hl)
		ld		h, c
		jp		(hl)
NE3:
		ld		hl, FLAG
		ld		a, (hl)
		cp		15h
		jp		z, SELREG
		jp		NE5
NE4:
		ld		hl, FLAG
		ld		a, (hl)
		cp		15h
		jp		z, ALTREG
		nop
		jp		NE6

/****************************************
          ROTINA DE VARREDURA
***************************************/

VARR:
		ld		c, a
		call	TEMPO
		in		a, (PTEC)
		cp		0
		ret		z
		ld		b, a
		ld		d, c
		ret

/***************************************
         ROTINA DE RESTAURACAO
***************************************/

REST:
		ld		c, 6
		ld		a, 1
NE7:
		call	TEMPO
		add		a, a
		dec		c
		ret		z
		jp		NE7

/***************************************
            ROTINA DE TEMPO
***************************************/

TEMPO:
		push	af
		out		(PDIG), a
		ld		a, (hl)
		out		(PSEG), a
		exx
		ld		de, ATRASO
LOOP1:
		dec		de
		ld		a, d
		or		e
		jp		nz, LOOP1
		exx
		inc		hl
		pop		af
		ret

/***************************************
      ROTINA DE AJUSTE DE COLUNA
***************************************/

AJCOL:
		ld		c, 0
		ld		a, 1
		cp		d
		jp		z, NE8
		add		a, a
		ld		c, 8
		cp		d
		jp		z, NE8
		add		a, a
		ld		c, 10h
		cp		d
		jp		z, NE8
		jp		INICIO
NE8:
		ld		d, c
		ret

/***************************************
      ROTINA DE AJUSTE DE TECLA
***************************************/

AJTEC:
		ld		e, 8
		ld		c, 0
		ld		a, 1
NE10:
		cp		b
		jp		z, NE9
		inc		c
		add		a, a
		dec		e
		jp		nz, NE10
		jp		INICIO
NE9:
		ld		a, c
		add		a, d
		ld		b, a
		nop
		ret

/***************************************
       ROTINA DE ALTERAR COMANDO
***************************************/

ALTCOM:
		ld		hl, FLAG
		ld		(hl), b
		ret

/***************************************
           ROTINA DE PERMISSAO
***************************************/

ROTPER:
		ld		c, 6
		ld		hl, FLAG
		ld		(hl), 17h
		ld		hl, BUFDIS
NE11:
		ld		(hl), DIG_APAG
		inc		hl
		dec		c
		jp		nz, NE11
		ld		(hl), 0
		inc		hl
		ld		(hl), 0
		inc		hl
		ld		(hl), 0
		jp		INICIO

/***************************************
     ROTINA DE CAMPO DE ENDERECOS
***************************************/

ROTCP:
		ld		hl, PBE
		ld		a, b
		rld
		inc		hl
		rld
		call	DECOD
		jp		INICIO

/***************************************
           ROTINA DE LEITURA
***************************************/

ROTLT:
		call	ATUAL
		ld		hl, FLAG
		ld		(hl), 18h
		ld		hl, PAE
		call	DECOD
		jp		INICIO

/***************************************
        ROTINA DE CAMPO DE DADOS
***************************************/

ROTCD:
		call	ATUAL
		ld		a, b
		rld
		ld		a, (hl)
		ld		(de), a
		ld		hl, PAE
		call	DECOD
		jp		INICIO

/***************************************
         ROTINA DE ATUALIZACAO
***************************************/

ATUAL:
		ld		hl, PBE
		ld		e, (hl)
		inc		hl
		ld		d, (hl)
		ld		a, (de)
		dec		hl
		dec		hl
		ld		(hl), a
		push	hl
		ld		hl, FLAG
		ld		(hl), 18h
		pop		hl
		ret

/***************************************
        ROTINA DE DECODIFICACAO
***************************************/

DECOD:
		ld		bc, BUFDIS
		call	DISPLAY
		dec		hl
		call	DISPLAY
		dec		hl
		call	DISPLAY
		ret

/***************************************
  ROTINA DE AJUSTE MEMORIA DE ENDERECO
***************************************/

RAME:
		ld		hl, PBE
		ld		(hl), e
		inc		hl
		ld		(hl), d
		dec		hl
		dec		hl
		ld		a, (de)
		ld		(hl), a
		ret

		db		0FFh, 0FFh

/***************************************
           ROTINA DE DISPLAY
***************************************/

DISPLAY:
		ld		a, (hl)
		push	hl
		ld		hl, ROT
		ld		(hl), a
		xor		a
		rld
		call	FORMAT
		ld		(bc), a
		inc		bc
		xor		a
		rld
		call	FORMAT
		ld		(bc), a
		inc		bc
		pop		hl
		ret

/***************************************
         ROTINA DE FORMATACAO
***************************************/

FORMAT:
		push	de
		ld		de, INTD
		add		a, e
		ld		e, a
		ld		a, (de)
		pop		de
		ret

/***************************************
       TABELA DE FORMATOS ALFA
***************************************/

INTD:
		db		DIG_0, DIG_1, DIG_2, DIG_3, DIG_4, DIG_5, DIG_6, DIG_7
		db		DIG_8, DIG_9, DIG_A, DIG_B, DIG_C, DIG_D, DIG_E, DIG_F

/***************************************
           ROTINA DE PROXIMO
***************************************/

ROTPR:
		call	ATUAL
		inc		de
		call	RAME
		ld		hl, PAE
		call	DECOD
		jp		INICIO

/***************************************
           ROTINA DE ULTIMO
***************************************/

ROTUL:
		call	ATUAL
		dec		de
		call	RAME
		ld		hl, PAE
		call	DECOD
		jp		INICIO

		ds		3, 0FFh					// 01C5 à 01C7 - NAO USADAS

/***************************************
            ROTINA DE RODAR
***************************************/

ROTRD:
		ld		a, 0FFh
		out		(PDIG), a
		ld		a, DIG_PONTO
		out		(PSEG), a
		ld		hl, ENDISP
		ld		(hl), 0C3h
		ld		sp, PILHARR
		push	af
		push	hl
		push	de
		push	bc
		ld		sp, PILHAT
		jp		ENDISP

/***************************************
    ROTINA DE EXAME DE REGISTRADORES
***************************************/

ROTER:
		ld		hl, MENCON
		ld		(hl), 0FEh
		jp		SELREG

/***************************************
        ROTINA DE INICIALIZACAO
***************************************/

INICIAL:
		ld		hl, BUFDIS
		ld		(hl), DIG_APAG
		inc		hl
		ld		(hl), DIG_APAG
		inc		hl
		ret

/***************************************
   ROTINA DE SELECAO DE REGISTRADORES
***************************************/

SELREG:
		ld		de, TABREG
		ld		hl, MENCON
		inc		(hl)
		inc		(hl)
		ld		a, e
		add		a, (hl)
NE12:
		ld		e, a
		ld		a, (de)
		ld		l, a
		inc		de
		ld		a, (de)
		ld		h, a
		jp		(hl)

/***************************************
  ROTINA DE ALTERACAO DE REGISTRADORES
***************************************/

ALTREG:
		ld		hl, MENCON
		ld		de, TABALT
		ld		a, e
		add		a, (hl)
		jp		NE12

/***************************************
             REGISTRADOR A
***************************************/

REGA:
		call	INICIAL
		ld		(hl), DIG_A
		inc		hl
		ld		(hl), DIG_IGUAL
		ld		hl, MENA
		jp		ROTSA

/***************************************
            ROTINA DE SAIDA
***************************************/

ROTSA:
		ld		bc, BYTE5
		call	DISPLAY
		jp		INICIO

/***************************************
          ALTERA REGISTRADOR A
***************************************/

ALTA:
		ld		hl, MENA
		ld		a, b
		rld
		jp		ROTSA

/***************************************
             REGISTRADOR B
***************************************/

REGB:
		call	INICIAL
		ld		(hl), DIG_B
		inc		hl
		ld		(hl), DIG_IGUAL
		ld		hl, MENB
		jp		ROTSA

/***************************************
          ALTERA REGISTRADOR B
***************************************/

ALTB:
		ld		hl, MENB
		ld		a, b
		rld
		jp		ROTSA

/***************************************
             REGISTRADOR C
***************************************/

REGC:
		call	INICIAL
		ld		(hl), DIG_C
		inc		hl
		ld		(hl), DIG_IGUAL
		ld		hl, MENC
		jp		ROTSA

/***************************************
          ALTERA REGISTRADOR C
***************************************/

ALTC:
		ld		hl, MENC
		ld		a, b
		rld
		jp		ROTSA

/***************************************
             REGISTRADOR D
***************************************/

REGD:
		call	INICIAL
		ld		(hl), DIG_D
		inc		hl
		ld		(hl), DIG_IGUAL
		ld		hl, MEND
		jp		ROTSA

/***************************************
          ALTERA REGISTRADOR D
***************************************/

ALTD:
		ld		hl, MEND
		ld		a, b
		rld
		jp		ROTSA

/***************************************
             REGISTRADOR E
***************************************/

REGE:
		call	INICIAL
		ld		(hl), DIG_E
		inc		hl
		ld		(hl), DIG_IGUAL
		ld		hl, MENE
		jp		ROTSA

/***************************************
          ALTERA REGISTRADOR E
***************************************/

ALTE:
		ld		hl, MENE
		ld		a, b
		rld
		jp		ROTSA

/***************************************
             REGISTRADOR H
***************************************/

REGH:
		call	INICIAL
		ld		(hl), DIG_H
		inc		hl
		ld		(hl), DIG_IGUAL
		ld		hl, MENH
		jp		ROTSA

/***************************************
          ALTERA REGISTRADOR H
***************************************/

ALTH:
		ld		hl, MENH
		ld		a, b
		rld
		jp		ROTSA

/***************************************
             REGISTRADOR L
***************************************/

REGL:
		call	INICIAL
		ld		(hl), DIG_L
		inc		hl
		ld		(hl), DIG_IGUAL
		ld		hl, MENL
		jp		ROTSA

/***************************************
          ALTERA REGISTRADOR L
***************************************/

ALTL:
		ld		hl, MENL
		ld		a, b
		rld
		jp		ROTSA

/***************************************
             REGISTRADOR F
***************************************/

REGF:
		call	INICIAL
		ld		(hl), DIG_F
		inc		hl
		ld		(hl), DIG_IGUAL
		ld		hl, MENF
		jp		ROTSA

/***************************************
          ALTERA REGISTRADOR F
***************************************/

ALTF:
		ld		hl, MENF
		ld		a, b
		rld
		jp		ROTSA

/***************************************
             REGISTRADOR I
***************************************/

REGI:
		ld		a, i
		ld		hl, MENI
		ld		(hl), a
		call	INICIAL
		ld		(hl), DIG_I
		inc		hl
		ld		(hl), DIG_IGUAL
		ld		hl, MENI
		jp		ROTSA

/***************************************
          ALTERA REGISTRADOR I
***************************************/

ALTI:
		ld		hl, MENI
		ld		a, b
		rld
		ld		a, (hl)
		ld		i, a
		jp		ROTSA

/***************************************
   ROTINA PARA O VETOR DE INTERRUPCAO
***************************************/

RIV:
		ld		bc, ROTINT
		ld		a, 0C3h
		ld		(bc), a
		inc		bc
		ld		hl, PBE
		ld		a, (hl)
		ld		(bc), a
		inc		bc
		inc		hl
		ld		a, (hl)
		ld		(bc), a
		jp		INICIO

/***************************************
  TABELA PARA SELECAO DE REGISTRADORES
***************************************/

TABREG:
		dw		REGA
		dw		REGB
		dw		REGC
		dw		REGD
		dw		REGE
		dw		REGH
		dw		REGL
		dw		REGF
		dw		REGI
		dw		JR
JR:
		jp		ROTER

/***************************************
  TABELA DE ALTERACAO DE REGISTRADORES
***************************************/

TABALT:
		dw		ALTA
		dw		ALTB
		dw		ALTC
		dw		ALTD
		dw		ALTE
		dw		ALTH
		dw		ALTL
		dw		ALTF
		dw		ALTI
		ds		3, 0FFh

/***************************************
     TABELA DE SELECAO DE COMANDOS
***************************************/

TABCOM:
		ds		16, 0
		db		high ROTPER, high ROTLT, high ROTUL, high ROTPR, high ROTRD, high ROTER, high RIV, high ROTCP, high ROTCD, high INICIO
		db		 low ROTPER,  low ROTLT,  low ROTUL,  low ROTPR,  low ROTRD,  low ROTER,  low RIV,  low ROTCP,  low ROTCD,  low INICIO
		ds		229, 0



/*********************************************
        ROTINA DE LEITURA DE CASSETE
**********************************************/

	code @ 0800h
K7:
		ld		a, 0
		ld		(CONT), a
		ld		hl, TITULO
NEC1:
		ld		de, DISP
		ld		bc, 6
		ldir
NEC2:
		ld		hl, DISP
		ld		b, 0
		ld		e, 6
		ld		a, 1
NEC3:
		call	VARR
		ld		a, c
		add		a, a
		dec		e
		jr		nz, NEC3
		ld		a, b
		cp		0
		jr		z, NEC2
NEC4:
		ld		hl, DISP
		call	REST
		ld		a, d
		out		(PDIG), a
		in		a, (PTEC)
		cp		0
		jr		nz, NEC4
		call	AJCOL
		call	AJTEC
		cp		KEY_RUN
		jp		z, GO
		cp		KEY_PERM
		jr		c, NEC5
		cp		KEY_1P
		jr		z, NEC6
		jp		NEC2
NEC6:
		ld		a, (CONT)
		cp		0
		jp		z, LFITA
		rst		0
NEC5:
		ld		a, (CONT)
		cp		0
		jr		z, FILE
		cp		1
		jr		z, FONTE
		cp		2
		jr		z, FINAL
		rst		0
GO:
		ld		a, (CONT)
		cp		0
		jr		z, FONTE1
		cp		1
		jr		z, FINAL1
		cp		2
		jr		z, GFITA
		rst		0
FONTE1:
		ld		hl, MFONTE
		ld		a, 1
		ld		(CONT), a
		jp		NEC1
FINAL1:
		ld		hl, MFINAL
		ld		a, 2
		ld		(CONT), a
		jp		NEC1
FILE:
		ld		hl, BUF
		jr		GERAL
FONTE:
		ld		hl, BUF+2
		jr		GERAL
FINAL:
		ld		hl, BUF+4
GERAL:
		ld		a, DIG_APAG				// Apaga 2 ultimos displays
		ld		(DISP+4), a
		ld		(DISP+5), a
		ld		a, b
		push	hl
		rld
		inc		hl
		rld
		ld		bc, DISP+2
		pop		hl
		call	DISPLAY
		inc		hl
		ld		bc, DISP
		call	DISPLAY
		jp		NEC2
;
; ROTINA DE GRAVAÇÃO DE FITA
;
GFITA:
		ld		a, 0FFh					// seta todos os displays
		out		(PDIG), a
		ld		a, 0F7h					// seta segmento D "____ __"
		out		(PSEG), a
		call	CBYTES					// calcular checksum
		jp		c, MERRO				// se houve erro (endF < endI) exibimos no display 
		ld		(BUF+6), a				// colocamos checksum no cabecalho
		ld		hl, 4000				// 4 segundos
		call	GE1KHZ					// geramos 4 segs. de 1KHz
		ld		hl, BUF					// HL aponta para o cabecalho
		ld		bc, 7					// sao 7 bytes de cabecalho
		call	SAFITA					// geramos os 7 bytes
		ld		hl, 2000				// 2 segundos
		call	GE2KHZ					// geramos 2 segs. de 2KHz
		call	PARAM					// calculamos de novo os parametros. HL aponta para dados,
		call	SAFITA					// BC tem o tamanho dos dados, geramos os BC bytes para a fita
		ld		hl, 4000				// 4 segundos
		call	GE2KHZ					// terminamos com 4 segs. de tom 2KHz
		jp		MFIM					// e acabou
;
; ROTINA CALC. NUMERO DE BYTES
;
CBYTES:
		call	PARAM					// vamos calcular os parametros
		ret		c						// se end. final for menor que end. inicial deu erro, retornamos
		xor		a						// zeramos A
SOMA:
		add		a, (hl)					// somamos um byte
		cpi								// incrementa HL e decrementa BC
		jp		pe, SOMA				// se ainda nao acabou, voltamos para o loop
		or		a						// zeramos carry
		ret								// A contem o checksum
;
; ROTINA CALC. PARAMETROS
;
PARAM:
		ld		hl, BUF+2				// aponta para end. inicial
		ld		e, (hl)					// End. inicial (low)
		inc		hl
		ld		d, (hl)					// End. inicial (high)
		inc		hl
		ld		c, (hl)					// End. final (low)
		inc		hl
		ld		h, (hl)					// End. final (high)
		ld		l, c
		or		a
		sbc		hl, de					// DE = end. inicial, HL = end. final
		ld		c, l
		ld		b, h
		inc		bc						// BC = comprimento dos dados
		ex		de, hl					// HL = end. inicial, DE = end. final
		ret								// se DE < HL sai com carry=1 (condicao de erro)
;
; ROTINA DE SAIDA PARA A FITA
;
SAFITA:
		ld		e, (hl)					// pegamos um byte dos dados
		call	SABYTE					// geramos os bits para a fita
		cpi								// incrementa HL e decrementa BC
		jp		pe, SAFITA				// se ainda nao acabou, retornamos ao loop
		ret								// acabou, voltamos
;
; ROTINA DE SAIDA DE BYTES
;
SABYTE:
		ld		d, 8					// vamos gerar 8 bits
		or		a						// bit de start eh 0
		call	SAIBIT					// geramos bit de start
LOOPC1:
		rr		e						// vamos enviar o bit LSB primeiro
		call	SAIBIT					// geramos ele
		dec		d						// se ainda nao gerou os 8 bits do byte,
		jr		nz, LOOPC1				// volta ao loop
		scf								// bit de stop eh 1
		call	SAIBIT					// geramos bit de stop
		ret								// acabou, voltamos
;
; ROTINA DE SAIDA DE BITS
;
SAIBIT:
		exx								// salva registradores
		ld		h, 0					// zera H
		jr		c, SAI1					// se bit a ser gerado for 1, pulamos
SAI0:
		ld		l, ZERO2K				// gerar bit 0: 8 ciclos de 2KHz
		call	GE2KHZ
		ld		l, ZERO1K				// e 2 ciclos de 1KHz
		jr		FINAL2					// pulamos
SAI1:
		ld		l, UM2K					// gerar bit 1: 4 ciclos de 2KHz
		call	GE2KHZ
		ld		l, UM1K					// e 4 ciclos de 1KHz
FINAL2:
		call	GE1KHZ					// geramos o sinal de 1KHz
		exx								// restauramos regs.
		ret								// acabou, retorna
;
; ROTINA DE GERACAO DE TONS
;
GE1KHZ:
		ld		c, V1KHZ				// gerar tom de 1KHz
		jr		TOM
GE2KHZ:
		ld		c, V2KHZ				// gerar tom de 2KHz
TOM:
		add		hl, hl					// duplicamos a quantidade de ciclos para termos
		ld		de, 1					// a quantidade de semiciclos
		ld		a, 0FFh					// enviamos primeiro semiciclo positivo (PE0 = 1)
QUAD:
		out		(PPS), a				// setamos PE0
		ld		b, c					// B contem delay que estava em C
		djnz	$						// esperamos o tempo do delay
		xor		1						// invertemos PE0 para gerar proximo semiciclo
		sbc		hl, de					// decrementamos contador de semiciclos
		jr		nz, QUAD				// ainda nao acabou de gerar a quantidade de ciclos
		ret								// agora acabou, voltamos
;
; ROTINA DE LEITURA DE FITA
;
LFITA:
		ld		a, DIG_APAG				// Apaga 2 ultimos digitos
		ld		(DISP+4), a
		ld		(DISP+5), a
		ld		hl, (BUF)				// HL contem titulo
		ld		(BUFT), hl				// salvamos titulo em BUFT
COND1:
		ld		a, 0FFh
		out		(PDIG), a				// seta todos displays
		ld		a, 0BFh
		out		(PSEG), a				// seta segmento G "---- --"
		ld		hl, 1000				// contador do pulso de sincronismo, pelo menos 1 segundo estavel
COND2:
		call	PERIOD					// Mede tamanho do ciclo
		jr		c, COND1				// nao eh tom de 1KHz, voltamos ao inicio
		dec		hl						// temos um tom de 1KHz, decrementamos contador do sincronismo
		ld		a, h					// testamos se contador chegou a zero
		or		l						//
		jr		nz, COND2				// enquanto nao zeramos contador de sinc., volta ao loop
COND3:
		call	PERIOD					// aqui temos 1 segundo de sinc. 1KHz estavel
		jr		nc, COND3				// esperamos o restante do sincronismo
		ld		hl, BUF					// apontamos para o BUF
		ld		bc, 7					// 7 bytes do cabecalho
		call	ENFITA					// lemos os 7 bytes do cabecalho em BUF
		jr		c, COND1				// se houve erro voltamos a estaca zero
		ld		bc, DISP+2				// vamos exibir o titulo lido na fita
		ld		hl, BUF					// como a leitura foi em little-endian
		call	DISPLAY					// mostramos o primeiro byte (LSB) no segundo par do display
		inc		hl						// e o segundo byte (MSB) no primeiro par do display
		ld		bc, DISP
		call	DISPLAY
		ld		de, (BUF)				// vamos manter a atualizacao do titulo no display
		ld		b, 32					// por um delay de 32
LOOP2:
		ld		hl, DISP
		call	REST
		djnz	LOOP2					// enquanto o delay nao acabar, atualizamos o display
		ld		hl, (BUFT)
		nop
		or		a
		sbc		hl, de					// testamos se o titulo lido bate com o esperado
		jp		nz, COND1				// se nao for o que o usuario pediu volta e espera novo arquivo
		ld		a, 0FFh
		out		(PDIG), a				// seta todos displays
		ld		a, 0FEh
		out		(PSEG), a				// seta segmento A "^^^^ ^^" para indicar que recebemos um cabecalho corretamente
		call	PARAM					// calcula parametros
		jp		c, MERRO				// se houve erro no cabecalho mostramos erro
		call	ENFITA					// ler dados da fita
		jp		c, MERRO				// mostra mensagem se houve erro
		call	CBYTES					// calcula checksum
		ld		hl, BUF+6				// pega checksum do cabecalho
		cp		(hl)					// compara
		jp		nz, MERRO				// se checksum nao bateu, mostramos erro
		jp		MFIM					// leitura concluida!!
;
; ROTINA DE GERACAO DE PERIODOS
;
PERIOD:
		ld		de, 0					// Contador de ciclos
LOOP3:
		in		a, (PPE)				// le porta K7 (bit 0)
		inc		de						// incrementa contador
		rr		a						// joga bit lido (bit 0) para o carry
		jr		c, LOOP3				// enquanto estiver recebendo 1 volta
		ld		a, 00h					// envia 0 para o auto-falante de monitoramento
		out		(PPS), a				// 
LOOP4:
		in		a, (PPE)				// le porta K7 (bit 0)
		inc		de						// incrementa contador
		rr		a						// joga bit lido (bit 0) para o carry
		jr		nc, LOOP4				// enquanto estiver recebendo 0 volta
		ld		a, 0FFh					// envia 1 para o auto-falante de monitoramento
		out		(PPS), a				// 
		ld		a, e					// testamos E (parte baixa contador)
		cp		PERIOP					// compara com limiar entre 1KHz e 2KHz?
		ret
;
; ROTINA DE ENTRADA DE FITA
;
ENFITA:
		xor		a						// zera A
		ex		af, af					// salva A
LOOP5:
		call	LEBYTE					// lemos 1 byte
		ld		(hl), e					// salvamos em (hl)
		cpi								// incrementa HL e decrementa BC
		jp		pe, LOOP5				// enquanto BC não for -1, voltamos para o loop
		ex		af, af					// recupera A (que agora esta em 0)
		ret
;
; ROTINA DE LEITURA DE BYTES
;
LEBYTE:
		call	LEBIT					// lemos o bit de start (0)
		ld		d, 8					// vamos ler 8 bits
LOOP6:
		call	LEBIT					// ler o bit (vem no carry)
		rr		e						// rotacionamos para o MSB do reg. E
		dec		d						// decrementa contador de bits
		jr		nz, LOOP6				// se ainda nao acabou de ler os 8 bits volta para o loop
		call	LEBIT					// lemos o bit de stop (1)
		ret
;
; ROTINA DE LEITURA DE BITS
;
LEBIT:
		exx								// salvamos os registradores
		ld		hl, 0					// contador do que?
LOOP7:
		call	PERIOD					// calculamos o tamanho do ciclo, carry indica se é 1KHz (C=0) ou 2KHz (C=1)
//		inc		d						// porque incrementa D?
//		jr		nz, ERROT				// altera a flag C tambem? tirei por dar erro
		jr		c, PERR					// se for 2KHz pula
		dec		l						// temos um pulso de 1KHz
		dec		l						// decrementamos L duas vezes
		set 	0, h					// e setamos bit 0 do reg. H
		jr		LOOP7					// voltamos ao loop
PERR:
		inc		l						// temos um pulso de 2KHz, incrementamos L
		bit		0, h					// testamos se bit 0 do reg. H ja foi setado
		jr		z, LOOP7				// se nao foi setado, voltamos ao loop
		rl		l						// se o bit lido for 0 (8 ciclos 2KHz e 2 ciclos 1KHz) teremos L = 4
		exx								// se o bit lido for 1 (4 ciclos 2KHz e 4 ciclos 1KHz) teremos L= -4
		ret								// entao carry sai 0 se bit for 0 ou carry sai 1 se bit for 1 (restauramos os regs.)
;
; ROTINA DE ERRO DE TRANSMISSAO
;
ERROT:
		ex		af, af					// trocamos AF por AF'
		scf								// setamos o carry em AF'
		ex		af, af					// voltamos de AF' para AF
		exx								// restauramos os regs. salvos anteriormente
		ret								// e retornamos
MERRO:
		ld		hl, ERRO				// houve erro, exibimos a mensagem no display
		call	REST					// eternamente
		jr		MERRO
MFIM:
		ld		hl, FIM					// acabou o procedimento, exibimos "FIN" no display
		call	REST					// eternamente
		jr		MFIM

ERRO:		db		DIG_E, DIG_R, DIG_R, DIG_O, DIG_APAG, DIG_APAG
FIM:		db		DIG_F, DIG_I, DIG_N, DIG_APAG, DIG_APAG, DIG_APAG
TITULO:	db		DIG_T, DIG_I, DIG_T, DIG_U, DIG_L, DIG_O
MFONTE:	db		DIG_F, DIG_O, DIG_N, DIG_T, DIG_E, DIG_APAG
MFINAL:	db		DIG_F, DIG_I, DIG_N, DIG_A, DIG_L, DIG_APAG

/* Constantes e posicoes da RAM */
ZERO2K		= 8
ZERO1K		= 2
UM2K		= 4
UM1K		= 4
PERIOP		= 66
V1KHZ		= 9Ah
V2KHZ		= 40h
ATRASO		= 0100h

// End RAM
BUF			= 9B50h
BUFT		= 9B57h
CONT		= 9B59h
DISP		= 9B5Ah
MENCON		= 9BE5h
FLAG		= 9BE6h
BUFDIS		= 9BE7h
BYTE5		= 9BEBh
ENDISP		= 9BEDh
PBE			= 9BEEh
PAE			= 9BEFh
ROT			= 9BF0h
ROTINT      = 9BF2h
MENI		= 9BF7h
MENF		= 9BF8h
MENA		= 9BF9h
MENL		= 9BFAh
MENH		= 9BFBh
MENE		= 9BFCh
MEND		= 9BFDh
MENC		= 9BFEh
MENB		= 9BFFh
PILHAI      = 9C00h
PILHAT      = 9BE4h
PILHARR     = 9BF8h
