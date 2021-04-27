/*
 *  by Fábio Belavenuto - Copyright 2011
 *
 *  Versão 0.1beta
 *
 *  Este arquivo é distribuido pela Licença Pública Geral GNU.
 *  Veja o arquivo "Licenca.txt" distribuido com este software.
 *
 *  ESTE SOFTWARE NÃO OFERECE NENHUMA GARANTIA
 */

//#define DEBUG1

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include "wav.h"
#include "functions.h"

// Definições
#define VERSAO "0.1"
#define DURSILENP 800			// 800 ms
#define DURSILENS 500			// 500 ms
#define DURCABA   2000			//   2 seg
#define MINCABA   500
#define MAXCABA   4000
#define TAXAAMOST 44100

// Estruturas
typedef struct ntfcab {
	unsigned short titulo;
	unsigned short endI;
	unsigned short endF;
	unsigned char checksum;
}__attribute__((__packed__)) Tntfcab;

// Variáveis
int  DurSilencioP    = DURSILENP;
int  DurSilencioS    = DURSILENS;
int  DurCabA         = DURCABA;
int  TaxaAmostragem  = TAXAAMOST;
int  totalDados      = 0;

// Funções

// =============================================================================
void silencio(FILE *fileWav, int duracaoms) {
	int   Total;
	short *buffer;

	Total = (TaxaAmostragem * duracaoms) / 1000;
	buffer = (short *)malloc(Total * sizeof(short) + 1);
	memset(buffer, 0, Total * sizeof(short));
	fwrite(buffer, sizeof(short), Total, fileWav);
	totalDados += Total * sizeof(short);
	free(buffer);
}

// =============================================================================
void tom(FILE *fileWav, int frequencia, int duracaoms)
{
	static short Pico = 32767;
	short *buffer;
	int   c, i;
	int   Total, CicloT, Ciclo1, Ciclo2;

	CicloT = TaxaAmostragem / frequencia;
	Ciclo1 = (int)((double)CicloT / 2 + .5);
	Ciclo2 = CicloT / 2;
	Total = CicloT * duracaoms;
	buffer = (short *)malloc(Total * sizeof(short) + sizeof(short));

	c = i = 0;
	while (c < Total) {
		i = 0;
		while (i++ < Ciclo1) {
			buffer[c++] = Pico;
		}
		Pico = 0-Pico;
		i = 0;
		while (i++ < Ciclo2) {
			buffer[c++] = Pico;
		}
		Pico = 0-Pico;
	}
	fwrite(buffer, sizeof(short), c, fileWav);
	totalDados += c * sizeof(short);
	free(buffer);
}

// =============================================================================
void tocaBit0(FILE *fileWav)
{
	tom(fileWav, FREQ2K, 8);
	tom(fileWav, FREQ1K, 2);
}

// =============================================================================
void tocaBit1(FILE *fileWav)
{
	tom(fileWav, FREQ2K, 4);
	tom(fileWav, FREQ1K, 4);
}

// =============================================================================
void tocaByte(FILE *fileWav, unsigned char byte)
{
	unsigned char mask = 1;		// MSB Primeiro
	int c = 0;

	tocaBit0(fileWav);
	while(c < 8) {
		if (byte & mask) {
			tocaBit1(fileWav);		// bit 1
		} else {
			tocaBit0(fileWav);		// bit 0
		}
		mask <<= 1;
		c++;
	}
	tocaBit1(fileWav);
}

// =============================================================================
void imprimeInf(unsigned short titulo, unsigned short endI, unsigned short endF)
{
	printf("Titulo: 0x%04X, ", titulo);
	printf("de 0x%.4X a 0x%.4X\n", endI, endF);
}

// =============================================================================
void mostraUso(char *nomeprog)
{
	fprintf(stderr, "\n");
	fprintf(stderr, "%s - Utilitario para gerar arquivo de audio .wav a partir\n", nomeprog);
	fprintf(stderr, "          do arquivo .ntf (Nestor Tape File). Versao %s\n\n", VERSAO);
	fprintf(stderr, "  Uso:\n");
	fprintf(stderr, "    %s [opcoes] <arquivo>\n\n", nomeprog);
	fprintf(stderr, "  Opcoes:\n");
	fprintf(stderr, "  -t <sps>    - Determina a taxa de amostragem em \"Samples per Second\".\n");
	fprintf(stderr, "                Padrao: %d sps, minimo 8000 maximo 88200\n", TaxaAmostragem);
	fprintf(stderr, "  -p <ms>     - Determina a duracao do silencio inicial.\n");
	fprintf(stderr, "                Padrao: %d ms \n", DurSilencioP);
	fprintf(stderr, "  -s <ms>     - Determina a duracao do silencio entre 2 arquivos.\n");
	fprintf(stderr, "                Padrao: %d ms \n", DurSilencioS);
	fprintf(stderr, "  -c <ms>     - Determina a duracao do cabecalho.\n");
	fprintf(stderr, "                Padrao: %d ms, Minimo de %d ms, Maximo de %d ms \n", DurCabA, MINCABA, MAXCABA);
	fprintf(stderr, "  -o <arq.>   - Salva resultado nesse arquivo.\n");
	fprintf(stderr, "\n");
	exit(0);
}

// =============================================================================
int main (int argc, char *argv[])
{
	int      c = 1, silencioAtual = DurSilencioP;
	int      comp;
	char     temp[1024], b, *p;
	char     *arqNtf    = NULL;
	char     *arqWav    = NULL;
	FILE     *fileNtf   = NULL;
	FILE     *fileWav   = NULL;
	TWaveCab waveCab;
	Tntfcab  ntfcab;

	if (argc < 2)
		mostraUso(argv[0]);

	// Interpreta linha de comando
	while (c < argc) {
		if (argv[c][0] == '-' || argv[c][0] == '/') {
			if (c+1 == argc) {
				fprintf(stderr, "Falta parametro para a opcao %s", argv[c]);
				return 1;
			}
			switch(argv[c][1]) {

			case 't':
				++c;
				TaxaAmostragem = MIN(88200, MAX(8000, atoi(argv[c])));
				break;

			case 'p':
				++c;
				DurSilencioP = MAX(10, atoi(argv[c]));
				break;

			case 's':
				++c;
				DurSilencioS = MAX(10, atoi(argv[c]));
				break;

			case 'c':
				++c;
				DurCabA = MIN(MAXCABA, MAX(MINCABA, atoi(argv[c])));
				break;

			case 'o':
				arqWav = argv[++c];
				break;

			default:
				fprintf(stderr, "Opcao invalida: %s\n", argv[c]);
				return 1;
				break;
			} // switch
		} else
			arqNtf = argv[c];
		c++;
	}

	if (!arqNtf) {
		fprintf(stderr, "Falta nome do arquivo.\n");
		return 1;
	}

	if (!arqWav) {
		arqWav = (char *)malloc(strlen(arqNtf) + 1);
		strcpy(arqWav, arqNtf);
		p = (char *)(arqWav + strlen(arqWav));
		while(--p > arqWav) {
			if (*p == '.') {
				strncpy(p, ".wav\0", 5);
				break;
			}
		}
	}

	//
	if (!(fileNtf = fopen(arqNtf, "rb"))) {
		fprintf(stderr, "Erro ao abrir arquivo %s\n", arqNtf);
		return -1;
	}

	if (!(fileWav = fopen(arqWav, "wb"))) {
		fprintf(stderr, "Erro ao criar arquivo %s", arqWav);
		return 1;
	}


	fread(temp, 1, 4, fileNtf);
	if (strncmp(temp, "NTF\0", 4)) {
		fclose(fileNtf);
		fclose(fileWav);
		fprintf(stderr, "ERRO: Arquivo nao esta no formato .NTF\n");
		return 1;
	}

	memset(&waveCab, 0, sizeof(TWaveCab));

	strcpy((char *)waveCab.GroupID,  "RIFF");
	waveCab.GroupLength    = 0;			// Não fornecido agora
	strcpy((char *)waveCab.TypeID,   "WAVE");
	strcpy((char *)waveCab.FormatID, "fmt ");
	waveCab.FormatLength   = 16;
	waveCab.wFormatTag     = WAVE_FORMAT_PCM;
	waveCab.NumChannels    = 1;
	waveCab.SamplesPerSec  = TaxaAmostragem;
	waveCab.BytesPerSec    = TaxaAmostragem * (16 / 8);
	waveCab.nBlockAlign    = (16 / 8);
	waveCab.BitsPerSample  = 16;
	strcpy((char *)waveCab.DataID,   "data");
	waveCab.DataLength     = 0;			// Não fornecido agora
	fwrite(&waveCab, 1, sizeof(TWaveCab), fileWav);

	while (1) {
		// Lê cabecalho
		fread(&ntfcab, 1, sizeof(Tntfcab), fileNtf);
		// Comprimento do bloco
		comp = ntfcab.endF - ntfcab.endI + 1;

		imprimeInf(ntfcab.titulo, ntfcab.endI, ntfcab.endF);

		silencio(fileWav, silencioAtual);
		silencioAtual = DurSilencioS;
		tom(fileWav, FREQ1K, DurCabA);
		// Titulo
		tocaByte(fileWav, ntfcab.titulo & 0x00FF);
		tocaByte(fileWav, (ntfcab.titulo & 0xFF00) >> 8);
		// Endereco inicial
		tocaByte(fileWav, ntfcab.endI & 0x00FF);
		tocaByte(fileWav, (ntfcab.endI & 0xFF00) >> 8);
		// Endereco final
		tocaByte(fileWav, ntfcab.endF & 0x00FF);
		tocaByte(fileWav, (ntfcab.endF & 0xFF00) >> 8);
		// Checksum
		tocaByte(fileWav, ntfcab.checksum);
		tom(fileWav, FREQ2K, DurCabA);
		// Toca Dados
		for (c = 0; c < comp; c++) {
			fread(&b, 1, 1, fileNtf);
			tocaByte(fileWav, b);
		}
		tom(fileWav, FREQ2K, DurCabA);
		break;
	}
	fclose(fileNtf);

	fseek(fileWav, 0, SEEK_SET);
	fread(&waveCab, 1, sizeof(TWaveCab), fileWav);
	waveCab.DataLength = totalDados;
	waveCab.GroupLength = totalDados + sizeof(TWaveCab) - 8;
	fseek(fileWav, 0, SEEK_SET);
	fwrite(&waveCab, 1, sizeof(TWaveCab), fileWav);
	fclose(fileWav);
	return 0;
}
