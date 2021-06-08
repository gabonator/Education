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

#include <SPI.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 32

#define SCREEN_ADDRESS 0x3C
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

void setup() 
{
  Serial.begin(9600);

  if(!display.begin(SSD1306_SWITCHCAPVCC, SCREEN_ADDRESS)) {
    Serial.println(F("SSD1306 allocation failed"));
    for(;;); // Don't proceed, loop forever
  }

  display.display();
  delay(500); 

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

  display.clearDisplay();
  display.drawRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, SSD1306_WHITE);

  display.setTextSize(1);      // Normal 1:1 pixel scale
  display.setTextColor(SSD1306_WHITE); // Draw white text
  display.setCursor(50, 2);
  display.print(ps);
  display.print(":");
  display.print(cs);

  display.setCursor(x-2, y-4);     // Start at top-left corner
  display.print("o");
  //display.drawPixel(x, y, SSD1306_WHITE);
  display.fillRect(SCREEN_WIDTH-5, cy-7, 3, 14, SSD1306_WHITE);
  display.fillRect(2, py-7, 3, 14, SSD1306_WHITE);
  display.display();

  if (waitReady)
  {
    delay(1000);
    waitReady = false;
  } else {
    delay(10);
  }
    
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
