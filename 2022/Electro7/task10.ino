#include <NeoPixelBus.h>
NeoPixelBus<NeoGrbFeature, NeoEsp8266Uart1800KbpsMethod> strip(8);

void setup() {
  strip.Begin();
}

int interpoluj(int x1, int x2, int percent)
{
  return x1 + (x2-x1)*percent/100;
}

void loop() {
  RgbColor zelena(3, 50, 14);
  RgbColor modra(11, 7, 50);
  
  for (int i=0; i<100; i+=1)
  {
    int r = interpoluj(zelena.R, modra.R, i);
    int g = interpoluj(zelena.G, modra.G, i);
    int b = interpoluj(zelena.B, modra.B, i);
    strip.SetPixelColor(0, RgbColor(r, g, b));
    strip.Show();
    delay(10);
  }
  delay(1000);
  for (int i=100; i>0; i-=1)
  {
    int r = interpoluj(zelena.R, modra.R, i);
    int g = interpoluj(zelena.G, modra.G, i);
    int b = interpoluj(zelena.B, modra.B, i);
    strip.SetPixelColor(0, RgbColor(r, g, b));
    strip.Show();
    delay(10);
  }
  delay(1000);
}