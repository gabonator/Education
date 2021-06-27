#include <Arduino.h>
#include <U8g2lib.h>

#include <Wire.h>
U8G2_SH1106_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, U8X8_PIN_NONE, SCL, SDA);


void setup()
{
  Serial.begin(9600);
  u8g2.begin();
  u8g2.setFont(u8g2_font_ncenB08_tr);
  u8g2.clearBuffer();

  u8g2.setCursor(10, 10);
  u8g2.print("Creative point ");
  u8g2.print(2021);
  u8g2.drawCircle(50, 35, 10);
  u8g2.drawCircle(50, 35, 20);
  u8g2.drawLine(60, 60, 90, 30);
  u8g2.drawLine(90, 30, 120, 60);
  u8g2.drawLine(120, 60, 60, 60);
  u8g2.drawLine(120, 60, 60, 60);
  u8g2.drawFrame(0, 50, 10, 10);*/
  u8g2.drawBox(20, 50, 10, 10);
  u8g2.sendBuffer();

  uint32_t* buf = (uint32_t*)u8g2.getBufferPtr();
  int size = (u8g2.getDisplayWidth()*u8g2.getDisplayHeight())/8/4;

  Serial.begin(9600);
  delay(2000);
  Serial.print("\n\nDumping buffer of size");
  Serial.print(size);
  Serial.print(":\n");
  for (int i=0; i<size; i+=2)
  {
    char msg[30];
    sprintf(msg, "0x%08x, 0x%08x, ", buf[i], buf[i+1]);
    Serial.print(msg);
    //delay(10);
    if (((i/2)%8) == 7)
      Serial.print("\n");
  }
  Serial.print("Done!\n");
}


void loop(void)
{
   delay(5000);
}