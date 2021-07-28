#define SYNC sync();

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
  u8g2.clearBuffer();               SYNC
  u8g2.drawFrame(10, 30, 31, 30);   SYNC
  u8g2.drawLine(10, 30, 25, 15);    SYNC
  u8g2.drawLine(25, 15, 40, 30);    SYNC
  u8g2.drawFrame(28, 35, 8, 8);     SYNC
  u8g2.drawFrame(34, 14, 3, 12);    SYNC
  
  u8g2.sendBuffer();
}

void sync()
{
  static bool b = true;
  if (b)
  {
    Serial.begin(115200);
    delay(200);
    delay(200);
    delay(200);    
    Serial.print("\n" __FILE__ "\n");
    delay(100);
    Serial.print("\nStart:\n");    
    b = false;
  }
  u8g2.sendBuffer();
  delay(200);
  
  uint32_t* buf = (uint32_t*)u8g2.getBufferPtr();
  int size = (u8g2.getDisplayWidth()*u8g2.getDisplayHeight())/8/4;

  Serial.print("[");
  for (int i=0; i<size; i+=2)
  {
    char msg[30];
    sprintf(msg, "0x%08x, 0x%08x, ", buf[i], buf[i+1]);
    Serial.print(msg);
    if (((i/2)%8) == 7)
      Serial.print("\n");
  }
  Serial.print("],\n");
}
