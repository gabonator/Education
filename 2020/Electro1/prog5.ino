int zelena = 6;
int oranzova = 4;
int cervena = 2;

void setup() {
  // put your setup code here, to run once:
  pinMode(7, OUTPUT);
  pinMode(6, OUTPUT);
  pinMode(5, OUTPUT);
  pinMode(4, OUTPUT);
  pinMode(3, OUTPUT);
  pinMode(2, OUTPUT);

  digitalWrite(zelena, LOW);
  digitalWrite(oranzova, LOW);
  digitalWrite(cervena, LOW);
}

void loop() {
  // put your main code here, to run repeatedly:
  digitalWrite(cervena, HIGH);
  delay(5000);
  digitalWrite(cervena, LOW);
  digitalWrite(oranzova, HIGH);
  delay(2000);
  digitalWrite(oranzova, LOW);
  digitalWrite(zelena, HIGH);
  delay(5000);
  digitalWrite(zelena, LOW);
  digitalWrite(oranzova, HIGH);
  delay(1000);
  digitalWrite(oranzova, LOW);
  delay(500);
  digitalWrite(oranzova, HIGH);
  delay(500);
  digitalWrite(oranzova, LOW);
  delay(500);
  digitalWrite(oranzova, LOW);
}






