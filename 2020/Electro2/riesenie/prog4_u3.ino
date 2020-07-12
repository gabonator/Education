void setup() 
{
  Serial.begin(9600);
}

int interpoluj(int odkial, int kam, int percent)
{
  return odkial + (kam-odkial)*percent/100;
}

void loop() 
{
  int x = 0;
  Serial.print("Vypisujem cisla od 0 po 100 s krokom 5:\n");
  while (x<=100)
  {
    Serial.print("x=");
    Serial.print(x);

    int y = interpoluj(50, 10, x);
    Serial.print(" y=");
    Serial.print(y);
    Serial.print("\n");

    x = x + 5;
  }
  delay(5000);
}
