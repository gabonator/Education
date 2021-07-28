void setup()
{
  Serial.begin(9600);

  pinMode(D8, OUTPUT);
  digitalWrite(D8, LOW);
  pinMode(D7, INPUT_PULLUP);

  pinMode(D6, OUTPUT);
  digitalWrite(D6, LOW);
  pinMode(D5, INPUT_PULLUP);
}

void loop()
{
  Serial.print("tlacidlo1=");
  if (digitalRead(D7)==LOW)
    Serial.print("zapnute");
  else
    Serial.print("vypnute");

  Serial.print(",tlacidlo2=");
  if (digitalRead(D5)==LOW)
    Serial.print("zapnute");
  else
    Serial.print("vypnute");
  Serial.print("\n");

  delay(100);
}