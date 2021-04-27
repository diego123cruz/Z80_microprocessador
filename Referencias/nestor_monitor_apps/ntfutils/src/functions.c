/*
 * functions.c
 *
 *  Created on: 11/12/2013
 *      Author: Fabio Belavenuto
 */

#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include "functions.h"

// ============================================================================
char *trim(char *s) {
	char *ptr;
	if (!s)
		return NULL; // handle NULL string
	if (!*s)
		return s; // handle empty string
	for (ptr = s + strlen(s) - 1; (ptr >= s) && (*ptr == ' '); --ptr)
		;
	ptr[1] = '\0';
	return s;
}

// ============================================================================
char *extractFileName(char *s) {
	char *ptr = s + strlen(s);
	while(--ptr > s) {
		if (*ptr == '\\' || *ptr == '/')
			return ptr+1;
	}
	return s;
}

// ============================================================================
char *cleanFN(char *s) {
	char *ptr = s;
	while (*ptr) {
		if (*ptr == '\\' || *ptr == '/' || *ptr == ':' || *ptr == '*' || *ptr
				== '?' || *ptr == '"' || *ptr == '<' || *ptr == '>' || *ptr
				== '|') {
			*ptr = '_';
		}
		ptr++;
	}
	return s;
}

// ============================================================================
int testaHexa(char *value) {
	const unsigned char HexMap[16] = "0123456789ABCDEF" ;
	char *temp = strdup((const char *)value);
	char *s = temp;
	int i, found = 0;

	while(*s) {
		*s = toupper(*s);
		s++;
	}
	s = temp;
	if (*s == '0' && *(s + 1) == 'X')
		s += 2;
	while (*s) {
		found = 0;
		for (i = 0; i < 16; i++) {
			if (*s == HexMap[i]) {
				found = 1;
				break;
			}
		}
		if (!found)
			break;
		s++;
	}
	free(temp);
	return found;
}

// ============================================================================
int _httoi(char *value) {
	const unsigned char HexMap[16] = "0123456789ABCDEF" ;
	int i, result = 0;
	char *temp = strdup((const char *)value);
	char *s = temp;

	while(*s) {
		*s = toupper(*s);
		s++;
	}
	s = temp;
	if (*s == '0' && *(s + 1) == 'X')
		s += 2;
	while (*s) {
		int found = 0;
		for (i = 0; i < 16; i++) {
			if (*s == HexMap[i]) {
				result <<= 4;
				result |= i;
				found = 1;
				break;
			}
		}
		if (!found)
			break;
		s++;
	}
	free(temp);
	return result;
}

// ============================================================================
void dec2hex(unsigned short hex, char *txt)
{
	int i;
	unsigned char x;

	for (i=0; i < 4; i++) {
		//
		x = (hex & 0xF000) >> 12;
		if (x < 10) {
			txt[i] = '0' + x;
		} else {
			txt[i] = 'A' + (x - 10);
		}
		hex <<= 4;
	}
}

