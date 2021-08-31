# Z80 Single Board Computer
Running Microsoft BASIC 4.7b by Grant Searle (http://searle.x10host.com/z80/SimpleZ80_32K.html)
- with my boot settings to work the lcd and keyboard without serial port chip

Z80 - (4Mhz)
ROM - AT27C256 (32kb)        - 0000h - 7FFFh
RAM - 62256    (32kb)        - 8000h - FFFFh

LCD 20x4 (4 bits Mode)      -  01h
Teclado (USB + PS2)         -  01h

OnBoard_In  + AudioTape(B0) -  02h
OnBoard_Out + AudioTape(B0) -  02h


![Z80 - Main board](https://github.com/diego123cruz/Z80_microprocessador/blob/main/img/main.jpeg)
