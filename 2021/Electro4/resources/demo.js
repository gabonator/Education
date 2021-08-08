_callback({
code:`#include <Arduino.h>
#include <U8g2lib.h>
#include <Wire.h>

U8G2_SH1106_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, U8X8_PIN_NONE, SCL, SDA);

void setup()
{
  u8g2.begin();
  u8g2.setFont(u8g2_font_ncenB08_tr);
  u8g2.clearBuffer();

  u8g2.setCursor(10, 10);                SYNC
  u8g2.print("Creative point ");         SYNC
  u8g2.print(2021);                      SYNC
  u8g2.drawCircle(50, 35, 10);           SYNC
  u8g2.drawCircle(50, 35, 20);           SYNC
  u8g2.drawPixel(50, 35);                SYNC
  u8g2.drawLine(60, 60, 90, 30);         SYNC
  u8g2.drawLine(90, 30, 120, 60);        SYNC
  u8g2.drawLine(120, 60, 60, 60);        SYNC
  u8g2.drawFrame(0, 50, 10, 10);         SYNC
  u8g2.drawBox(20, 50, 10, 10);          SYNC
  u8g2.sendBuffer();
}

void loop(void)
{
}
`,
screens:[
[0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
],
[0x00000000, 0x00000000, 0xf8f00000, 0x08040404, 0xe0e0009c, 0xc0006040, 0xc0e0a0e0, 0xe0a02000, 0xf8f000c0, 0xec200020, 0x200000ec, 0xe000e0e0, 0xe0c00020, 0x00c0e0a0, 0xe0000000, 0xe02040e0, 
0xe0c000c0, 0xc0e02020, 0xecec2000, 0xe0e00000, 0xc0e02040, 0x20f8f000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x01000000, 0x02020202, 0x03030001, 0x01000000, 0x02020203, 0x03020300, 0x03010003, 0x03020002, 0x00000203, 0x00030300, 0x03010000, 0x00020202, 0x0f000000, 0x03020a0f, 
0x03010001, 0x01030202, 0x03030200, 0x03030002, 0x03030000, 0x02030100, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
],
[0x00000000, 0x00000000, 0xf8f00000, 0x08040404, 0xe0e0009c, 0xc0006040, 0xc0e0a0e0, 0xe0a02000, 0xf8f000c0, 0xec200020, 0x200000ec, 0xe000e0e0, 0xe0c00020, 0x00c0e0a0, 0xe0000000, 0xe02040e0, 
0xe0c000c0, 0xc0e02020, 0xecec2000, 0xe0e00000, 0xc0e02040, 0x20f8f000, 0x00000000, 0x7c449c18, 0xfcf80038, 0x00f8fc04, 0x7c449c18, 0x08000038, 0x0000fcfc, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x01000000, 0x02020202, 0x03030001, 0x01000000, 0x02020203, 0x03020300, 0x03010003, 0x03020002, 0x00000203, 0x00030300, 0x03010000, 0x00020202, 0x0f000000, 0x03020a0f, 
0x03010001, 0x01030202, 0x03030200, 0x03030002, 0x03030000, 0x02030100, 0x00000000, 0x03030303, 0x03010003, 0x00010302, 0x03030303, 0x02000003, 0x00020303, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
],
[0x00000000, 0x00000000, 0xf8f00000, 0x08040404, 0xe0e0009c, 0xc0006040, 0xc0e0a0e0, 0xe0a02000, 0xf8f000c0, 0xec200020, 0x200000ec, 0xe000e0e0, 0xe0c00020, 0x00c0e0a0, 0xe0000000, 0xe02040e0, 
0xe0c000c0, 0xc0e02020, 0xecec2000, 0xe0e00000, 0xc0e02040, 0x20f8f000, 0x00000000, 0x7c449c18, 0xfcf80038, 0x00f8fc04, 0x7c449c18, 0x08000038, 0x0000fcfc, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x01000000, 0x02020202, 0x03030001, 0x01000000, 0x02020203, 0x03020300, 0x03010003, 0x03020002, 0x00000203, 0x00030300, 0x03010000, 0x00020202, 0x0f000000, 0x03020a0f, 
0x03010001, 0x01030202, 0x03030200, 0x03030002, 0x03030000, 0x02030100, 0x00000000, 0x03030303, 0x03010003, 0x00010302, 0x03030303, 0x02000003, 0x00020303, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x1020c000, 0x02040408, 0x02020202, 0x04040202, 0xc0201008, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x0000807f, 0x00000000, 0x00000000, 0x00000000, 0x80000000, 0x0000007f, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x04020100, 0x20101008, 0x20202020, 0x10102020, 0x01020408, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
],
[0x00000000, 0x00000000, 0xf8f00000, 0x08040404, 0xe0e0009c, 0xc0006040, 0xc0e0a0e0, 0xe0a02000, 0xf8f000c0, 0xec200020, 0x200000ec, 0xe000e0e0, 0xe0c00020, 0x00c0e0a0, 0xe0000000, 0xe02040e0, 
0xe0c000c0, 0xc0e02020, 0xecec2000, 0xe0e00000, 0xc0e02040, 0x20f8f000, 0x00000000, 0x7c449c18, 0xfcf80038, 0x00f8fc04, 0x7c449c18, 0x08000038, 0x0000fcfc, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x01000000, 0x02020202, 0x03030001, 0x01000000, 0x02020203, 0x03020300, 0x03010003, 0x03020002, 0x00000203, 0x80830300, 0x83818080, 0x00828282, 0x0f000000, 0x03020a0f, 
0x03010001, 0x01030202, 0x03030200, 0x03030002, 0x03030000, 0x02030100, 0x00000000, 0x03030303, 0x03010003, 0x00010302, 0x03030303, 0x02000003, 0x00020303, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x40800000, 0x04081020, 0x01020204, 0x00000101, 0x00000000, 0x01000000, 0x02020101, 0x10080404, 
0x00804020, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x70800000, 0x0000030c, 0x00000000, 0x1020c000, 0x02040408, 0x02020202, 0x04040202, 0xc0201008, 0x00000000, 
0x03000000, 0x0080700c, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00ff0000, 0x00000000, 0x00000000, 0x0000807f, 0x00000000, 0x00000000, 0x00000000, 0x80000000, 0x0000007f, 
0x00000000, 0x00ff0000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x07000000, 0x00806018, 0x00000000, 0x04020100, 0x20101008, 0x20202020, 0x10102020, 0x01020408, 0x00000000, 
0x60800000, 0x00000718, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x01000000, 0x10080402, 0x40202010, 0x80804040, 0x80808080, 0x40808080, 0x20204040, 0x04081010, 
0x00000102, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
],
[0x00000000, 0x00000000, 0xf8f00000, 0x08040404, 0xe0e0009c, 0xc0006040, 0xc0e0a0e0, 0xe0a02000, 0xf8f000c0, 0xec200020, 0x200000ec, 0xe000e0e0, 0xe0c00020, 0x00c0e0a0, 0xe0000000, 0xe02040e0, 
0xe0c000c0, 0xc0e02020, 0xecec2000, 0xe0e00000, 0xc0e02040, 0x20f8f000, 0x00000000, 0x7c449c18, 0xfcf80038, 0x00f8fc04, 0x7c449c18, 0x08000038, 0x0000fcfc, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x01000000, 0x02020202, 0x03030001, 0x01000000, 0x02020203, 0x03020300, 0x03010003, 0x03020002, 0x00000203, 0x80830300, 0x83818080, 0x00828282, 0x0f000000, 0x03020a0f, 
0x03010001, 0x01030202, 0x03030200, 0x03030002, 0x03030000, 0x02030100, 0x00000000, 0x03030303, 0x03010003, 0x00010302, 0x03030303, 0x02000003, 0x00020303, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x40800000, 0x04081020, 0x01020204, 0x00000101, 0x00000000, 0x01000000, 0x02020101, 0x10080404, 
0x00804020, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x70800000, 0x0000030c, 0x00000000, 0x1020c000, 0x02040408, 0x02020202, 0x04040202, 0xc0201008, 0x00000000, 
0x03000000, 0x0080700c, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00ff0000, 0x00000000, 0x00000000, 0x0000807f, 0x00000000, 0x00080000, 0x00000000, 0x80000000, 0x0000007f, 
0x00000000, 0x00ff0000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x07000000, 0x00806018, 0x00000000, 0x04020100, 0x20101008, 0x20202020, 0x10102020, 0x01020408, 0x00000000, 
0x60800000, 0x00000718, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x01000000, 0x10080402, 0x40202010, 0x80804040, 0x80808080, 0x40808080, 0x20204040, 0x04081010, 
0x00000102, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
],
[0x00000000, 0x00000000, 0xf8f00000, 0x08040404, 0xe0e0009c, 0xc0006040, 0xc0e0a0e0, 0xe0a02000, 0xf8f000c0, 0xec200020, 0x200000ec, 0xe000e0e0, 0xe0c00020, 0x00c0e0a0, 0xe0000000, 0xe02040e0, 
0xe0c000c0, 0xc0e02020, 0xecec2000, 0xe0e00000, 0xc0e02040, 0x20f8f000, 0x00000000, 0x7c449c18, 0xfcf80038, 0x00f8fc04, 0x7c449c18, 0x08000038, 0x0000fcfc, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x01000000, 0x02020202, 0x03030001, 0x01000000, 0x02020203, 0x03020300, 0x03010003, 0x03020002, 0x00000203, 0x80830300, 0x83818080, 0x00828282, 0x0f000000, 0x03020a0f, 
0x03010001, 0x01030202, 0x03030200, 0x03030002, 0x03030000, 0x02030100, 0x00000000, 0x03030303, 0x03010003, 0x00010302, 0x03030303, 0x02000003, 0x00020303, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x40800000, 0x04081020, 0x01020204, 0x00000101, 0x00000000, 0x01000000, 0x02020101, 0x10080404, 
0x00804020, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x70800000, 0x0000030c, 0x00000000, 0x1020c000, 0x02040408, 0x02020202, 0x04040202, 0xc0201008, 0x00000000, 
0x03000000, 0x0080700c, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00408000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00ff0000, 0x00000000, 0x00000000, 0x0000807f, 0x00000000, 0x00080000, 0x00000000, 0x80000000, 0x0000007f, 
0x00000000, 0x00ff0000, 0x00000000, 0x00000000, 0x20408000, 0x02040810, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x07000000, 0x00806018, 0x00000000, 0x04020100, 0x20101008, 0x20202020, 0x10102020, 0x01020408, 0x00000000, 
0x60800000, 0x00000718, 0x20408000, 0x02040810, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x01000000, 0x10080402, 0x40202010, 0x80804040, 0x80808080, 0x40808080, 0x20204040, 0x04081010, 
0x20408102, 0x02040810, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x02040810, 
0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
],
[0x00000000, 0x00000000, 0xf8f00000, 0x08040404, 0xe0e0009c, 0xc0006040, 0xc0e0a0e0, 0xe0a02000, 0xf8f000c0, 0xec200020, 0x200000ec, 0xe000e0e0, 0xe0c00020, 0x00c0e0a0, 0xe0000000, 0xe02040e0, 
0xe0c000c0, 0xc0e02020, 0xecec2000, 0xe0e00000, 0xc0e02040, 0x20f8f000, 0x00000000, 0x7c449c18, 0xfcf80038, 0x00f8fc04, 0x7c449c18, 0x08000038, 0x0000fcfc, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x01000000, 0x02020202, 0x03030001, 0x01000000, 0x02020203, 0x03020300, 0x03010003, 0x03020002, 0x00000203, 0x80830300, 0x83818080, 0x00828282, 0x0f000000, 0x03020a0f, 
0x03010001, 0x01030202, 0x03030200, 0x03030002, 0x03030000, 0x02030100, 0x00000000, 0x03030303, 0x03010003, 0x00010302, 0x03030303, 0x02000003, 0x00020303, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x40800000, 0x04081020, 0x01020204, 0x00000101, 0x00000000, 0x01000000, 0x02020101, 0x10080404, 
0x00804020, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x70800000, 0x0000030c, 0x00000000, 0x1020c000, 0x02040408, 0x02020202, 0x04040202, 0xc0201008, 0x00000000, 
0x03000000, 0x0080700c, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x80408000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00ff0000, 0x00000000, 0x00000000, 0x0000807f, 0x00000000, 0x00080000, 0x00000000, 0x80000000, 0x0000007f, 
0x00000000, 0x00ff0000, 0x00000000, 0x00000000, 0x20408000, 0x02040810, 0x00000001, 0x08040201, 0x80402010, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x07000000, 0x00806018, 0x00000000, 0x04020100, 0x20101008, 0x20202020, 0x10102020, 0x01020408, 0x00000000, 
0x60800000, 0x00000718, 0x20408000, 0x02040810, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x08040201, 0x80402010, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x01000000, 0x10080402, 0x40202010, 0x80804040, 0x80808080, 0x40808080, 0x20204040, 0x04081010, 
0x20408102, 0x02040810, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x08040201, 0x80402010, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x02040810, 
0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x08040201, 0x00000010, 0x00000000, 
],
[0x00000000, 0x00000000, 0xf8f00000, 0x08040404, 0xe0e0009c, 0xc0006040, 0xc0e0a0e0, 0xe0a02000, 0xf8f000c0, 0xec200020, 0x200000ec, 0xe000e0e0, 0xe0c00020, 0x00c0e0a0, 0xe0000000, 0xe02040e0, 
0xe0c000c0, 0xc0e02020, 0xecec2000, 0xe0e00000, 0xc0e02040, 0x20f8f000, 0x00000000, 0x7c449c18, 0xfcf80038, 0x00f8fc04, 0x7c449c18, 0x08000038, 0x0000fcfc, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x01000000, 0x02020202, 0x03030001, 0x01000000, 0x02020203, 0x03020300, 0x03010003, 0x03020002, 0x00000203, 0x80830300, 0x83818080, 0x00828282, 0x0f000000, 0x03020a0f, 
0x03010001, 0x01030202, 0x03030200, 0x03030002, 0x03030000, 0x02030100, 0x00000000, 0x03030303, 0x03010003, 0x00010302, 0x03030303, 0x02000003, 0x00020303, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x40800000, 0x04081020, 0x01020204, 0x00000101, 0x00000000, 0x01000000, 0x02020101, 0x10080404, 
0x00804020, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x70800000, 0x0000030c, 0x00000000, 0x1020c000, 0x02040408, 0x02020202, 0x04040202, 0xc0201008, 0x00000000, 
0x03000000, 0x0080700c, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x80408000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00ff0000, 0x00000000, 0x00000000, 0x0000807f, 0x00000000, 0x00080000, 0x00000000, 0x80000000, 0x0000007f, 
0x00000000, 0x00ff0000, 0x00000000, 0x00000000, 0x20408000, 0x02040810, 0x00000001, 0x08040201, 0x80402010, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x07000000, 0x00806018, 0x00000000, 0x04020100, 0x20101008, 0x20202020, 0x10102020, 0x01020408, 0x00000000, 
0x60800000, 0x00000718, 0x20408000, 0x02040810, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x08040201, 0x80402010, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x01000000, 0x10080402, 0x40202010, 0x80804040, 0x80808080, 0x40808080, 0x20204040, 0x04081010, 
0x20408102, 0x02040810, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x08040201, 0x80402010, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x12141810, 
0x10101011, 0x10101010, 0x10101010, 0x10101010, 0x10101010, 0x10101010, 0x10101010, 0x10101010, 0x10101010, 0x10101010, 0x10101010, 0x10101010, 0x10101010, 0x18141211, 0x00000010, 0x00000000, 
],
[0x00000000, 0x00000000, 0xf8f00000, 0x08040404, 0xe0e0009c, 0xc0006040, 0xc0e0a0e0, 0xe0a02000, 0xf8f000c0, 0xec200020, 0x200000ec, 0xe000e0e0, 0xe0c00020, 0x00c0e0a0, 0xe0000000, 0xe02040e0, 
0xe0c000c0, 0xc0e02020, 0xecec2000, 0xe0e00000, 0xc0e02040, 0x20f8f000, 0x00000000, 0x7c449c18, 0xfcf80038, 0x00f8fc04, 0x7c449c18, 0x08000038, 0x0000fcfc, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x01000000, 0x02020202, 0x03030001, 0x01000000, 0x02020203, 0x03020300, 0x03010003, 0x03020002, 0x00000203, 0x80830300, 0x83818080, 0x00828282, 0x0f000000, 0x03020a0f, 
0x03010001, 0x01030202, 0x03030200, 0x03030002, 0x03030000, 0x02030100, 0x00000000, 0x03030303, 0x03010003, 0x00010302, 0x03030303, 0x02000003, 0x00020303, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x40800000, 0x04081020, 0x01020204, 0x00000101, 0x00000000, 0x01000000, 0x02020101, 0x10080404, 
0x00804020, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x70800000, 0x0000030c, 0x00000000, 0x1020c000, 0x02040408, 0x02020202, 0x04040202, 0xc0201008, 0x00000000, 
0x03000000, 0x0080700c, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x80408000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00ff0000, 0x00000000, 0x00000000, 0x0000807f, 0x00000000, 0x00080000, 0x00000000, 0x80000000, 0x0000007f, 
0x00000000, 0x00ff0000, 0x00000000, 0x00000000, 0x20408000, 0x02040810, 0x00000001, 0x08040201, 0x80402010, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x07000000, 0x00806018, 0x00000000, 0x04020100, 0x20101008, 0x20202020, 0x10102020, 0x01020408, 0x00000000, 
0x60800000, 0x00000718, 0x20408000, 0x02040810, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x08040201, 0x80402010, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x040404fc, 0x04040404, 0x0000fc04, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x01000000, 0x10080402, 0x40202010, 0x80804040, 0x80808080, 0x40808080, 0x20204040, 0x04081010, 
0x20408102, 0x02040810, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x08040201, 0x80402010, 0x00000000, 0x00000000, 0x00000000, 
0x0808080f, 0x08080808, 0x00000f08, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x12141810, 
0x10101011, 0x10101010, 0x10101010, 0x10101010, 0x10101010, 0x10101010, 0x10101010, 0x10101010, 0x10101010, 0x10101010, 0x10101010, 0x10101010, 0x10101010, 0x18141211, 0x00000010, 0x00000000, 
],
[0x00000000, 0x00000000, 0xf8f00000, 0x08040404, 0xe0e0009c, 0xc0006040, 0xc0e0a0e0, 0xe0a02000, 0xf8f000c0, 0xec200020, 0x200000ec, 0xe000e0e0, 0xe0c00020, 0x00c0e0a0, 0xe0000000, 0xe02040e0, 
0xe0c000c0, 0xc0e02020, 0xecec2000, 0xe0e00000, 0xc0e02040, 0x20f8f000, 0x00000000, 0x7c449c18, 0xfcf80038, 0x00f8fc04, 0x7c449c18, 0x08000038, 0x0000fcfc, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x01000000, 0x02020202, 0x03030001, 0x01000000, 0x02020203, 0x03020300, 0x03010003, 0x03020002, 0x00000203, 0x80830300, 0x83818080, 0x00828282, 0x0f000000, 0x03020a0f, 
0x03010001, 0x01030202, 0x03030200, 0x03030002, 0x03030000, 0x02030100, 0x00000000, 0x03030303, 0x03010003, 0x00010302, 0x03030303, 0x02000003, 0x00020303, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x40800000, 0x04081020, 0x01020204, 0x00000101, 0x00000000, 0x01000000, 0x02020101, 0x10080404, 
0x00804020, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x70800000, 0x0000030c, 0x00000000, 0x1020c000, 0x02040408, 0x02020202, 0x04040202, 0xc0201008, 0x00000000, 
0x03000000, 0x0080700c, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x80408000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00ff0000, 0x00000000, 0x00000000, 0x0000807f, 0x00000000, 0x00080000, 0x00000000, 0x80000000, 0x0000007f, 
0x00000000, 0x00ff0000, 0x00000000, 0x00000000, 0x20408000, 0x02040810, 0x00000001, 0x08040201, 0x80402010, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x07000000, 0x00806018, 0x00000000, 0x04020100, 0x20101008, 0x20202020, 0x10102020, 0x01020408, 0x00000000, 
0x60800000, 0x00000718, 0x20408000, 0x02040810, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x08040201, 0x80402010, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
0x040404fc, 0x04040404, 0x0000fc04, 0x00000000, 0x00000000, 0xfcfcfcfc, 0xfcfcfcfc, 0x0000fcfc, 0x01000000, 0x10080402, 0x40202010, 0x80804040, 0x80808080, 0x40808080, 0x20204040, 0x04081010, 
0x20408102, 0x02040810, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x08040201, 0x80402010, 0x00000000, 0x00000000, 0x00000000, 
0x0808080f, 0x08080808, 0x00000f08, 0x00000000, 0x00000000, 0x0f0f0f0f, 0x0f0f0f0f, 0x00000f0f, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x12141810, 
0x10101011, 0x10101010, 0x10101010, 0x10101010, 0x10101010, 0x10101010, 0x10101010, 0x10101010, 0x10101010, 0x10101010, 0x10101010, 0x10101010, 0x10101010, 0x18141211, 0x00000010, 0x00000000, 
],
]});