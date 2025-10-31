void setup() {
  // put your setup code here, to run once:
  analogReference(EXTERNAL);
  Serial.begin(250000);
}

void loop() {
  // put your main code here, to run repeatedly:
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
  Serial.print("CH2:");
  Serial.print(ch2Value);
  Serial.print(",t:");
  Serial.println(t);
  Serial.print("CH3:");
  Serial.print(ch3Value);
  Serial.print(",t:");
  Serial.println(t);
  delay(5);
}
