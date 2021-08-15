#include <Arduino.h>
#include <U8g2lib.h>
#include <Wire.h>

U8G2_SH1106_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, U8X8_PIN_NONE, SCL, SDA);

void setup()
{
  u8g2.begin();
  u8g2.setFontMode(true);
  u8g2.setFont(u8g2_font_helvB14_tf);
  u8g2.clearBuffer();

  u8g2.drawBox(0, 0, 64, 64);

  u8g2.setCursor(20, 20);
  u8g2.setDrawColor(0);
  u8g2.print("0 Color 0");

  u8g2.setCursor(20, 40);
  u8g2.setDrawColor(1);
  u8g2.print("1 Color 1");
 
  u8g2.setCursor(20, 60);
  u8g2.setDrawColor(2);
  u8g2.print("2 Color 2");

  u8g2.sendBuffer();
}

void loop()
{
}