enum {LED1 = 0, LED2 = 1, LED3 = 3, LED4 = 2, LED5 = 8, SWITCH = 10};

volatile uint8_t counter = 0;
volatile uint8_t level1 = 0;
volatile uint8_t level2 = 0;
volatile uint8_t level3 = 0;
volatile uint8_t level4 = 0;
volatile uint8_t level5 = 0;

void setup() 
{
  pinMode(SWITCH, INPUT);
  digitalWrite(SWITCH, 1);
  pinMode(LED1, OUTPUT);
  pinMode(LED2, OUTPUT);
  pinMode(LED3, OUTPUT);
  pinMode(LED4, OUTPUT);
  pinMode(LED5, OUTPUT);
  digitalWrite(LED1, 0);
  digitalWrite(LED2, 0);
  digitalWrite(LED3, 0);
  digitalWrite(LED4, 0);
  digitalWrite(LED5, 0);

  setupPwm();
}


int l1 = 0, l2 = 0, l3 = 0, l4 = 0, l5 = 0;
int d1 = 39, d2 = 51, d3 = 27, d4 = 15, d5 = 12;

void upd(int &l, int& d, volatile uint8_t& r)
{
  l = l + d;
  if (l > 128*16) 
  { 
    l = 128*16; 
    d = -d; 
  }
  if (l < 0) 
  { 
    l = 0; 
    d = -d; 
  }
  
  int x = l / 16;

  x = x - 32 - 64;
  if (x >= 0)
  {
    r = x;
  } else
  {
    r = 0;
  }
}

void loop() 
{
  upd(l1, d1, level1);
  upd(l2, d2, level2);
  upd(l3, d3, level3);
  upd(l4, d4, level4);
  upd(l5, d5, level5);
  delay(5);
}






// software pwm
void setupPwm() 
{
  noInterrupts();
  // Clear registers
  TCCR1A = 0;
  TCCR1B = 0;
  TCNT1 = 0;

  // 1 Hz (1000000/((15624+1)*64))
  OCR1A = 2;
  // CTC
  TCCR1B |= (1 << WGM12);
  // Prescaler 64
  //TCCR1B |= (1 << CS11) | (1 << CS10);
  // Prescaler 1
  TCCR1B |= (1 << CS10);
  // Output Compare Match A Interrupt Enable
  TIMSK1 |= (1 << OCIE1A);
  interrupts();
}

ISR(TIM1_COMPA_vect) 
{
  uint8_t b = counter++;
  b = (b & 0xF0) >> 4 | (b & 0x0F) << 4;
  b = (b & 0xCC) >> 2 | (b & 0x33) << 2;
  b = (b & 0xAA) >> 1 | (b & 0x55) << 1;
  uint8_t v = 0;
  v |= (b < level1) << 0;
  v |= (b < level2) << 1;
  v |= (b < level3) << 3;
  v |= (b < level4) << 2;
  PORTA = v;
  v = 1;
  v |= (b < level5) << 2;
  PORTB = v;
}
