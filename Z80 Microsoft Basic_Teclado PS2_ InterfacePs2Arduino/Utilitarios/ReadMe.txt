Para configurar o ambiente de compilação ASM -> HEX

Softwares	
	DOSBox0.74-3
	VS Code + Z80 Assembly
	XgproV1120_Setup - Gravador Minipro Tl866ii Plus

Configuração DOSBox / Compilação

	1 - Copiar a pasta Z80ASM para C:\

	2 - Abrir DOSBox para configurar o ambiente, no terminal do DOSBox: 
		a - Montar a partição D: 	mount D c:\Z80ASM
		b - Entrar na partição D:	d:
		c - Verificar os arquivos:	dir

	3 - Compilar o arquivo de boot.asm:	tasm -80 -fff -c boot.asm boot.hex


Gravado utilizado:
	Gravador Minipro Tl866ii Plus


Arquivo original - fonte:
	http://searle.x10host.com/z80/SimpleZ80_32K.html