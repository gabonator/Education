void setup() 
{
  pinMode(LED_BUILTIN, OUTPUT);
  pinMode(9, OUTPUT); // prvy riadok 1-2-3-A
  pinMode(5, INPUT);  // prvy stlpec 1-4-7-*
  digitalWrite(5, HIGH);
}

void loop() 
{
  int klavesa1 = digitalRead(5);
  digitalWrite(LED_BUILTIN, 1 - klavesa1);
}
