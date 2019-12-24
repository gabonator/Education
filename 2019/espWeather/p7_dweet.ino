#include "ESP8266WiFi.h"

const char* ssid = "******";
const char* password = "******";

int counter = 10000;

void setup() 
{  
  Serial.begin(115200);
  
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

  // https://dweet.io/follow/gabonator_1
  // https://dweet.io/dweet/for/gabonator_1?counter=10123
  
  Serial.print("Connecting...\n");
  
  WiFiClient client;
  if (!client.connect("dweet.io", 80)) 
  {
    Serial.println("connection failed");
    return;
  }
    
  client.print("GET /dweet/for/gabonator_1?counter=");
  client.print(counter);
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
 
  // Repeat every 10 seconds
  delay(10000); 
}