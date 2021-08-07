#include <Arduino.h>
#include <U8g2lib.h>
#include <Wire.h>

U8G2_SH1106_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, U8X8_PIN_NONE, SCL, SDA);

void setup()
{
  u8g2.begin();            
  u8g2.setFont(u8g2_font_ncenB12_tr);
}

int px = 30;
void loop()
{
  u8g2.clearBuffer();

  u8g2.setCursor(px, 40);                
  u8g2.print("Gabriel"); 
  u8g2.sendBuffer();
  
  px = px + 1;
  if (px >= 128)
  {
    px = -70;
  }
}
