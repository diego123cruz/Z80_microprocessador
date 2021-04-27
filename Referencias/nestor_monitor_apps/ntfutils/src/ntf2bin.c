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
 * ntf2bin.cpp
 *
 *  Created on: 13/12/2012
 *      Author: Fabio Belavenuto
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "wav.h"
#include "functions.h"

// Definições
#define VERSAO "0.1"

// Estruturas
typedef struct ntfcab {
	unsigned short titulo;
	unsigned short endI;
	unsigned short endF;
	unsigned char checksum;
}__attribute__((__packed__)) Tntfcab;


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
	fprintf(stderr, "%s - Utilitario para gerar arquivo binario a partir\n", nomeprog);
	fprintf(stderr, "     do arquivo .ntf (Nestor Tape File). Versao %s\n\n", VERSAO);
	fprintf(stderr, "  Uso:\n");
	fprintf(stderr, "    %s [opcoes] <arquivo>\n\n", nomeprog);
	fprintf(stderr, "  Opcoes:\n");
	fprintf(stderr, "  -o <arq.>   - Prefixo do arquivo binario.\n");
	fprintf(stderr, "\n");
	exit(0);
}

// =============================================================================
int main (int argc, char *argv[])
{
	unsigned short	comp = 0;
	int				c = 1;
	char			temp[1024], *p, *buffer;
	char			*arqNtf    = NULL;
	char			*arqBin    = NULL;
	FILE			*fileNtf   = NULL;
	FILE			*fileBin   = NULL;
	Tntfcab			ntfcab;

	if (argc < 2)
		mostraUso(argv[0]);

	// Interpreta linha de comando
	while (c < argc) {
		if (argv[c][0] == '-' || argv[c][0] == '/') {
			if (argv[c][1] == 'o' && c+1 == argc) {
				fprintf(stderr, "Falta parametro para a opcao %s", argv[c]);
				return 1;
			}
			switch(argv[c][1]) {

			case 'o':
				arqBin = argv[++c];
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

	if (!arqBin) {
		arqBin = (char *)malloc(strlen(arqNtf) + 1);
		strcpy(arqBin, arqNtf);
		p = (char *)(arqBin + strlen(arqBin));
		while(--p > arqBin) {
			if (*p == '.') {
				*p = '\0';
				break;
			}
		}
		strcat(arqBin, ".bin");
	}

	//
	if (!(fileNtf = fopen(arqNtf, "rb"))) {
		fprintf(stderr, "Erro ao abrir arquivo %s\n", arqNtf);
		return -1;
	}

	if (!(fileBin = fopen(arqBin, "wb"))) {
		fprintf(stderr, "Erro ao criar arquivo %s", arqBin);
		return -1;
	}

	fread(temp, 1, 4, fileNtf);
	if (strncmp(temp, "NTF\0", 4)) {
		fclose(fileNtf);
		fclose(fileBin);
		fprintf(stderr, "ERRO: Arquivo nao esta no formato .NTF\n");
		return 1;
	}

	while (1) {
		// Lê cabecalho
		fread(&ntfcab, 1, sizeof(Tntfcab), fileNtf);
		// Comprimento do bloco
		comp = ntfcab.endF - ntfcab.endI + 1;

		imprimeInf(ntfcab.titulo, ntfcab.endI, ntfcab.endF);

		buffer = (char *)malloc(comp);
		fread(buffer, 1, comp, fileNtf);
		fwrite(buffer, 1, comp, fileBin);

		break;
	}
	if (fileBin)
		fclose(fileBin);
	fclose(fileNtf);
	return 0;
}
