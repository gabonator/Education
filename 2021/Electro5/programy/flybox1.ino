#include <Arduino.h>
#include <U8g2lib.h>
#include <Wire.h>

U8G2_SH1106_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, U8X8_PIN_NONE, SCL, SDA);

void setup()
{
  u8g2.begin();            
}

int bx = 128/2-5;
int by = 64/2-5;
int direction = 1;

void loop()
{
  u8g2.clearBuffer();

  u8g2.drawFrame(0, 0, 128, 64);
  u8g2.drawFrame(bx, by, 10, 10);

  bx = bx + direction;

  if (bx+10 >= 127)
    direction = -1;
  if (bx <= 1)
    direction = 1;

  u8g2.sendBuffer();
}
