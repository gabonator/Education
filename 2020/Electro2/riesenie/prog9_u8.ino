void setup() 
{
  pinMode(3, OUTPUT); // zelena
  pinMode(4, OUTPUT);
  pinMode(5, OUTPUT); // modra
  pinMode(6, OUTPUT); // cervena
  digitalWrite(4, LOW);
}

void farba(int r, int g, int b)
{
  analogWrite(6, r);
  analogWrite(3, g/2);
  analogWrite(5, b);
  delay(1000);
}

void loop() 
{
  farba(148, 0, 211);
  farba(74, 0, 130);
  farba(0, 0, 255);
  farba(0, 255, 0);
  farba(255, 255, 0);
  farba(255, 127, 0);
  farba(255, 0, 0);
}
