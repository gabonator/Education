#include <ESP8266WiFi.h>
#include <WiFiClient.h>
#include <ESP8266WebServer.h>
#include <ESP8266mDNS.h>

#include "DHTesp.h"
#include <NeoPixelBus.h>

DHTesp dht;
NeoPixelBus<NeoGrbFeature, NeoEsp8266Uart1800KbpsMethod> strip(8);

#ifndef STASSID
#define STASSID "lucia"
#define STAPSK  "Stefanikova15"
#endif

const char* ssid = STASSID;
const char* password = STAPSK;

ESP8266WebServer server(80);

//const int led = 13;

void handleRoot() {
  //digitalWrite(led, 1);
  server.send(200, "text/plain", "hello from esp8266!\r\n");
  //digitalWrite(led, 0);
}

void handleNotFound() {
 // digitalWrite(led, 1);
  String message = "File Not Found\n\n";
  message += "URI: ";
  message += server.uri();
  message += "\nMethod: ";
  message += (server.method() == HTTP_GET) ? "GET" : "POST";
  message += "\nArguments: ";
  message += server.args();
  message += "\n";
  for (uint8_t i = 0; i < server.args(); i++) {
    message += " " + server.argName(i) + ": " + server.arg(i) + "\n";
  }
  server.send(404, "text/plain", message);
  //digitalWrite(led, 0);
}

void setup(void) {
  strip.Begin();
  strip.Show();

  pinMode(D1, OUTPUT);
  digitalWrite(D1, HIGH);
  pinMode(D3, OUTPUT);
  digitalWrite(D3, LOW);
  dht.setup(D2, DHTesp::DHT22); // Connect DHT sensor to GPIO 17
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, 0);

  
  //pinMode(led, OUTPUT);
  //digitalWrite(led, 0);
  Serial.begin(115200);
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  Serial.println("");

  // Wait for connection
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("");
  Serial.print("Connected to ");
  Serial.println(ssid);
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());

  if (MDNS.begin("esp8266")) {
    Serial.println("MDNS responder started");
  }

  server.on("/", handleRoot);

  server.on("/read", []() {
    float humidity = dht.getHumidity();
    float temperature = dht.getTemperature();
    char msg[64];
    sprintf(msg, "t=%f, h=%f", temperature, humidity);
    server.send(200, "text/plain", msg);
  });

  server.on("/red", []() {
    server.send(200, "text/plain", "this works as well");
    strip.SetPixelColor(5, RgbColor(16, 0, 0));
    strip.Show();
  });

  server.on("/grn", []() {
    server.send(200, "text/plain", "this works as well");
    strip.SetPixelColor(5, RgbColor(0, 16, 0));
    strip.Show();
  });

  server.on("/blu", []() {
    server.send(200, "text/plain", "this works as well");
    strip.SetPixelColor(5, RgbColor(0, 0, 16));
    strip.Show();
  });

  server.on("/blk", []() {
    server.send(200, "text/plain", "this works as well");
    strip.SetPixelColor(5, RgbColor(0, 0, 0));
    strip.Show();
  });
  

  server.onNotFound(handleNotFound);

  server.addHook([](const String & method, const String & url, WiFiClient * client, ESP8266WebServer::ContentTypeFunction contentType) {
    (void)method;      // GET, PUT, ...
    (void)url;         // example: /root/myfile.html
    (void)client;      // the webserver tcp client connection
    (void)contentType; // contentType(".html") => "text/html"
    //Serial.printf("A useless web hook has passed\n");
    //Serial.printf("(this hook is in 0x%08x area (401x=IRAM 402x=FLASH))\n", esp_get_program_counter());
    return ESP8266WebServer::CLIENT_REQUEST_CAN_CONTINUE;
  });

  server.begin();
  Serial.println("HTTP server started");
   strip.Begin();
  strip.Show();
}

void loop(void) {
  server.handleClient();
  MDNS.update();
}
