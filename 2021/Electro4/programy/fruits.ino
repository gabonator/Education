void setup()
{
  Serial.begin(9600);
}

void loop()
{
  int i = rand()%3;
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
  delay(100);
}
