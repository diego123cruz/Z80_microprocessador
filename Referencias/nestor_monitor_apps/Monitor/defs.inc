
/***************************************

       PROGRAMA MONITOR NESTOR
           NOVA ELETRONICA
    SAO PAULO SP 01/84 MSCS/JRP
            Digitado por
          Fábio Belavenuto
            em 27/11/2012

***************************************/

/***************************************

 Variáveis, constantes e endereços da
 RAM usados pelo monitor e rotinas do
 K7 Podem ser utilizados em softwares
 utilitários incluindo este arquivo

***************************************/

// Portas I/O
PTEC		= 1
PSEG		= 1
PPE			= 2
PDIG		= 3
PPS			= 4

// Constantes
// Códigos das teclas (AJCOL e AJTEC)
KEY_0		= 0
KEY_1		= 1
KEY_2		= 2
KEY_3		= 3
KEY_4		= 4
KEY_5		= 5
KEY_6		= 6
KEY_7		= 7
KEY_8		= 8
KEY_9		= 9
KEY_A		= 10
KEY_B		= 11
KEY_C		= 12
KEY_D		= 13
KEY_E		= 14
KEY_F		= 15
KEY_PERM	= 16
KEY_LOAD	= 17
KEY_1M		= 18
KEY_1P		= 19
KEY_RUN		= 20
KEY_ER		= 21
KEY_IV		= 22
KEY_QUAD	= 23

// Caracteres para display 7-seg
DIG_APAG	= 0FFh
DIG_0		= 0C0h
DIG_1		= 0F9h
DIG_2		= 0A4h
DIG_3		= 0B0h
DIG_4		= 99h
DIG_5		= 92h
DIG_6		= 82h
DIG_7		= 0F8h
DIG_8		= 80h
DIG_9		= 90h
DIG_A		= 88h
DIG_B		= 83h
DIG_C		= 0C6h
DIG_D		= 0A1h
DIG_E		= 86h
DIG_F		= 8Eh
DIG_G		= 82h
DIG_H		= 89h
DIG_I		= 0F9h
DIG_J		= 0E1h
DIG_L		= 0C7h
DIG_N		= 0C8h
DIG_O		= 0C0h
DIG_P		= 8Ch
DIG_Q		= 98h
DIG_R		= 0CEh
DIG_S		= 92h
DIG_T		= 87h
DIG_U		= 0C1h
DIG_PONTO	= 7Fh
DIG_IGUAL	= 0B7h
