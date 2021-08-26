/*  PS2Keyboard library, International Keyboard Layout Example
    http://www.pjrc.com/teensy/td_libs_PS2Keyboard.html

    keyboard.begin() accepts an optional 3rd parameter to
    configure the PS2 keyboard layout.  Uncomment the line for
    your keyboard.  If it doesn't exist, you can create it in
    PS2Keyboard.cpp and email paul@pjrc.com to have it included
    in future versions of this library.


    Diego Cruz - 08/2021
*/
   
#include <PS2Keyboard.h>

const int DataPin = 2;
const int IRQpin =  3;
const int IntPin = 13;

const  byte pins [8] = {8, 7, 6, 5, 9, 10, 11, 12};

PS2Keyboard keyboard;

void setup() {
  for (int p = 0; p < 8; ++p) {
    pinMode(pins [p], OUTPUT);
  }
  
  keyboard.begin(DataPin, IRQpin, PS2Keymap_US);
  //keyboard.begin(DataPin, IRQpin, PS2Keymap_German);
  //keyboard.begin(DataPin, IRQpin, PS2Keymap_French);
  //Serial.begin(9600);
  //Serial.println("International Keyboard Test:");

  pinMode(IntPin, OUTPUT);
  digitalWrite(IntPin, HIGH);
}

void loop() {
  if (keyboard.available()) {
    char c = keyboard.read();
    //Serial.write(c);
  
    for (int bit = 7; bit >= 0; bit--)
    {
      digitalWrite(pins[bit], bitRead(c, bit));
    }

    
    delay(1);
    digitalWrite(IntPin, LOW);
    delay(1);
    digitalWrite(IntPin, HIGH);
    delay(50);

    c = 0;
    for (int bit = 7; bit >= 0; bit--)
    {
      digitalWrite(pins[bit], LOW);
    }
  }
}
