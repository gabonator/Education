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


/*
// Mozeme aj takto:
void loop() 
{
  if (digitalRead(2) == 1)
  {
    digitalWrite(LED_BUILTIN, HIGH);
  }
  else
  {
    digitalWrite(LED_BUILTIN, LOW);
  }
}

// Alebo takto, pretoze HIGH je konstanta rovna 1, LOW rovna 0, 
// LED_BUILTIN = 13
// digitalRead vracia hodnotu 0 alebo 1
void loop() 
{
  digitalWrite(LED_BUILTIN, digitalRead(2));
}

*/