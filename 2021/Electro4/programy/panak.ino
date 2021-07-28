#include <Arduino.h>
#include <U8g2lib.h>
#include <Wire.h>

U8G2_SH1106_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, U8X8_PIN_NONE, SCL, SDA);

void setup()
{
  u8g2.begin();
  u8g2.clearBuffer();

  u8g2.drawCircle(40, 20, 5);
  u8g2.drawLine(40, 25, 40, 45);
  u8g2.drawLine(40, 45, 50, 60);
  u8g2.drawLine(40, 45, 30, 60);
  u8g2.drawLine(30, 30, 50, 30);
  u8g2.sendBuffer();
}

void loop()
{
}

