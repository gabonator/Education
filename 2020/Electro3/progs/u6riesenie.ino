void setup() 
{
  pinMode(LED_BUILTIN, OUTPUT);
  pinMode(2, INPUT);
  digitalWrite(2, HIGH); // zapneme pull-up
  Serial.begin(115200);
}

int bolStlaceny = 0;
int ledka = 0;

void loop() 
{
  int stlaceny = digitalRead(2);
  if (stlaceny == 1)
  {
    if (bolStlaceny == 0)
    {
      Serial.print("Stlacil\n");
      bolStlaceny = 1;
      delay(50);

      // prepinanie ledky
      if (ledka == 0)
      {
        digitalWrite(LED_BUILTIN, 1);
        ledka = 1;
      } else
      {
        digitalWrite(LED_BUILTIN, 0);
        ledka = 0;
      }

      /*
      alebo:
      ledka = 1 - ledka;
      digitalWrite(LED_BUILTIN, ledka);
       */
    }
  }
  else
  {
    if (bolStlaceny == 1)
    {
      Serial.print("Pustil\n");
      bolStlaceny = 0;
      delay(50);
    }
  }
}
