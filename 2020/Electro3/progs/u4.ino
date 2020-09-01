void setup() 
{
  pinMode(LED_BUILTIN, OUTPUT);
  pinMode(2, INPUT);
  digitalWrite(2, HIGH); // zapneme pull-up
  Serial.begin(115200);
}

void loop() 
{
  int vstup = digitalRead(2);
  if (vstup == 1)
  {
    digitalWrite(LED_BUILTIN, HIGH);
    Serial.print("Zapnute\n");
  }
  else
  {
    digitalWrite(LED_BUILTIN, LOW);
    Serial.print("Vypnute\n");
  }
  delay(10);
}
