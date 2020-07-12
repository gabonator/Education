void setup() 
{
  Serial.begin(9600);
}

void loop() 
{
  int x = 0;
  Serial.print("Vypisujem cisla od 0 po 10:\n");
  while (x<=10)
  {
    Serial.print("x=");
    Serial.print(x);
    Serial.print("\n");
    x = x + 1;
  }
  delay(5000);
}