void setup() {
  // put your setup code here, to run once:
  pinMode(8, OUTPUT);
  digitalWrite(8, LOW);
}

void loop() {
  // put your main code here, to run repeatedly:
  analogWrite(9, 5); // zelena
  analogWrite(10, 5);
  analogWrite(11, 5); // cervena
}