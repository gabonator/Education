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
  int r = sin(uhol)*127 + 128;
  int g = sin(uhol*1.3)*127 + 128;
  int b = sin(uhol*1.7)*127 + 128;
  nastav(r, g, b);

  uhol = uhol + 0.01;
  delay(10);
}