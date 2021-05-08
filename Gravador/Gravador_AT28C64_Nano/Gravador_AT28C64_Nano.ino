/* =========================================================================================================
 *  
   Gravador de EEPROM com Arduino Nano (old)

   Compilador: Arduino IDE 1.8.13

   Autor: Diego Cruz
   Data: Abril de 2021
   
   Adaptação do código WR Kits
   Link: https://www.youtube.com/watch?v=iJG7BMKUUQY
   
========================================================================================================= */

 
// =========================================================================================================
// --- Mapeamento de Hardware ---
#define    shift_data     10    //dados do shift register 74HC595
#define    shift_latch    11    //latch do shift register 74HC595
#define    shift_clk      12    //clock do shift register 74HC595
#define    EEPROM_D0       2    //bit menos significativo de dados da EEPROM
#define    EEPROM_D7       9    //bit mais significativo de dados da EEPROM
#define    write_en       13    //sinal de escrita para EEPROM
#define    led_green      A2    // led status - reading
#define    led_yellow     A1    // led status - writing
#define    led_red        A0    // led status - erasing





int MEM_ORG = 2000; // .org in decimal






// AT28C64 - Total: 8191
#define sizeToErase 500

// =========================================================================================================
// --- Protótipo das Funções ---
void setAddress(int address);               //função para seleção do endereço
byte readEEPROM(int address);               //função para leitura da EEPROM
byte writeEEPROM(int address, byte data);   //função para escrita da EEPROM
void printData();                           //função para imprimir os dados no monitor serial
void eraseEEPROM();                         //função para apagar EEPROM


// =========================================================================================================
// --- Preencha o vetor com os dados que deseja escrever na EEPROM ---
#include "data.h"

// =========================================================================================================
// --- Configurações Iniciais ---
void setup() 
{
   delay(15000); // REMOVER E COLOCAR UM PUSH BUTTON
    
   pinMode(shift_latch, OUTPUT);   //saída para latch
   pinMode(shift_data,  OUTPUT);   //saída para dados
   pinMode(shift_clk,   OUTPUT);   //saída para clock

   pinMode(led_green, OUTPUT);    // saida de status
   pinMode(led_yellow, OUTPUT);   // saida de status
   pinMode(led_red, OUTPUT);      // saida de status

   // Desliga leds de status
   digitalWrite(led_green, LOW); 
   digitalWrite(led_yellow, LOW);
   digitalWrite(led_red, LOW);

   digitalWrite(write_en, HIGH);   //pullup interno em write_en
   pinMode(write_en, OUTPUT);      //saída para write_en

   Serial.begin(9600);           //inicializa Serial em 250000 bits por segundo

   //eraseEEPROM();                  //apaga EEPROM
   
// ======================= ESCREVE DADOS =========================

   //escreve nos endereços da EEPROM 
   digitalWrite(led_yellow, HIGH);
   int mem_data = MEM_ORG + dataSize;
   for(int address = MEM_ORG; address < mem_data; address += 1) {
    writeEEPROM(address, data[address - MEM_ORG]);
   }
   digitalWrite(led_yellow, LOW);

// ===============================================================
    
   //printData();                    //imprime o conteúdo da EEPROM no monitor serial
  

} //end setup






// =========================================================================================================
// --- Loop Infinito ---
void loop() 
{
   //nenhum processamento em loop infinito
} //end loop

// =========================================================================================================


// --- Desenvolvimento das Funções ---


void setAddress(int address, bool outEnable)
{
   // Seleciona os 3 bits mais significativos de endereço com bit outEnable
   shiftOut(shift_data, shift_clk, MSBFIRST, (address >> 8) | (outEnable ? 0x00 : 0x80));
   
   //Seleciona os 8 bits menos significativos de endereço
   shiftOut(shift_data, shift_clk, MSBFIRST, address);

   //gera pulso de latch para escrever dados nas saídas dos shift registers
   digitalWrite(shift_latch,  LOW);
   digitalWrite(shift_latch, HIGH);
   digitalWrite(shift_latch,  LOW);
  
} //end setAddress


byte readEEPROM(int address)
{
   //configura pinos de dados como entrada
   for(int pin = EEPROM_D0; pin <= EEPROM_D7; pin += 1)
    pinMode(pin, INPUT);
     
   setAddress(address, true);   //seleciona endereço para leitura
   
   byte data = 0;               //variável local para armazenar dados
   
   //realiza a leitura dos dados
   for(int pin = EEPROM_D7; pin >= EEPROM_D0; pin -=1)
    data = (data << 1) + digitalRead(pin);
    
   return data;                 //retorna o dado lido
  
} //end readEEPROM


byte writeEEPROM(int address, byte data)
{
   //configura os pinos de dados como saída
   for(int pin = EEPROM_D0; pin <= EEPROM_D7; pin += 1)
    pinMode(pin, OUTPUT);
    
   setAddress(address, false);   //seleciona endereço para escrita

   //envia os dados para as saídas
   for(int pin = EEPROM_D0; pin <= EEPROM_D7; pin += 1)
   {
      digitalWrite(pin, data & 1);
      data = data >> 1;
    
   } //end for

   //gera o pulso de escrita
   digitalWrite(write_en, LOW);
   delayMicroseconds(1);
   digitalWrite(write_en, HIGH);
   delay(10);
} //end writeEEPROM


//void printData()
//{
//   //imprime os primeiros 256 endereços de dados
//   digitalWrite(led_green, HIGH);
//   for(int base = 0; base <=dataSize; base += 16)
//   {
//     byte data[16];
//     
//     for(int offset = 0; offset <= 15; offset += 1)
//      data[offset] = readEEPROM(base + offset);
//  
//   char buf[80];
//     sprintf(buf, "%03x: %02x %02x %02x %02x %02x %02x %02x %02x  %02x %02x %02x %02x %02x %02x %02x %02x",
//       base, data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7], 
//       data[8], data[9], data[10], data[11], data[12], data[13], data[14], data[15]);
//
//     Serial.println(buf);
// 
//   } //end for
//   digitalWrite(led_green, LOW);
//} //end printData
//
//
//void eraseEEPROM()
//{
//   // AT28C64 - Total: 8191
//   digitalWrite(led_red, HIGH);
//   for(int address = 0; address <= sizeToErase; address += 1)   //apaga EEPROM escrevendo FFh em
//   writeEEPROM(address, 0xFF);                           //todos os endereços 
//   digitalWrite(led_red, LOW);
//} //end eraseEEPROM
