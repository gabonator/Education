#include <ESP8266WiFi.h>
#include <WiFiClient.h>
#include <ESP8266WebServer.h>
#include <NeoPixelBus.h>

ESP8266WebServer server(80);
NeoPixelBus<NeoGrbFeature, NeoEsp8266Uart1800KbpsMethod> strip(8);
const char* ssid = "*****";
const char* password = "*****";
int r1, g1, b1, r2, g2, b2;

void handleRoot() 
{
  String html = R""(
    <input type="color" id="set1" value="#000000">
    <input type="color" id="set2" value="#000000">
    <script>
      document.querySelectorAll("input[type='color']")
        .forEach(e => e.addEventListener("input", updateColor, false));
                
      function updateColor()
      {
        var html = event.target.value;
        var id = event.target.id;
        var color = parseInt("0x"+html.substr(1));
        var r = color >> 16, g = (color >> 8) & 0xff, b = color & 0xff;
        r /= 4; g /= 4; b /= 4;
        const xhr = new XMLHttpRequest()
        xhr.open("GET", `${id}?r=${r}&g=${g}&b=${b}`);
        xhr.send()
      }
    </script>
  )"";
  server.send(200, "text/html", html);
}

void handleSet1()
{
  r1 = server.arg("r").toInt();
  g1 = server.arg("g").toInt();
  b1 = server.arg("b").toInt();
  vykresli();    
  server.send(200, "text/plain", "ok");  
}

void handleSet2()
{
  r2 = server.arg("r").toInt();
  g2 = server.arg("g").toInt();
  b2 = server.arg("b").toInt();
  vykresli();    
  server.send(200, "text/plain", "ok");  
}

int interpoluj(int x1, int x2, int percent)
{
  return x1 + (x2-x1)*percent/100;
}

void vykresli()
{
  for (int i=0; i<8; i++)
  {
    int r = interpoluj(r1, r2, i*100/7);
    int g = interpoluj(g1, g2, i*100/7);
    int b = interpoluj(b1, b2, i*100/7);
    strip.SetPixelColor(i, RgbColor(r, g, b));
  }
  strip.Show();
}

void setup(void) 
{
  strip.Begin();
  strip.Show();
  
  Serial.begin(115200);
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) 
  {
    delay(500);
    Serial.print(".");
  }
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());

  server.on("/", handleRoot);
  server.on("/set1", handleSet1);
  server.on("/set2", handleSet2); 
  server.begin();
}

void loop(void) 
{
  server.handleClient();
}
