void setup() 
{
  pinMode(LED_BUILTIN, OUTPUT);
  pinMode(2, INPUT);
}

void loop() 
{
  int vstup = digitalRead(2);
  if (vstup == 1)
  {
    digitalWrite(LED_BUILTIN, HIGH);
  }
  else
  {
    digitalWrite(LED_BUILTIN, LOW);
  }
}
