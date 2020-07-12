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
  int i = 0;
  while (i<=255)
  {
    analogWrite(5, 255-i);  
    analogWrite(6, i);
    delay(10);
    i = i + 1;
  }
  i = 255;
  while (i>=0)
  {
    analogWrite(5, 255-i);  
    analogWrite(6, i);
    delay(10);
    i = i - 1;
  }
}