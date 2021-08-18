#include <Arduino.h>
#include <U8g2lib.h>
#include <Wire.h>

U8G2_SH1106_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, U8X8_PIN_NONE, SCL, SDA);

void smajlik(int x, int y)
{
  u8g2.drawCircle(x, y, 12);   
  u8g2.drawCircle(x, y, 8, U8G2_DRAW_LOWER_LEFT | U8G2_DRAW_LOWER_RIGHT);
  u8g2.drawDisc(x-3, y-6, 1);
  u8g2.drawDisc(x+3, y-6, 1);
}

void setup()
{
  u8g2.begin();            
}

void loop()
{
  u8g2.clearBuffer();
  for (int y=0; y<3; y++)
    for (int x=0; x<4; x++)
    {
      if ((y%2) == 0)
        smajlik(8+x*32, 12+y*19);
      else
        smajlik(23+x*32, 12+y*19);
    }    
  u8g2.sendBuffer();
}