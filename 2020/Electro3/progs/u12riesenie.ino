void setup() 
{
  pinMode(LED_BUILTIN, OUTPUT);
  pinMode(5, INPUT);  // prvy stlpec   1-4-7-*
  pinMode(4, INPUT);  // druhy stlpec  2-5-8-0
  pinMode(3, INPUT);  // treti stlpec  3-6-9-#
  pinMode(2, INPUT);  // stvrty stlpec A-B-C-D
  digitalWrite(5, HIGH);
  digitalWrite(4, HIGH);
  digitalWrite(3, HIGH);
  digitalWrite(2, HIGH);
  Serial.begin(9600);
  Serial.print("Uhadni rok kedy som sa narodil\n");
}

char klavesa = ' ';
char klavesa1 = ' ';
char klavesa2 = ' ';
char klavesa3 = ' ';

void TestujRiadok(int riadok, char a, char b, char c, char d)
{
  pinMode(riadok, OUTPUT);

  if (digitalRead(5) == 0)
    klavesa = a;

  if (digitalRead(4) == 0)
    klavesa = b;

  if (digitalRead(3) == 0)
    klavesa = c;    

  if (digitalRead(2) == 0)
    klavesa = d;    

  pinMode(riadok, INPUT);  
}

void loop() 
{
  klavesa = ' ';
  TestujRiadok(9, '1', '2', '3', 'A');
  TestujRiadok(8, '4', '5', '6', 'B');
  TestujRiadok(7, '7', '8', '9', 'C');
  TestujRiadok(6, '*', '0', '#', 'D');
  if (klavesa != ' ')
  {
    Serial.print("Posledne styri znaky: ");
    Serial.print(klavesa3);
    Serial.print(klavesa2);
    Serial.print(klavesa1);
    Serial.print(klavesa);

    if (klavesa3 == '1' && klavesa2 == '9' && 
        klavesa1 == '8' && klavesa == '5')
    {
      Serial.print(" Uhadol si heslo!");
      digitalWrite(LED_BUILTIN, HIGH);
    } else 
    {
      digitalWrite(LED_BUILTIN, LOW);      
    }
    
    klavesa3 = klavesa2;
    klavesa2 = klavesa1;
    klavesa1 = klavesa;
    Serial.print("\n");
    delay(300);
  }
}
