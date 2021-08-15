#include <Arduino.h>
#include <U8g2lib.h>
#include <Wire.h>

U8G2_SH1106_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, U8X8_PIN_NONE, SCL, SDA);

void setup()
{
  u8g2.begin();
  u8g2.setFont(u8g2_font_ncenB08_tr);
  u8g2.clearBuffer();

  u8g2.setCursor(10, 10);                
  u8g2.print("Creative point ");         
  u8g2.print(2021);                      
  u8g2.drawCircle(50, 35, 10);           
  u8g2.drawCircle(50, 35, 20);           
  u8g2.drawPixel(50, 35);                
  u8g2.drawLine(60, 60, 90, 30);         
  u8g2.drawLine(90, 30, 120, 60);        
  u8g2.drawLine(120, 60, 60, 60);        
  u8g2.drawFrame(0, 50, 10, 10);         
  u8g2.drawBox(20, 50, 10, 10);          
  u8g2.sendBuffer();
}

void loop(void)
{
}
