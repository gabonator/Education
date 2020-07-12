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
  analogWrite(3, 20);
  analogWrite(5, 10);
  analogWrite(6, 30);
}