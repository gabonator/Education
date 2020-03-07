void setup() {
  // put your setup code here, to run once:
  pinMode(7, OUTPUT);
  pinMode(6, OUTPUT);
  pinMode(5, OUTPUT);
  pinMode(4, OUTPUT);
  pinMode(3, OUTPUT);
  pinMode(2, OUTPUT);

  digitalWrite(7, LOW);
  digitalWrite(5, LOW);
  digitalWrite(3, LOW);
}

void loop() {
  // put your main code here, to run repeatedly:
  digitalWrite(6, HIGH);
  digitalWrite(4, HIGH);
  digitalWrite(2, HIGH);
}





