#include "DHTesp.h" // Click here to get the library: http://librarymanager/All#DHTesp
#include <NeoPixelBus.h>

DHTesp dht;
NeoPixelBus<NeoGrbFeature, NeoEsp8266Uart1800KbpsMethod> strip(8);

void setup()
{
  Serial.begin(115200);
  Serial.println();
  Serial.println("Status\tHumidity (%)\tTemperature (C)\t(F)\tHeatIndex (C)\t(F)");
  String thisBoard= ARDUINO_BOARD;
  Serial.println(thisBoard);
    strip.Begin();
    strip.Show();

    pinMode(D1, OUTPUT);
    digitalWrite(D1, HIGH);
    pinMode(D3, OUTPUT);
    digitalWrite(D3, LOW);

  // Autodetect is not working reliable, don't use the following line
  // dht.setup(17);
  // use this instead: 
  dht.setup(D2, DHTesp::DHT22); // Connect DHT sensor to GPIO 17
}

int i=0;
void loop()
{
  //delay(dht.getMinimumSamplingPeriod());

  float humidity = dht.getHumidity();
  float temperature = dht.getTemperature();

  Serial.print(dht.getStatusString());
  Serial.print("\t");
  Serial.print(humidity, 1);
  Serial.print("\t\t");
  Serial.print(temperature, 1);
  Serial.print("\t\t");
  Serial.print(dht.toFahrenheit(temperature), 1);
  Serial.print("\t\t");
  Serial.print(dht.computeHeatIndex(temperature, humidity, false), 1);
  Serial.print("\t\t");
  Serial.println(dht.computeHeatIndex(dht.toFahrenheit(temperature), humidity, true), 1);
for (int k=0; k<50; k++)
{
  i+=20;
  /*
    strip.SetPixelColor(0, HslColor(+i, 8, 128));
    strip.SetPixelColor(1, HslColor(+i+10, 8, 128));
    strip.SetPixelColor(2, HslColor(+i+20, 8, 128));
    strip.SetPixelColor(3, HslColor(+i+30, 8, 128));
    
    strip.SetPixelColor(0, RgbColor((i/3)%128, 0, 0));
    strip.SetPixelColor(1, RgbColor(0, (i/3)%128, 0));
    strip.SetPixelColor(2, RgbColor(0, 0, (i/3)%128));
    */
    for (int l=0; l<8; l++)
    {
      strip.SetPixelColor(l, HslColor(((i+l*150)%1000)/1000.0, 1, 0.1));
    }
    strip.Show();
    
  delay(50);
}
}
