#include <ESP8266WiFi.h>
#include <WiFiClient.h>
#include <ESP8266WebServer.h>

#include <NeoPixelBus.h>
NeoPixelBus<NeoGrbFeature, NeoEsp8266Uart1800KbpsMethod> strip(8);

char* ssid = "*****";
char* password = "*****";
 
ESP8266WebServer server(80);
  
void handleRoot() 
{
  String html = R""(
<html>
  <head>
      <title>Moja meteo stanica</title>
  </head>
<body>
  <center>
      <a href="/red">Nastav cervenu</a>
      <a href="/green">Nastav zelenu</a>
      <a href="/blue">Nastav modru</a>
      <a href="/black">Nastav ciernu</a>
  </center> 
</body>
</html>
)"";

  server.send(200, "text/html", html);
}

void setup(void)
{
  strip.Begin();
  strip.Show();
  Serial.begin(9600);
  
  WiFi.begin(ssid, password);
 
  while (WiFi.status() != WL_CONNECTED) 
  {
    delay(500);
    Serial.print(".");
  }
 
  Serial.print("\n");
  Serial.print("Connected to ");
  Serial.print(ssid);
  Serial.print("\n");
  Serial.print("IP address: ");
  Serial.print(WiFi.localIP());
  Serial.print("\n");
 
  server.on("/", handleRoot);
  
  server.on("/red", []() {
    server.send(200, "text/plain", "Nastavil som cervenu farbu");
    strip.SetPixelColor(5, RgbColor(16, 0, 0));
    strip.Show();
  });

  server.on("/green", []() {
    server.send(200, "text/plain", "Nastavil som zelenu farbu");
    strip.SetPixelColor(5, RgbColor(0, 16, 0));
    strip.Show();
  });

  server.on("/blue", []() {
    server.send(200, "text/plain", "Nastavil som modru farbu");
    strip.SetPixelColor(5, RgbColor(0, 0, 16));
    strip.Show();
  });

  server.on("/black", []() {
    server.send(200, "text/plain", "Nastavil som ciernu farbu");
    strip.SetPixelColor(5, RgbColor(0, 0, 0));
    strip.Show();
  });
  
  server.begin();
}

void loop(void)
{
  server.handleClient();
}
