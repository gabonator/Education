void setup() 
{
  pinMode(3, OUTPUT); // zelena
  pinMode(4, OUTPUT);
  pinMode(5, OUTPUT); // modra
  pinMode(6, OUTPUT); // cervena
  digitalWrite(4, LOW);
}

void loop() 
{
  digitalWrite(3, 0);
  digitalWrite(5, 0);
  digitalWrite(6, 0);
  delay(5000);
  digitalWrite(3, 0);
  digitalWrite(5, 0);
  digitalWrite(6, 1);
  delay(5000);
  digitalWrite(3, 0);
  digitalWrite(5, 1);
  digitalWrite(6, 0);
  delay(5000);
  digitalWrite(3, 1);
  digitalWrite(5, 0);
  digitalWrite(6, 0);
  delay(5000);
  digitalWrite(3, 1);
  digitalWrite(5, 0);
  digitalWrite(6, 1);
  delay(5000);
  digitalWrite(3, 1);
  digitalWrite(5, 1);
  digitalWrite(6, 0);
  delay(5000);
  digitalWrite(3, 1);
  digitalWrite(5, 1);
  digitalWrite(6, 1);
  delay(5000);
}
