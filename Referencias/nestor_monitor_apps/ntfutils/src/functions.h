/*
 * functions.h
 *
 *  Created on: 24/05/2011
 *      Author: Fabio Belavenuto
 */

#ifndef FUNCTIONS_H_
#define FUNCTIONS_H_

char *trim(char *s);
char *extractFileName(char *s);
char *cleanFN(char *s);
int testaHexa(char *value);
int _httoi(char *value);
void dec2hex(unsigned short hex, char *txt);

#endif /* FUNCTIONS_H_ */
