/*****************************
  NESTOR - aplicativo demo 4
    Revista 86 - Abril/84
Jogo da forca com modificações

        Digitado por
      Fábio Belavenuto
       em 12/12/2013

     Compilar com SJASM
*****************************/

	output	forca.bin
	defpage	0, 2000h, *
	
	page 0

	include	"../monitor/defs.inc"
	include	"../monitor/nestor.inc"

DELAYROL	= 32
DELAY		= 96

	code @ 2000h

inicio:
	ld		bc, msg_titulo				// BC aponta para mensagem de titulo
a4:
	ld		d, DELAYROL					// D contem um contador de atraso para rolagem do titulo
	inc		bc							// incrementa BC
	ld		a, c						// testa C
	cp		LOW (msg_titulo_fim-5)		// se for fim da mensagem
	jp z, 	inicio						// recomeca
a3:
	ld		e, 6						// E recebe 6 (contador do digito)
	ld		a, 1						// A recebe 1 (bit 0)
	ld		h, b						// copia para HL o conteudo de BC (apontador da mensagem de titulo)
	ld		l, c						//
a2:
	call	TEMPO						// chama TEMPO (coloca caracter apontado por HL no display do bit em A
	ex		af							// salva A
	in		a, (PTEC)					// testa se tem tecla apertada
	cp		0							// compara com 0
	jp nz,	a1							// se não for 0, teve tecla apertada, pula
	ex		af							// restaura A
	add		a, a						// desloca A para apontar para o proximo bit (proximo display)
	dec		e							// decrementa E
	jp nz,	a2							// se nao for 0 ainda tem display para atualizar, voltamos em A2
	dec		d							// acabou a atualizacao de todos os digitos do display, decrementamos D (delay)
	jp nz,	a3							// se D nao for 0, voltamos a atualizar o display
	jp 		a4							// D chegou a 0, acabou a espera, vamos em A4 para incrementar BC e deslocar a mensagem do titulo
a1:
	ex		af							// acabamos de mostrar o titulo, salvamos A (A contem a tecla pressionada)
	ld		hl, mencon1					// vamos por 0 em MENCON1
	ld		(hl), 0
	ld		hl, mencon2					// vamos por 0 em MEMCON2
	ld		(hl), 0
	ld		hl, ndv						// vamos por 0 em NDV
	ld		(hl), 0
	exx									// troca registradores
	ld		hl, buf						// HL' aponta para buffer da palavra digitada pelo usuario
	exx									// troca regs
	ld		hl, buft					// HL aponta para buffer das letras acertadas
a5:
	ld		(hl), 0FFh					// vamos preencher BUF e BUFT com 0xFF 
	inc		hl							// (são 12 bytes, entao preenchemos tambem de 0xFF a variavel BUF)
	ld		a, l
	cp		LOW (buft+12)
	jp nz,	a5
a6:
	ld		hl, buf						// aqui HL aponta para buffer da palavra escolhida pelo usuario
	call	RIP							// chama RIP que coloca no display o conteudo apontado por HL (6 bytes) e testa teclado
	ld		a, b						// A recebe conteudo de B
	cp		0							// se B (no caso A) for 0, nao teve tecla pressionada
	jp z,	a6							// entao voltamos no loop que fica exibindo o conteudo de BUF
a7:
	ld		hl, buf						// chegamos aqui quando pressionamos uma tecla
	call	REST						// exibe no display os 6 bytes apontados por HL sem testar teclado
	ld		a, d						// colocamos em A o conteudo de D, que deve apontar para o bit da coluna do teclado da ultima tecla pressionada
	out		(PDIG), a					// seta coluna do teclado
	in		a, (PTEC)					// le teclado
	cp		0							// se ainda estiver sendo pressionada
	jp nz,	a7							// volta a atualizar o display e espera até tecla deixar de ser pressionada
	call	AJCOL						// tecla deixou de ser pressionada, vamos converter para um numero de 0 a 23
	call	AJTEC
	ld		hl, mencon2					// Vamos verificar o valor de mencon2
	ld		a, (hl)						//
	bit		0, a						// testamos bit 0 de A, se for 0 (digito impar) nao fazemos nada
	jp nz,	a133						// pulamos para A133 se o bit 0 de mencon2 for 1 (digito par) para converter 2 digitos em valor hexa e salvar em HL' (BUF)
	ld		hl, met						// salvamos o conteudo de B em MET
	ld		(hl), b						//
a14:
	ld		hl, mencon2					// incrementamos o conteudo de mencon2 (indicar que eh digito impar ou par)
	inc		(hl)
	ld		a, (hl)						// lemos o valor de mencon2, se for 12 eh porque esta completo (maximo de 6 letras)
	cp		12							//
	jp nz,	a6							// se nao preencheu as 6 letras, retornamos para a6
	ld		de, DELAY					// carregamos um atraso em DE
a8:
	ld		hl, buf						// vamos exibir o conteudo de BUF
	call	REST
	dec		de							// e esperamos o tempo do delay atualizando o display
	ld		a, d						// jogamos D para A
	or		e							// para fazer um OR entre D e E para ver se chegou a 0
	jp nz,	a8							// se nao acabou o tempo do delay, voltamos para o loop em A8
	nop
a9:
	ld		hl, buft					// agora vamos exibir o conteudo de BUFT no display
	call	RIP							// e testar se tem tecla pressionada
	ld		a, b						// tem tecla pressionada?
	cp		0							//
	jp z,	a9							// se nao, voltamos em A9 e continuamos a atualizar o display ate apertar uma tecla
a10:
	ld		hl, buft					// era 214A
	call	REST						// atualiza display com conteudo de BUFT e testa teclado
	ld		a, d
	out		(PDIG), a
	in		a, (PTEC)
	cp		0
	jp nz,	a10							// se nao pressionou nenhuma tecla volta a atualizar display
	call	AJCOL						// convertemos a tecla pressionada em indice em B de 0 a 23
	call	AJTEC
	ld		hl, mencon1					// testamos se eh digito impar ou par
	bit		0, (hl)
	jp nz,	a11							// se for par (2 digitos pressionados) pulamos para A11
	inc		(hl)						// incrementar contador de teclas
	ld		hl, met
	ld		(hl), b						// salvamos tecla pressionada em MET
	jp		a9							// esperamos proxima tecla
a11:
	inc		(hl)						// incrementa contador de teclas
	ld		a, b						// vamos rotacionar as teclas para gerar o valor hexa em A
	ld		hl, met						//
	rld									//
	ld		a, (hl)						// A contem valor hexa digitado
	ld		e, 0						// E marca se acertou
	ld		hl, buf						// HL aponta para buffer da palavra escolhida pelo usuario
a13:
	cp		(hl)						// testa se bate letra escolhida com alguma da palavra do usuario
	jp z,	acertou						// bateu, entao vamos marcar a letra como certa
	inc		hl							// incrementa
a16:
	ld		c, a						// salvamos a letra digitada
	ld		a, l
	cp		LOW (buf + 6)				// testamos as 6 letras?
	jp z,	a12							// sim, pulamos para A12
	ld		a, c						// voltamos a letra digitada para testar por outras posicoes
	jp		a13							// testar o resto
a12:
	ld		a, e						// acertamos a letra?
	cp		0
	jp z,	errou						// nao acertamos, vamos mostrar que errou e incrementar a quantidade de erros
	jp		a9							// volta ao comeco

a133:
	ld		hl, met						// temos 2 valores hexa digitados, vamos converter para ASCII
	ld		a, b						// MET tem o primeiro, B tem o segundo
	rld									// rotaciona 4 bits dos 12 bits de A(low) e conteudo de HL, assim juntamos os 2 valores hexa digitados em A
	ld		a, (hl)						// trazemos para A o resultado de (HL)
	exx									// salvamos os registradores (menos AF)
	ld		(hl), a						// colocamos A em HL' (que aponta para BUF)
	inc		hl							// incrementamos HL'
	exx									// voltamos os registradores
	jp		a14							// agora voltamos para A14

RIP:
	ld		b, 0						// B contera um valor diferente de zero se pressionarmos alguma tecla
	ld		d, 0						// D contera o bit da coluna do teclado se pressionarmos alguma tecla
	ld		e, 6						// E conta 6 digitos para exibir
	ld		a, 1						// comecamos no display 1
a15:
	call	VARR						// atualizamos display e testamos por teclas pressionadas
	ld		a, c						// pegamos A salvo em C
	add		a, a						// rotacionamos A para acionar proximo display
	dec		e							// decrementa contados de display
	jp nz,	a15							// ainda nao exibimos todo os 6 caracteres, voltamos ao loop
	ret									// atualizamos o display, retornar a rotina chamadora

acertou:
	ld		c, a						// acertamos uma letra, vamos salvar esta em C
	ld		a, l						// salvamos L em A
	push	hl							// salvar HL
	sub		6							// subtraimos 6 para apontar para a mesma posicao do caracter no buffer de letras acertadas
	ld		l, a						// corrige L para HL apontar para HL anterior - 6
	ld		(hl), c						// salvamos letra em C no buffer de acertos
	pop		hl							// restauramos HL
	inc		hl							// incrementamos HL para testar proximo caracter
	ld		a, c						// voltamos caracter salvo
	ld		e, 1						// marcamos que tivemos acerto
	jp		a16							// volta em A16

errou:
	ld		hl, ndv						// carrega numero de erros
	inc		(hl)						// incrementa
	ld		a, (hl)						// transfere n. erros para A
	ld		hl, tfe						// ponteiro na RAM contendo os digitos de 1 a 7
	add		a, l						// converte numero de erro em digito
	ld		l, a
	ld		a, (hl)						// A contem o digito de 1 a 7 conforme valor de NDV
	ld		hl, bufe					// buffer na RAM para exibir "ERRO x" onde 'x' é a quantidade de erros
	ld		(hl), DIG_E
	inc		hl
	ld		(hl), DIG_R
	inc		hl
	ld		(hl), DIG_R
	inc		hl
	ld		(hl), DIG_O
	inc		hl
	ld		(hl), DIG_APAG
	inc		hl
	ld		(hl), a
	ld		de, DELAY					// atraso para exibir mensagem por um tempo
a166:
	ld		hl, bufe					// exibir mensagem de erro
	call	REST
	dec		de
	ld		a, d
	or		e
	jp nz,	a166						// ainda nao acabou tempo de delay, voltar a exibir mensagem
	ld		hl, ndv						// carrega numero de erros
	ld		a, (hl)
	cp		7							// chegou a 7?
	jp z,	perdeu						// se sim, exibir mensagem de fim de jogo
	jp		a9							// ainda ha tentativas, voltar
	
perdeu:
	ld		bc, msg_gameover
a18:
	ld		d, DELAYROL					// atraso de rolagem de mensagem de game over
	inc		bc
	ld		a, c
	cp		LOW (msg_gameover_fim-5)
	jp z,	perdeu
a17:
	ld		h, b
	ld		l, c
	push	bc
	call	REST
	pop		bc
	dec		d
	jp nz,	a17
	jp		a18							// exibe mensagem sem parar

	// Variaveis e constantes

msg_titulo:
	db		DIG_APAG, DIG_APAG, DIG_APAG, DIG_APAG, DIG_APAG, DIG_APAG
	db		DIG_J, DIG_O, DIG_G, DIG_O
	db		DIG_APAG, DIG_APAG
	db		DIG_D, DIG_A
	db		DIG_APAG, DIG_APAG
	db		DIG_F, DIG_O, DIG_R, DIG_C, DIG_A
	db		DIG_APAG, DIG_APAG, DIG_APAG, DIG_APAG, DIG_APAG, DIG_APAG
msg_titulo_fim:

msg_gameover:
	db		DIG_APAG, DIG_APAG, DIG_APAG, DIG_APAG, DIG_APAG, DIG_APAG
	db		DIG_G, DIG_A, DIG_N, DIG_E, DIG_APAG
	db		DIG_O, DIG_U, DIG_E, DIG_R, DIG_APAG
	db		DIG_APAG, DIG_APAG, DIG_APAG, DIG_APAG, DIG_APAG, DIG_APAG
msg_gameover_fim:

tfe:
	db		0
	db		DIG_1, DIG_2, DIG_3, DIG_4, DIG_5, DIG_6, DIG_7

mencon1:
	ds		1							// 
buft:
	ds		6							// buffer com as letras acertadas pelo usuario na posicao correta
buf:
	ds		6							// buffer com a palavra escolhida pelo usuario
mencon2:
	ds		1							// 
met:
	ds		2							// 
ndv:
	ds		1							// numero de erros
bufe:
	ds		6							// buffer para exibir mensagem de erro
