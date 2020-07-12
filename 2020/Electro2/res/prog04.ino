void setup() {
  // put your setup code here, to run once:
  pinMode(8, OUTPUT);
  digitalWrite(8, LOW);
}

void nastav(int red, int green, int blue)
{
  analogWrite(9, green/2); // zelena
  analogWrite(10, blue); // modra
  analogWrite(11, red); // cervena  
}

float uhol = 0;

void loop() 
{
  int r = sin(uhol)*128 + 128;
  nastav(r, 0, 0);

  uhol = uhol + 0.1;
  delay(10);
}