#include <TimerOne.h>

int faADC  = 200;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(250000);
  Timer1.initialize(1000000/faADC);             
  Timer1.attachInterrupt(readADC);                             
}

void loop() {
}

void readADC() {
  int ch0Value = analogRead(0);
  int ch1Value = analogRead(1);
  int ch2Value = analogRead(2);
  int ch3Value = analogRead(3);
  int ekgValue = ch0Value - ch1Value;
  
  unsigned long t = millis();
  Serial.print("EKG:");
  Serial.print(ekgValue);
  Serial.print(",t:");
  Serial.println(t);
  Serial.print("CH0:");
  Serial.print(ch0Value);
  Serial.print(",t:");
  Serial.println(t);
  Serial.print("CH1:");
  Serial.print(ch1Value);
  Serial.print(",t:");
  Serial.println(t);
  // Serial.print("CH2:");
  // Serial.print(ch2Value);
  // Serial.print(",t:");
  // Serial.println(t);
  // Serial.print("CH3:");
  // Serial.print(ch3Value);
  // Serial.print(",t:");
  // Serial.println(t);}
}

void serialEvent() {
  char inChar = Serial.read();
  if (inChar == 's') {   // 's'top
    Timer1.stop();
  }
  if (inChar == 't') {   //  restar't'
    Timer1.restart();
  }
}