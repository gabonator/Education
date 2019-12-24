#include <Ticker.h>

Ticker blinker;

void flip()
{
  bool led = digitalRead(LED_BUILTIN);
  if (led)
    digitalWrite(LED_BUILTIN, 0);
  else
    digitalWrite(LED_BUILTIN, 1);
}

void setup() 
{
    pinMode(LED_BUILTIN, OUTPUT);
    blinker.attach(1, flip);
}

void loop() 
{
}