void setup()
{
  Serial.begin(9600);
}

void loop()
{
  int i = rand() % 4;
  if (i==0)
  {
    Serial.println("jablka");
  }
  if (i==1)
  {
    Serial.println("hrusky");
  }
  if (i==2)
  {
    Serial.println("maliny");
  }
  if (i==3)
  {
    Serial.println("cucoriedky");
  }
  delay(100);
}
