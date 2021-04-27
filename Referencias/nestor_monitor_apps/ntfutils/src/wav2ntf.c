/*
 *  by Fábio Belavenuto - Copyright 2013
 *
 *  Versão 0.1beta
 *
 *  Este arquivo é distribuido pela Licença Pública Geral GNU.
 *  Veja o arquivo "Licenca.txt" distribuido com este software.
 *
 *  ESTE SOFTWARE NÃO OFERECE NENHUMA GARANTIA
 */

/*
 * wav2ntf.c
 *
 *  Created on: 12/12/2013
 *      Author: Fabio Belavenuto
 */
//#define DEBUG1
//#define DEBUG2

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "wav.h"
#include "functions.h"

// Definições
#define VERSAO "0.1"
#define LIMIAR	 16		// limiar (1 ciclo) entre 1KHz (22) e 2KHz (11)

// Estruturas
typedef struct ntfcab {
	unsigned short titulo;
	unsigned short endI;
	unsigned short endF;
	unsigned char checksum;
}__attribute__((__packed__)) Tntfcab;

// Variáveis
int limiar = LIMIAR;
char separado = 0, binarios = 0, incompleto = 0;
unsigned int tamLens, posLens = 0, contArqs = 0;
unsigned char *lens;
char *arqWav = NULL, *arqNtf = NULL;
FILE *fileLog = NULL;

// ============================================================================
int getLens(FILE *f) {
	short ub;
	int c = 0, p = 0, s = 1024576;
	char sinal, sinalA = -1;

	lens = (unsigned char *)malloc(s);
	while (!feof(f)) {
		fread(&ub, 2, 1, f);
		sinal = (ub < 0) ? -1 : 1;
		if (sinal != sinalA) {
			sinalA = sinal;
			if (c < 80)
				lens[p++] = c;
			if (p >= s) {
				s += 1024576;
				lens = (unsigned char *)realloc(lens, s);
			}
			c = 0;
		}
		c++;
	}
	return p;
}

// ============================================================================
int sincroniza(int e2khz) {
	int c, b = 0;

	// espera 16 ciclos do sincronismo
	while (posLens < tamLens) {
		c = lens[posLens++];
#ifdef DEBUG2
		printf("%d,", c);
#endif
		if (c > limiar && e2khz == 0) {
			b++;
		} else if (c < limiar && e2khz == 1) {
			b++;
		} else {
			b = 0;
		}
		if (b > 16)
			break;
	}
	if (posLens >= tamLens)
		return -1;
	// espera restante do sincronismo
	while (posLens < tamLens) {
		c = lens[posLens++];
#ifdef DEBUG2
		printf("%d,", c);
#endif
		if (c < limiar && e2khz == 0)
			break;
		else if (c > limiar && e2khz == 1)
			break;
	}
	if (posLens >= tamLens)
		return -1;
//	posLens++;	// ignora meio-ciclo
	if (e2khz) {
		posLens -= 17; // retorna meio-ciclo + 8 ciclos (bit 0 de start que se mistura com o sinc de 2KHz)
	} else {
		posLens--;	// retorna meio-ciclo do primeiro bit de start
	}
#ifdef DEBUG1
	printf("sinc %d\n", e2khz);
#endif
	return 0;
}

// ============================================================================
int lerByte() {
	int i, c;
	int c1k = 0, c2k = 0;
	int pronto = 0;
	int r = 0, byte;
	char bits, bite;

	for (i = 0; i < 10; i++) {
		r >>= 1;
		pronto = c1k = c2k = 0;
		while(!pronto) {
			c = lens[posLens++];
#ifdef DEBUG2
			printf("BIT: %d + ", c);
#endif
			c += lens[posLens++];
#ifdef DEBUG2
			printf("%d = %d, ", lens[posLens-1], c);
#endif
			c /= 2;								// Tira a media
#ifdef DEBUG2
			printf("media: %d\n", c);
#endif
			if (c > limiar)
				c1k++;
			else
				c2k++;
			if (c2k == 8 && c1k == 2) {			// Bit 0 = 8 ciclos 2K + 2 ciclos 1K
				r |= 0;
				pronto = 1;
			} else if (c2k == 4 && c1k == 4) {	// Bit 1 = 4 ciclos 2K + 4 ciclos 1K
				r |= 0x200;
				pronto = 1;
			} else if ((c1k+c2k) > 10) {
#ifdef DEBUG1
				printf("Erro ao decodificar bit, c1k=%d, c2k=%d\n", c1k, c2k);
#endif
				return -1;
			}
		}
#ifdef DEBUG2
		printf("bit #%d: %d\n", i, (r & 0x200) >> 9);
#endif
	}
	bits = (r & 0x001);
	bite = (r & 0x200) >> 9;
	if (bits != 0 || bite != 1) {
#ifdef DEBUG1
		printf("Erro ao decodificar byte, r=0x%X, bits=%d, bite=%d\n", r, bits, bite);
#endif
		return -1;
	}
	byte = (r >> 1) & 0xFF;
#ifdef DEBUG1
	printf("Byte lido: %2X\n", byte);
#endif
	return byte;
}

// ============================================================================
int lerBloco(char *buffer, int len, int *ct) {
	int cb = 0, bb;
	unsigned char b;

	*ct = 0;
	while (cb < len) {
		bb = lerByte();
		if (bb < 0) {
			fprintf(fileLog, "\nErro lendo byte\n");
			return -1;
		}
		b = (unsigned char)bb;
		buffer[cb++] = b;
		*ct = *ct + b;
	}
	return cb;
}

// =============================================================================
void mostraUso(char *nomeprog) {
	fprintf(stderr, "\n");
	fprintf(stderr, "%s - Utilitario para interpretar arquivo .wav e converter\n", nomeprog);
	fprintf(stderr, "     para .ntf (Nestor Tape File). Versao %s\n\n", VERSAO);
	fprintf(stderr, "  Uso:\n");
	fprintf(stderr, "    %s [opcoes] <arquivo>\n\n", nomeprog);
	fprintf(stderr, "  Opcoes:\n");
	fprintf(stderr, "  -o <arq.>   - Salva resultado nesse arquivo.\n");
	fprintf(stderr, "  -c          - Ignora erros de checksum.\n");
	fprintf(stderr, "  -n          - Salva arquivos incompletos.\n");
	fprintf(stderr, "  -l          - Gerar mais logs.\n");
	fprintf(stderr, "  -k          - Salvar log em arquivo.\n");
	fprintf(stderr, "  -q <tempo>  - Configura tempo do limiar entre 1 e 2KHz\n");
	fprintf(stderr, "                Padrao: %d\n", limiar);
	fprintf(stderr, "\n");

	exit(0);
}

// =============================================================================
int main(int argc, char *argv[]) {
	FILE *fileWav = NULL, *fileNtf = NULL;
	char ics = 0, logs = 0, loga = 0;
	int c = 1, ct, cb, tamDados;
	TWaveCab waveCab;
	char *p, temp[1024], *buffer = NULL;
	unsigned short titulo, endI, endF;
	unsigned char checksum;

	fileLog = stdout;

	if (argc < 2)
		mostraUso(argv[0]);

	// Interpreta linha de comando
	while (c < argc) {
		if (argv[c][0] == '-' || argv[c][0] == '/') {
			if (c + 1 == argc) {
				if (argv[c][1] == 'o' || argv[c][1] == 'q')
				fprintf(stderr, "Falta parametro para a opcao %s", argv[c]);
				return 1;
			}
			switch (argv[c][1]) {

			case 'o':
				arqNtf = argv[++c];
				break;

			case 'c':
				ics = 1;
				break;

			case 'n':
				incompleto = 1;
				break;

			case 'l':
				logs = 1;
				break;

			case 'k':
				loga = 1;
				break;

			case 'b':
				binarios = 1;
				break;

			case 'q':
				limiar = atoi(argv[++c]);
				break;

			default:
				fprintf(stderr, "Opcao invalida: %s\n", argv[c]);
				return 1;
				break;
			} // switch
		} else
			arqWav = argv[c];
		c++;
	}

	if (!arqWav) {
		fprintf(stderr, "Falta nome do arquivo.\n");
		return 1;
	}

	if (!(fileWav = fopen(arqWav, "rb"))) {
		fprintf(stderr, "Erro ao abrir arquivo %s\n", arqWav);
		return -1;
	}
	fread(&waveCab, 1, sizeof(TWaveCab), fileWav);

	if (loga) {
		sprintf(temp, "%s.log", arqWav);
		fileLog = fopen(temp, "w");
		if (!fileLog)
			fileLog = stdout;
	}

	if (strncmp((const char *)waveCab.GroupID, "RIFF", 4)) {
		fclose(fileWav);
		fprintf(stderr, "Formato nao reconhecido.\n");
		return -1;
	}

	if (waveCab.NumChannels != 1) {
		fclose(fileWav);
		fprintf(stderr, "Audio deve ser mono.\n");
		exit(-1);
	}
	if (waveCab.SamplesPerSec != 44100) {
		fclose(fileWav);
		fprintf(stderr, "Formato deve ser 44100 Samples per second.\n");
		exit(-1);
	}
	if (waveCab.BitsPerSample != 16) {
		fclose(fileWav);
		fprintf(stderr, "Formato deve ser 16 bits\n");
		exit(-1);
	}

	if (!arqNtf) {
		arqNtf = strdup((const char *)arqWav);
		p = (char *)(arqNtf + strlen(arqNtf));
		while(--p > arqNtf) {
			if (*p == '.') {
				*p = '\0';
				break;
			}
		}
		strcat(arqNtf, ".ntf");
	}
	if (!(fileNtf = fopen(arqNtf, "wb"))) {
		fprintf(stderr, "Erro ao abrir arquivo %s\n", arqNtf);
		return -1;
	}

	fprintf(fileLog, "Decodificando '%s'\n", arqWav);
	fprintf(fileLog, "Calculando comprimentos...\n");
	tamLens = getLens(fileWav);
	fclose(fileWav);

	while(1) {
		// Sincronizar com primeiro sync de 1KHz (antes do cabecalho)
		if (sincroniza(0) == -1) {
			if (logs)
				fprintf(fileLog, "Erro ao sincronizar com 1KHz\n");
			break;
		}
//		posSync = posLens;

		// ler 7 bytes (cabecalho)
		cb = lerBloco(temp, 7, &ct);
		if (cb < 7) {
			if (logs)
				fprintf(fileLog, "Cabecalho nao achado\n");
			break;
		}
#ifdef DEBUG1
		for(cb = 0; cb < 7; cb++) {
			printf("%02X", ((unsigned char)temp[cb]));
		}
		printf("\n");
#endif
		titulo   = ((unsigned char)temp[1] << 8) | (unsigned char)temp[0];
		endI     = ((unsigned char)temp[3] << 8) | (unsigned char)temp[2];
		endF     = ((unsigned char)temp[5] << 8) | (unsigned char)temp[4];
		checksum = (unsigned char)temp[6];
		fprintf(fileLog, "Titulo: %04X, End. Inicial: %04X, End. Final: %04X, Checksum: %02X\n", titulo, endI, endF, checksum);
		tamDados = endF - endI + 1;
#ifdef DEBUG1
		printf("Tam. dados: %d\n", tamDados);
#endif
		// Sincronizar com segundo sync de 2KHz (antes dos dados)
		if (sincroniza(1) == -1) {
			if (logs)
				fprintf(fileLog, "Erro ao sincronizar com 2KHz\n");
			break;
		}
		buffer = (char *)malloc(tamDados+1);
		cb = lerBloco(buffer, tamDados, &ct);
		if (cb != tamDados) {
			if (logs)
				fprintf(fileLog, "Erro ao ler dados, lido %d mas deveria ser %d bytes\n", cb, tamDados);
			break;
		}
		ct = ct & 0xFF;
		if (ct != checksum) {
			if (logs)
				fprintf(fileLog, "Erro de checksum: lido 0x%2X, calculado 0x%2X\n", checksum, ct);
			if (!ics)
				break;
		}

		// Termina
		break;
	}

	// Salvar .ntf
	if (buffer) {
		fwrite("NTF\0", 1, 4, fileNtf);
		fwrite(temp, 1, 7, fileNtf);
		fwrite(buffer, 1, tamDados, fileNtf);
		fclose(fileNtf);
		free(buffer);
	}

	fprintf(fileLog, "\n");
	return 0;
}
