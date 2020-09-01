void setup() 
{
  pinMode(LED_BUILTIN, OUTPUT);
  pinMode(9, OUTPUT); // prvy riadok   1-2-3-A
  pinMode(5, INPUT);  // prvy stlpec   1-4-7-*
  pinMode(4, INPUT);  // druhy stlpec  2-5-8-0
  pinMode(3, INPUT);  // treti stlpec  3-6-9-#
  pinMode(2, INPUT);  // stvrty stlpec A-B-C-D
  digitalWrite(5, HIGH);
  digitalWrite(4, HIGH);
  digitalWrite(3, HIGH);
  digitalWrite(2, HIGH);
  Serial.begin(9600);
}

void loop() 
{
  // dopln
}
