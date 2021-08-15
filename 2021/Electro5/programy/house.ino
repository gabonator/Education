#include <Arduino.h>
#include <U8g2lib.h>
#include <Wire.h>

U8G2_SH1106_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, U8X8_PIN_NONE, SCL, SDA);

void setup()
{
  u8g2.begin();            
}

void loop()
{
  u8g2.clearBuffer();
  u8g2.drawFrame(10, 30, 31, 30);
  u8g2.drawLine(10, 30, 25, 15);
  u8g2.drawLine(25, 15, 40, 30);
  u8g2.drawFrame(28, 35, 8, 8);
  u8g2.drawFrame(34, 14, 3, 12);  
  u8g2.sendBuffer();
}
