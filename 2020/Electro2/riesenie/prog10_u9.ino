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
}


int interpoluj(int odkial, int kam, int percent)
{
  return odkial + (kam-odkial)*percent/100;
}

void interpoluj(int r1, int g1, int b1, int r2, int g2, int b2)
{
  int i = 0;
  while (i <= 100)
  {
    int r = interpoluj(r1, r2, i);
    int g = interpoluj(g1, g2, i);
    int b = interpoluj(b1, b2, i);
    farba(r, g, b);
    delay(10);
    i = i + 1;
  }
}

void loop() 
{
  interpoluj(148, 0, 211, 74, 0, 130);
  interpoluj(74, 0, 130, 0, 0, 255);
  interpoluj(0, 0, 255, 0, 255, 0);
  interpoluj(0, 255, 0, 255, 255, 0);
  interpoluj(255, 255, 0, 255, 127, 0);
  interpoluj(255, 127, 0, 255, 0, 0);
  interpoluj(255, 0, 0, 148, 0, 211);
}
