/*
 * LOLIN (WEMOS) D1 R2 & mini
 * 
 *   RST 
 *   A0                         TX - 
 *   D0                         RX -
 *   D5 - button 2              D1 - display SCL
 *   D6 - button 2              D2 - display SDA
 *   D7 - button 1              D3 - 
 *   D8 - button 1              D4 -
 *   3.3 V - display VCC        G - display GND
 * 
 */

#include <Arduino.h>
#include <U8g2lib.h>

#include <Wire.h>

/*
 * class U8G2_SSD1305_128X64_ADAFRUIT_1_HW_I2C : public U8G2 {
class U8G2_SSD1305_128X64_RAYSTAR_1_HW_I2C : public U8G2 {
class U8G2_SSD1305_128X64_ADAFRUIT_2_HW_I2C : public U8G2 {
class U8G2_SSD1305_128X64_RAYSTAR_2_HW_I2C : public U8G2 {
class U8G2_SSD1305_128X64_ADAFRUIT_F_HW_I2C : public U8G2 {
class U8G2_SSD1305_128X64_RAYSTAR_F_HW_I2C : public U8G2 {
class U8G2_SSD1306_128X64_NONAME_1_HW_I2C : public U8G2 {
class U8G2_SSD1306_128X64_VCOMH0_1_HW_I2C : public U8G2 {
class U8G2_SSD1306_128X64_ALT0_1_HW_I2C : public U8G2 {
class U8G2_SSD1306_128X64_NONAME_2_HW_I2C : public U8G2 {
class U8G2_SSD1306_128X64_VCOMH0_2_HW_I2C : public U8G2 {
class U8G2_SSD1306_128X64_ALT0_2_HW_I2C : public U8G2 {
class U8G2_SSD1306_128X64_NONAME_F_HW_I2C : public U8G2 {
class U8G2_SSD1306_128X64_VCOMH0_F_HW_I2C : public U8G2 {
class U8G2_SSD1306_128X64_ALT0_F_HW_I2C : public U8G2 {
class U8G2_SH1106_128X64_NONAME_1_HW_I2C : public U8G2 {
class U8G2_SH1106_128X64_VCOMH0_1_HW_I2C : public U8G2 {
class U8G2_SH1106_128X64_WINSTAR_1_HW_I2C : public U8G2 {
class U8G2_SH1106_128X64_NONAME_2_HW_I2C : public U8G2 {
class U8G2_SH1106_128X64_VCOMH0_2_HW_I2C : public U8G2 {
class U8G2_SH1106_128X64_WINSTAR_2_HW_I2C : public U8G2 {
?  class U8G2_SH1106_128X64_NONAME_F_HW_I2C : public U8G2 {
class U8G2_SH1106_128X64_VCOMH0_F_HW_I2C : public U8G2 {
class U8G2_SH1106_128X64_WINSTAR_F_HW_I2C : public U8G2 {
class U8G2_SSD1309_128X64_NONAME2_1_HW_I2C : public U8G2 {
class U8G2_SSD1309_128X64_NONAME2_2_HW_I2C : public U8G2 {
class U8G2_SSD1309_128X64_NONAME2_F_HW_I2C : public U8G2 {
q  class U8G2_SSD1309_128X64_NONAME0_1_HW_I2C : public U8G2 {
   class U8G2_SSD1309_128X64_NONAME0_2_HW_I2C : public U8G2 {
>  class U8G2_SSD1309_128X64_NONAME0_F_HW_I2C : public U8G2 {
x  class U8G2_SSD1325_NHD_128X64_1_HW_I2C : public U8G2 {
   class U8G2_SSD1325_NHD_128X64_2_HW_I2C : public U8G2 {
x  class U8G2_SSD1325_NHD_128X64_F_HW_I2C : public U8G2 {
*/

//U8G2_SSD1309_128X64_NONAME0_F_HW_I2C u8g2(U8G2_R0,U8X8_PIN_NONE,SCL,SDA);
//U8G2_SSD1306_128X64_NONAME_1_HW_I2C u8g2(U8G2_R0,U8X8_PIN_NONE,SCL,SDA);

U8G2_SH1106_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0,U8X8_PIN_NONE,SCL,SDA);

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
//#define SCREEN_ADDRESS 0x3C

void setup() 
{
  Serial.begin(9600);

  u8g2.begin();
  u8g2.setFont(u8g2_font_ncenB08_tr);

  pinMode(D8, OUTPUT);
  digitalWrite(D8, LOW);
  pinMode(D7, INPUT_PULLUP);

  pinMode(D6, OUTPUT);
  digitalWrite(D6, LOW);
  pinMode(D5, INPUT_PULLUP);
}

int x = SCREEN_WIDTH/2;
int y = SCREEN_HEIGHT/2;
int dx = 1;
int dy = 1;
int py = 10;
int cy = 10;
int ps = 0;
int cs = 0;
int waitReady = true;
int speed = 1;

void loop(void) 
{
  if (digitalRead(D7) == 0 && py > 9)
    py--;
  if (digitalRead(D5) == 0 && py < SCREEN_HEIGHT - 9)
    py++;

  if (cy > y && cy > 9)
    cy--;

  if (cy < y && cy < SCREEN_HEIGHT-9)
    cy++;

  u8g2.clearBuffer();
  u8g2.drawFrame(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);

  u8g2.setCursor(60, 10);
  u8g2.print(ps);
  u8g2.print(":");
  u8g2.print(cs);

  u8g2.setCursor(x-2, y+3);
  u8g2.print("o");
  //u8g2.drawPixel(x, y);
  
  u8g2.drawBox(SCREEN_WIDTH-5, cy-7, 3, 14);
  u8g2.drawBox(2, py-7, 3, 14);
  u8g2.sendBuffer();

  if (waitReady)
  {
    delay(1000);
    waitReady = false;
  } else {
    //delay(10);
  }

  for (int cycles = 0; cycles < speed; cycles++)
  {
    x += dx;
    y += dy;
    if (x >= SCREEN_WIDTH-5-5+2)
    {
      if (abs(y-cy) > 7)
      {
        x = SCREEN_WIDTH/2;
        y = SCREEN_HEIGHT/2;
        dx = -1;
        ps++;
        waitReady = true;
        delay(1000);
      } else {
        dx = -1;
      }
    }
    if (x < 6+2)
    {
      if (abs(y-py) > 7)
      {
        x = SCREEN_WIDTH/2;
        y = SCREEN_HEIGHT/2;
        dx = 1;
        cs++;
        waitReady = true;
        delay(1000);      
      } else {
        dx = 1;
      }
    }
    if (y >= SCREEN_HEIGHT-4 || y < 4)
      dy = -dy;
  }
}