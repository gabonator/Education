void setup() {
  // put your setup code here, to run once:
  pinMode(8, OUTPUT);
  digitalWrite(8, LOW);
}

void nastav(int red, int green, int blue)
{
  analogWrite(9, green/2); // zelena
  analogWrite(10, blue); // modra
  analogWrite(11, red); // cervena  
}

void loop() {
  nastav(200, 0, 0);
  delay(1000);
  nastav(0, 200, 0);
  delay(1000);
  nastav(0, 0, 200);
  delay(1000);
}