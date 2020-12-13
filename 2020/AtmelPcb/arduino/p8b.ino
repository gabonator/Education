#include <avr/sleep.h>

enum {LED1 = 0, LED2 = 1, LED3 = 3, LED4 = 2, LED5 = 8, SWITCH = 10};
int leds[] = {LED1, LED2, LED3, LED4, LED5};
 
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

  setupLowPower();
}

void loop() 
{
  for (int i=0; i<5; i++)
  {
    digitalWrite(leds[i], 1);
    delay(20);
    digitalWrite(leds[i], 0);
    delay(180);
    
    if (digitalRead(SWITCH) == 0) 
    {
      delay(500);
      sleep();
    }
  }
}





void setupLowPower()
{
  #define BODS 7 //BOD Sleep bit in MCUCR
  #define BODSE 2 //BOD Sleep enable bit in MCUCR
  MCUCR |= _BV(BODS) | _BV(BODSE); //turn off the brown-out detector
  ADCSRA &= ~ bit(ADEN); // disable the ADC
  bitSet(PRR, PRADC); // power down the ADC
}

void sleep() 
{
    GIMSK |= _BV(PCIE1);                     // Enable Pin Change Interrupts
    PCMSK1 |= _BV(PCINT8);                   // Use PB3 as interrupt pin   
    set_sleep_mode(SLEEP_MODE_PWR_DOWN);    // replaces above statement
    sleep_enable();                         // Sets the Sleep Enable bit in the MCUCR Register (SE BIT)
    sei();                                  // Enable interrupts
    sleep_cpu();                            // sleep
    
    cli();                                  // Disable interrupts    
    PCMSK1 &= ~_BV(PCINT8);                  // Turn off PB3 as interrupt pin
    sleep_disable();                        // Clear SE bit
    sei();                                  // Enable interrupts
}

ISR(PCINT1_vect) 
{
}
