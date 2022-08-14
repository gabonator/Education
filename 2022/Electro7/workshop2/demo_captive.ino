#include <ESP8266WiFi.h>
#include <WiFiClient.h>
#include <ESP8266WebServer.h>
#include <DHTesp.h>
#include <DNSServer.h>

char* apSsid = "esp weather";

IPAddress         apIP(10, 10, 10, 1);
ESP8266WebServer  server(80);
DNSServer         dnsServer;  

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

  WiFi.mode(WIFI_AP);
  WiFi.softAPConfig(apIP, apIP, IPAddress(255, 255, 255, 0));
  WiFi.softAP("ahoj");
  
  dnsServer.start(53, "*", apIP);

  server.on("/", handleRoot);
  server.on("/meraj", handleMeraj);
  server.onNotFound(handleRoot);
  server.begin();

  pinMode(D1, OUTPUT);
  digitalWrite(D1, HIGH);
  pinMode(D3, OUTPUT);
  digitalWrite(D3, LOW);  
}

void loop(void)
{
  server.handleClient();
  dnsServer.processNextRequest();
}
