#include <Arduino.h>
#include <U8g2lib.h>
#include <Wire.h>

U8G2_SH1106_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, U8X8_PIN_NONE, SCL, SDA);

void setup()
{
  Serial.begin(9600);
  u8g2.begin();            
  u8g2.setFont(u8g2_font_ncenB08_tr);
}

int phase = 0;

void loop()
{
  u8g2.clearBuffer();

  int centerx = 64;
  int centery = 32;
  int radius = 12;
  int radius1 = 15;
  int radius2 = 30;
  int rays = 10;
  
  u8g2.drawDisc(centerx, centery, radius);   
  u8g2.setDrawColor(0);
  u8g2.drawCircle(centerx, centery, radius * 0.8, U8G2_DRAW_LOWER_LEFT | 
  U8G2_DRAW_LOWER_RIGHT);

  u8g2.drawDisc(centerx-radius*0.3, centery-radius*0.5, 2);
  u8g2.drawDisc(centerx+radius*0.3, centery-radius*0.5, 2);
  u8g2.setDrawColor(1);

  for (int i=0; i<rays; i++)
  {
    int angle = 360*i/rays + phase;
    int sx = centerx + cos(angle*PI/180) * radius1;
    int sy = centery + sin(angle*PI/180) * radius1;
    int ex = centerx + cos(angle*PI/180) * radius2;
    int ey = centery + sin(angle*PI/180) * radius2;

    u8g2.drawLine(sx, sy, ex, ey);              
  }
  
  u8g2.sendBuffer();
  phase = phase + 6; 
}