void setup() 
{
  pinMode(LED_BUILTIN, OUTPUT);
  pinMode(2, INPUT);
  digitalWrite(2, HIGH); // zapneme pull-up
  Serial.begin(115200);
}

int bolStlaceny = 0;

void loop() 
{
  int stlaceny = digitalRead(2);
  if (stlaceny == 1)
  {
    if (bolStlaceny == 0)
    {
      Serial.print("Stlacil\n");
      bolStlaceny = 1;
    }
  }
  else
  {
    if (bolStlaceny == 1)
    {
      Serial.print("Pustil\n");
      bolStlaceny = 0;
    }
  }
}
