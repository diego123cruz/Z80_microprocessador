// Teclado 03/2021

#define Ln1 A0
#define Ln2 A1
#define Ln3 A2
#define Ln4 A3

#define Cl1 10
#define Cl2 11
#define Cl3 12
#define Cl4 13

#define b0 9
#define b1 8
#define b2 7
#define b3 6
#define b4 5
#define b5 4
#define b6 3
#define b7 2


#define colSize 4
#define rowSize 4

byte lastByte = 0x00;

int col[colSize] = {Cl1, Cl2, Cl3, Cl4};
int row[rowSize] = {Ln1, Ln2, Ln3, Ln4};

byte teclas[rowSize][colSize] = { {0x87, 0x88, 0x89, 0x8A},
                      {0x84, 0x85, 0x86, 0x8B},
                      {0x81, 0x82, 0x83, 0x8C},
                      {0x80, 0x8F, 0x8E, 0x8D}
                      };

void setup() {
  // Define pinMode colunas
  for(int i = 0; i < colSize; i++) {
    pinMode(col[i], OUTPUT);
  }

  // Define pinMode linhas
  for(int i = 0; i < rowSize; i++) {
    pinMode(row[i], INPUT_PULLUP);
  }

  // output
  pinMode(b0, OUTPUT);
  pinMode(b1, OUTPUT);
  pinMode(b2, OUTPUT);
  pinMode(b3, OUTPUT);
  pinMode(b4, OUTPUT);
  pinMode(b5, OUTPUT);
  pinMode(b6, OUTPUT);
  pinMode(b7, OUTPUT);

  Serial.begin(9600);
}

byte getKey() {
  
  for(int c = 0; c < colSize; c++){
    digitalWrite(Cl1, HIGH);
    digitalWrite(Cl2, HIGH);
    digitalWrite(Cl3, HIGH);
    digitalWrite(Cl4, HIGH);
    digitalWrite(col[c], LOW);
    for(int l = 0; l < rowSize; l++) {
      bool rowRead = digitalRead(row[l]);
      if (rowRead == LOW) {
        return teclas[l][c];
      }
    }
  }
  return 0x00;
}

void writeOutput(byte key) {
  digitalWrite(b0, bitRead(key, 0));
  digitalWrite(b1, bitRead(key, 1));
  digitalWrite(b2, bitRead(key, 2));
  digitalWrite(b3, bitRead(key, 3));
  digitalWrite(b4, bitRead(key, 4));
  digitalWrite(b5, bitRead(key, 5));
  digitalWrite(b6, bitRead(key, 6));
  digitalWrite(b7, bitRead(key, 7));
}

void loop() {
  byte key = getKey();
  if (key != lastByte) {
    Serial.println(key, HEX);
    writeOutput(key);
    lastByte = key;
  }
  delay(100);
}
