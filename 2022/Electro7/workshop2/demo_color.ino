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
      <a href="/color?r=50&g=0&b=0">Nastav cervenu</a>
      <a href="/color?r=0&g=50&b=0">Nastav zelenu</a>
      <a href="/color?r=0&g=0&b=50">Nastav modru</a>
      <a href="/color?r=0&g=0&b=0">Nastav ciernu</a>
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
  
  server.on("/color", []() {
    int r = server.arg("r").toInt();
    int g = server.arg("g").toInt();
    int b = server.arg("b").toInt();
    strip.SetPixelColor(5, RgbColor(r, g, b));
    strip.Show();
    
    server.sendHeader("Location", String("/"), true);
    server.send(302, "text/plain", "");
  });
  
  server.begin();
}

void loop(void)
{
  server.handleClient();
}
