#include <ESP8266WiFi.h>
#include <WiFiClient.h>
#include <ESP8266WebServer.h>
#include <NeoPixelBus.h>
#include <EEPROM.h>

const char* ssid = "*****";
const char* password = "*****";

ESP8266WebServer server(80);

String nacitajEeprom(int adresa)
{
  char temp[64];
  for (int i=0; i<63; i++)
  {
    temp[i] = EEPROM.read(adresa+i);
    if (temp[i] == 0)
      break;
  }
  return String(temp);
}

void zapisEeprom(int adresa, String text)
{
  for (int i=0; i<text.length()+1; i++)
    EEPROM.write(adresa+i, text[i]);
}

void dokonciEeprom()
{
  EEPROM.commit();
}


void setup(void) 
{
  EEPROM.begin(128);
  
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

  server.on("/", [](){
    server.send(200, "text/html", R""(
    <h1>Formular</h1>

    <form action="/prihlasma">
    Meno: <input type=text name="meno"><br>
    Heslo: <input type=password name="heslo"><br>
    <input type="submit" value="Prihlasit">
    </form>
    )"");   
  });
  
  server.on("/prihlasma", [](){
    String meno = server.arg("meno");
    String heslo = server.arg("heslo");
    
    String html = "Zadal si meno:" + meno + " a heslo: " + heslo;    
    server.send(200, "text/html", html);  
    
    zapisEeprom(0, "gabo");
    zapisEeprom(10, meno);
    zapisEeprom(60, heslo);
    dokonciEeprom();
  });

  server.on("/posledny", [](){
    String kontrola = nacitajEeprom(0);
    String html;
    if (kontrola == "gabo")
    {
      String meno = nacitajEeprom(10);
      String heslo = nacitajEeprom(60);
      html = "Posledne meno:" + meno + " a heslo: " + heslo;
    } else {
      html = "Este neboli zadane ziadne prihlasovacie udaje";
    }
    server.send(200, "text/html", html);  
  });
  
  server.begin();
}

void loop(void) 
{
  server.handleClient();
}

