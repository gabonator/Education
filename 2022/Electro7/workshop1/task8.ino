    #include <NeoPixelBus.h>

    NeoPixelBus<NeoGrbFeature, NeoEsp8266Uart1800KbpsMethod> strip(8);

    void setup()
    {
      strip.Begin();
      strip.Show();
    }

    void loop()
    {
      // red, green, blue (0..255)
      strip.SetPixelColor(0, RgbColor(10, 0, 0));
      strip.SetPixelColor(1, RgbColor(0, 0, 0));
      strip.SetPixelColor(2, RgbColor(0, 0, 0));
      strip.Show();
      delay(2000);

      strip.SetPixelColor(0, RgbColor(0, 0, 0));
      strip.SetPixelColor(1, RgbColor(10, 3, 0));
      strip.SetPixelColor(2, RgbColor(0, 0, 0));
      strip.Show();
      delay(1000);

      strip.SetPixelColor(0, RgbColor(0, 0, 0));
      strip.SetPixelColor(1, RgbColor(0, 0, 0));
      strip.SetPixelColor(2, RgbColor(0, 10, 0));
      strip.Show();
      delay(2000);

      strip.SetPixelColor(0, RgbColor(0, 0, 0));
      strip.SetPixelColor(1, RgbColor(10, 3, 0));
      strip.SetPixelColor(2, RgbColor(0, 0, 0));
      strip.Show();
      delay(1000);
    }
