// Additional Board Manager URLs: 
// https://raw.githubusercontent.com/damellis/attiny/ide-1.6.x-boards-manager/package_damellis_attiny_index.json
// Board: ATtiny25/45/85
// Processor: ATtiny45
// Clock: Internal 1 MHz

/*
    ATTiny45 / ATTiny25
    
    PB5  1   8  VCC (+)
 sw PB3  2   7  PB2
 sw PB4  3   6  PB1 led/pwm
(-) GND  4   5  PB0 led/pwm

*/

#include <avr/sleep.h>
#include <avr/io.h>

enum {SWITCHA=3, SWITCHB=4, LEDA=0, LEDB=1};

void setupLowPower()
{
  #define BODS 7 //BOD Sleep bit in MCUCR
  #define BODSE 2 //BOD Sleep enable bit in MCUCR
  MCUCR |= _BV(BODS) | _BV(BODSE); //turn off the brown-out detector

  ADCSRA &= ~ bit(ADEN); // disable the ADC
  bitSet(PRR, PRADC); // power down the ADC
}

void setupTimers() 
{
  noInterrupts();
  
  // Setup timer1 to interrupt every second
  TCCR1 = 0; // Stop timer
  TCNT1 = 0; // Zero timer
  GTCCR = _BV(PSR1); // Reset prescaler
  OCR1A = 255; // T = prescaler / 1MHz = 0.004096s; OCR1A = (1s/T) - 1 = 243
  OCR1C = 255; // Set to same value to reset timer1 to 0 after a compare match
  TIMSK = _BV(OCIE1A); // Interrupt on compare match with OCR1A
  
  // Start timer in CTC mode; prescaler = 32; 
  // CS13:10  1101 PCK/4096
  //          1000 PCK/128
  //          0111 PCK/64
  //          0110 PCK/32
  TCCR1 = _BV(CTC1) | _BV(CS12) | _BV(CS11); // PCK/32

  // set pwm speed
  TCCR0B &= ~(_BV(CS02) | _BV(CS01) | _BV(CS00));
  TCCR0B |= _BV(CS00);
  interrupts();
}

void stopTimers()
{
  TCCR1 = 0; 
  TCCR0B &= ~(_BV(CS02) | _BV(CS01) | _BV(CS00));
}

volatile byte levela = 0;
volatile byte levelb = 0;
volatile byte tick = 0;
int mode = 0;
int inhibit = 0;
int32_t counter = 0;
int temp = 0;
int dir = 1;
int phase = 0;
int pressed = 0;

void setup() 
{
  setupLowPower();

  // switch
  pinMode(SWITCHB, OUTPUT);
  digitalWrite(SWITCHB, 0);
  pinMode(SWITCHA, INPUT);
  digitalWrite(SWITCHA, 1);

  // led  
  pinMode(LEDA, OUTPUT);
  pinMode(LEDB, OUTPUT);

  digitalWrite(LEDA, LOW);
  digitalWrite(LEDB, HIGH);
 
  setupTimers();
}

ISR(TIM1_COMPA_vect) 
{
  switch (tick++&1)
  {
    case 0:
      pinMode(LEDA, INPUT);
      pinMode(LEDB, INPUT);    
      analogWrite(LEDA, levela);
      digitalWrite(LEDB, LOW);
      pinMode(LEDB, OUTPUT);
      break;
    case 1:    
      pinMode(LEDA, INPUT);//2
      pinMode(LEDB, INPUT);   //2 
      analogWrite(LEDB, levelb);
      digitalWrite(LEDA, LOW);
      pinMode(LEDA, OUTPUT);
      break;
  }
}

void loop() 
{  
  counter++;

  // triangle
  temp += dir;
  if (temp == 1023)
    dir = -1;
  if (temp == 0)
    dir = 1;

  // mode switch
  switch(mode)
  {
    case 0: levela = 255; levelb = 255; break;
    case 1: levela = 63; levelb = 63; break;
    case 2: levela = 1; levelb = 1; break;
    case 3: levela = levelb = max(0, temp/4 -100); break;
    case 4: levela = max(0, temp/4 -100); levelb = max(0, 255-temp/4 -100); break;
    case 5: levela = levelb = ((((counter >> 4) & 15) == 1) || (((counter >> 4) & 15) == 4)) ? 255 : 0; break;
    // hidden modes
    case 10: levela = 255; levelb = 0; break;
    case 11: levela = 0; levelb = 255; break;
    case 12: levela = levelb = ((counter >> 9) & 1) ? 255 : 1; break;
    case 13: levela = levelb = ((counter >> 8) & 1) ? 255 : 1; break;
    case 14: levela = levelb = ((counter >> 7) & 1) ? 255 : 1; break;
    case 15: levela = levelb = ((counter >> 6) & 1) ? 255 : 1; break;
    case 16: levela = levelb = ((counter >> 5) & 1) ? 255 : 1; break;
    case 17: levela = levelb = ((counter >> 4) & 1) ? 255 : 1; break;
    default: mode = 0;
  }

  for (volatile int i=0; i<100; i++); // 2ms?

  bool buttonPressed = digitalRead(SWITCHA) == LOW;
  bool timeout = counter > 500*60*60l*4l; // turn off after 4hours
  bool sleepRequest = false;

  if (buttonPressed)
  {
    pressed++; 
    if (pressed == 750) // holding for 1.5 seconds
    {
      mode++;
    }
    if (pressed == 5000) // holding for 10 seconds
    {
      mode = 10;
    }
  } else
  {
    if (pressed > 0)
    {
      if (pressed > 25 && pressed < 500)  // 50 ms .. 1s
      {
        sleepRequest = true;
      }
      // button released
    }
    pressed = 0;
  }

  
  if (sleepRequest || timeout)
  {
    stopTimers();
    
    pinMode(LEDA, OUTPUT);
    pinMode(LEDB, OUTPUT);
    digitalWrite(LEDA, LOW);
    digitalWrite(LEDB, LOW);
    for (volatile uint16_t i=0; i<20000; i++); // 300ms?
    while (digitalRead(SWITCHA) == LOW);
    for (volatile uint16_t i=0; i<20000; i++);
   
    sleep();

    setupTimers();    
    counter = 0;
    pressed = -500;
  }
}

void sleep() {
  GIMSK |= _BV(PCIE);                     // Enable Pin Change Interrupts
  PCMSK |= _BV(PCINT3);                   // Use PB3 as interrupt pin   
  ADCSRA &= ~_BV(ADEN);                   // ADC off
  set_sleep_mode(SLEEP_MODE_PWR_DOWN);    // replaces above statement
  sleep_enable();                         // Sets the Sleep Enable bit in the MCUCR Register (SE BIT)
  sei();                                  // Enable interrupts
  sleep_cpu();                            // sleep
  
  cli();                                  // Disable interrupts    
  PCMSK &= ~_BV(PCINT3);                  // Turn off PB3 as interrupt pin
  sleep_disable();                        // Clear SE bit
  //ADCSRA |= _BV(ADEN);                    // ADC on
  sei();                                  // Enable interrupts
}

ISR(PCINT0_vect) 
{
  // must be here, otherwise it restarts the program instead of resuming
}
