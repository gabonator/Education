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

int interpoluj(int odkial, int kam, int percent)
{
  return odkial + (kam-odkial)*percent/100;
}

void prechod(int r1, int g1, int b1, int r2, int g2, int b2)
{
  for (int percent=0; percent<=100; percent++)
  {
    int r = interpoluj(r1, r2, percent);
    int g = interpoluj(g1, g2, percent);
    int b = interpoluj(b1, b2, percent);
    nastav(r, g, b);
    delay(10);
  }
}

void loop() {
  prechod(200, 0, 0,   0, 200 ,0);
  prechod(0, 200, 0,   0, 0, 200);
  prechod(0, 0, 200,   200, 0, 0);
}
