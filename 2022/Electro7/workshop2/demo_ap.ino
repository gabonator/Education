#include <ESP8266WiFi.h>
#include <WiFiClient.h>
#include <ESP8266WebServer.h>
#include <DHTesp.h>

char* apSsid = "esp gabo";
char* apPassword = "11111111";

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
      <a href="/meraj">Klikni sem pre zobrazenie vysledkov merania</a>
  </center> 
</body>
</html>
)"";

  server.send(200, "text/html", html);
}

void handleMeraj() 
{
  DHTesp dht;
  dht.setup(D2, DHTesp::DHT22);
  
  String html = "Teplota: " + String(dht.getTemperature()) + " &deg;C<br>";
  html = html + "Vlhkost: " + String(dht.getHumidity()) + "%<br>";
  html = html + "<script>setTimeout(() => document.location.reload(), 1000)</script>";
  server.send(200, "text/html", html);
}

void setup(void)
{
  Serial.begin(9600);
  
  WiFi.softAP(apSsid, apPassword);
 
  Serial.print("\nSoft ap running: ");
  Serial.print("ssid: ");
  Serial.print(apSsid);
  Serial.print(" password: ");
  Serial.print(apPassword);
  Serial.print("\n");
  
  Serial.print("IP address: ");
  Serial.print(WiFi.softAPIP());
  Serial.print("\n");
 
  server.on("/", handleRoot);
  server.on("/meraj", handleMeraj);
  server.begin();
  
  pinMode(D1, OUTPUT);
  digitalWrite(D1, HIGH);
  pinMode(D3, OUTPUT);
  digitalWrite(D3, LOW);
}

void loop(void)
{
  server.handleClient();
}
