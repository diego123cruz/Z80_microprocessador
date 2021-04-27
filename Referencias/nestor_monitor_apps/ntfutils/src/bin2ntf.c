/*
 * bin2ntf.c
 *
 *  Created on: 11/12/2013
 *      Author: Fabio Belavenuto
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "wav.h"
#include "functions.h"

// Definições
#define VERSAO "0.1"

// =============================================================================
void mostraUso(char *nomeprog) {
	fprintf(stderr, "\n");
	fprintf(stderr, "%s - Utilitario para converter arquivos binarios\n", nomeprog);
	fprintf(stderr, "     para .ntf (Nestor Tape File). Versao %s\n\n", VERSAO);
	fprintf(stderr, "  Uso:\n");
	fprintf(stderr, "    %s [opcoes] <arquivo binario>\n\n", nomeprog);
	fprintf(stderr, "  Opcoes:\n");
	fprintf(stderr, "  -o <arq.>     - Salva resultado nesse arquivo.\n");
	fprintf(stderr, "  -n <nome>     - Nome do titulo do programa em 2 bytes hexa (ex. CA01).\n");
	fprintf(stderr, "  -s <endereco> - Indica endereco inicial do arquivo (em hexa).\n");
	fprintf(stderr, "\n");

	exit(0);
}

// =============================================================================
int main(int argc, char *argv[]) {
	FILE *fileBin = NULL, *fileNtf = NULL;
	char *arqBin = NULL, *arqNtf = NULL, *buffer = NULL;
	char *p, nome[2];
	unsigned char checksum = 0;
	unsigned short endI = 0, endF = 0;
	int i, c = 1, fileSize = 0, titulo = 0;

	if (argc < 2)
		mostraUso(argv[0]);

	memset(nome, 0, 2);
	// Interpreta linha de comando
	while (c < argc) {
		if (argv[c][0] == '-' || argv[c][0] == '/') {
			if (c + 1 == argc) {
				if (argv[c][1] == 'o' || argv[c][1] == 'n' || argv[c][1] == 's') {
					fprintf(stderr, "Falta parametro para a opcao %s", argv[c]);
					return 1;
				}
			}
			switch (argv[c][1]) {

			case 'o':
				arqNtf = argv[++c];
				break;

			case 'n':
				++c;
				strncpy(nome, argv[c], MIN(4, strlen(argv[c])));
				break;

			case 's':
				endI = _httoi(argv[++c]);
				break;

			default:
				fprintf(stderr, "Opcao invalida: %s\n", argv[c]);
				return 1;
				break;
			} // switch
		} else
			arqBin = argv[c];
		c++;
	}

	if (!arqBin) {
		fprintf(stderr, "Falta nome do arquivo de entrada.\n");
		return 1;
	}

	if (strlen(nome) != 4 || !testaHexa(nome)) {
		fprintf(stderr, "Titulo do arquivo da fita tem que ter 2 valores HEXA.\n");
		return 1;
	}
	titulo = _httoi(nome);

	if (endI < 0x2000) {
		fprintf(stderr, "Endereco inicial tem que ser maior que 0x1FFF.\n");
		return 1;
	}

	printf("Lendo arquivo '%s'\n", arqBin);
	if (!(fileBin = fopen(arqBin, "rb"))) {
		fprintf(stderr, "Erro ao abrir arquivo %s\n", arqBin);
		return -1;
	}
	fseek(fileBin, 0, SEEK_END);
	fileSize = ftell(fileBin);
	fseek(fileBin, 0, SEEK_SET);

	if (!arqNtf) {
		arqNtf = strdup((const char *)arqBin);
	}
	p = (char *)(arqNtf + strlen(arqNtf));
	while(--p > arqNtf) {
		if (*p == '.') {
			*p = '\0';
			break;
		}
	}
	strcat(arqNtf, ".ntf");
	if (!(fileNtf = fopen(arqNtf, "wb"))) {
		fprintf(stderr, "Erro ao abrir arquivo %s\n", arqNtf);
		return -1;
	}

	// Ler binario
	buffer = (char *)malloc(fileSize + 7);
	fread(buffer+7, 1, fileSize, fileBin);
	fclose(fileBin);
	// Endereco final é endereco inicial + tamanho do binario - 1
	endF = endI + fileSize - 1;

	memcpy(buffer, &titulo, 2);
	memcpy(buffer+2, &endI, 2);
	memcpy(buffer+4, &endF, 2);
	for (i=0; i < fileSize; i++) {
		checksum += buffer[i+7];
	}
	buffer[6] = checksum;

	fwrite("NTF\0", 1, 4, fileNtf);
	fwrite(buffer, 1, fileSize+7, fileNtf);
	fclose(fileNtf);
	free(buffer);

	return 0;
}
