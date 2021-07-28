#include <Arduino.h>
#include <U8g2lib.h>
#include <Wire.h>

U8G2_SH1106_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, U8X8_PIN_NONE, SCL, SDA);

// polohy troch bodov vo vrcholoch trojuholnika
int px0 = 0; 
int py0 = 60;
int px1 = 64;
int py1 = 0;
int px2 = 127;
int py2 = 63;

// nasa pociatocna suradnica
int x = 128/2;
int y = 64/2;

void setup()
{
  u8g2.begin(); 
}

void loop()
{
  int i = rand()%3;
  if (i==0)
  {
    x = (x + px0) / 2;
    y = (y + py0) / 2;
  }
  if (i==1)
  {
    x = (x + px1) / 2;
    y = (y + py1) / 2;
  }
  if (i==2)
  {
    x = (x + px2) / 2;
    y = (y + py2) / 2;
  }
  u8g2.drawPixel(x, y);
  u8g2.sendBuffer();
}
