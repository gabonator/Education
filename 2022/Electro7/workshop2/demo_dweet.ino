#include "ESP8266WiFi.h"
#include "DHTesp.h"

// https://dweet.io/follow/creativepoint_svojemeno
// https://dweet.io/get/latest/dweet/for/creativepoint_svojemeno

const char* ssid = "*****";
const char* password = "*****";
const char* id = "creativepoint_ba1";

int counter = 0;

DHTesp dht;

void setup() 
{  
  Serial.begin(115200);
  pinMode(D1, OUTPUT);
  digitalWrite(D1, HIGH);
  pinMode(D3, OUTPUT);
  digitalWrite(D3, LOW);

  dht.setup(D2, DHTesp::DHT22);
  
  Serial.print("\n");
  Serial.print("Connecting to ");
  Serial.print(ssid);
  Serial.print("\n");
  WiFi.begin(ssid, password);
  
  while (WiFi.status() != WL_CONNECTED) 
  {
    delay(500);
    Serial.print(".");
  }

  Serial.print("\n");
  Serial.print("WiFi connected\n");
}

void loop() 
{
  counter++;

  float humidity = dht.getHumidity();
  float temperature = dht.getTemperature();

  Serial.print("Connecting...\n");
  
  WiFiClient client;
  if (!client.connect("dweet.io", 80)) 
  {
    Serial.println("connection failed");
    return;
  }
  
  client.print("GET /dweet/for/");
  client.print(id);
  client.print("?counter=");
  client.print(counter);
  client.print("&humidity=");
  client.print(humidity);
  client.print("&temperature=");
  client.print(temperature);
  client.print(" HTTP/1.1\r\n");
  client.print("Host: dweet.io\r\n");
  client.print("Connection: close\r\n");
  client.print("\r\n");
  
  delay(1000);

  Serial.print("\n<<<< Response >>>>\n");
  while(client.available())
  {
    char c = client.read();
    Serial.print(c);
  }
  Serial.print("\n===================\n");
 
  // Repeat every 5 seconds
  delay(5000); 
}
