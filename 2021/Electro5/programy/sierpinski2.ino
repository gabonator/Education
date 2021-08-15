#include <Arduino.h>
#include <U8g2lib.h>
#include <Wire.h>

U8G2_SH1106_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, U8X8_PIN_NONE, SCL, SDA);

int posx[] = {0, 64, 127};
int posy[] = {60, 0, 63};
int x = posx[0];
int y = posy[0];
void setup()
{
  Serial.begin(9600);
  u8g2.begin(); 
  //u8g2.setDrawColor(2);
}

void loop()
{
  int i = rand() % 3;
  int nx = posx[i];
  int ny = posy[i];
  x = (x + nx)/2;
  y = (y + ny)/2;
  u8g2.drawPixel(x, y);
  u8g2.sendBuffer();
}
