#ifdef __AVR__
enum {D8=8, D7=7, D6=6, D5=5};
#endif

#include <Arduino.h>
#include <U8g2lib.h>
#include <Wire.h>

U8G2_SH1106_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, U8X8_PIN_NONE, SCL, SDA);

void setup()
{
  u8g2.begin();

  pinMode(D8, OUTPUT);
  digitalWrite(D8, LOW);
  pinMode(D7, INPUT_PULLUP);

  pinMode(D6, OUTPUT);
  digitalWrite(D6, LOW);
  pinMode(D5, INPUT_PULLUP);

  u8g2.setFont(u8g2_font_ncenB08_tr);  
}

int py = 32;       // player
int oy = 32;       // opponent
int bx = 128/2-5;  // ball-x
int by = 64/2-5;   // ball-y
int dx = 1;        // ball-dir-x
int dy = 1;        // ball-dir-y

void loop()
{
  if (digitalRead(D7) == 0 && py > 9)
    py--;
  if (digitalRead(D5) == 0 && py < 64 - 9)
    py++;

  if (oy > by && oy > 9)
    oy--;
  if (oy < by && oy < 64-9)
    oy++;

  u8g2.clearBuffer();
  u8g2.drawFrame(0, 0, 128, 64);
  u8g2.drawBox(2, py-7, 3, 14);
  u8g2.drawBox(128-5, oy-7, 3, 14);

  //u8g2.drawFrame(bx, by, 6, 5);
  u8g2.setCursor(bx, by+5);
  u8g2.print("o");

  bx = bx + dx;
  by = by + dy;

  if (bx+6 >= 127-5 || bx <= 5)
    dx = -dx;
  if (by+5 >= 63 || by <= 1)
    dy = -dy;

  u8g2.sendBuffer();
  
  if (bx <= 5)
  {
    int lopta_vrch = by;
    int lopta_spodok = by + 5;
    int hrac_vrch = py-7;
    int hrac_spodok = py-7+14;

    if (hrac_vrch > lopta_spodok || hrac_spodok < lopta_vrch)
    {
      // netrafil
      delay(1000);
      bx = 128/2-5;
      by = 64/2-5;
    }
  }
}
