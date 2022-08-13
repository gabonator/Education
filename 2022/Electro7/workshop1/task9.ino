    #include <NeoPixelBus.h>

    NeoPixelBus<NeoGrbFeature, NeoEsp8266Uart1800KbpsMethod> strip(8);

    void setup()
    {
      strip.Begin();
    }

    void loop()
    {
      for (int i=0; i<50; i++)
      {
        // tato slucka sa opakuje pre i=0, 1, 2, 3,...., 48, 49
        
        strip.SetPixelColor(0, RgbColor(0, i, 0));
        strip.SetPixelColor(3, RgbColor(i/2, i, i/2));
        strip.SetPixelColor(5, RgbColor(0, 0, 25+i/2));
        strip.SetPixelColor(7, RgbColor(50-i, i, 0));
        strip.Show();
        delay(100);
      }
    }
