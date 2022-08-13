# Electro workshop s ESP8266

![image](readme.jpg)

## Annotation
Zaujíma vás ako fungujú bezdrôtové meteorologické stanice alebo inteligentné žiarovky? Na tomto workshope pod vedením skúseného lektora skonštruujete svoje vlastné IoT (internet vecí) zariadenie, ktoré bude prostredníctvom WiFi siete komunikovať s vaším mobilným telefónom. 
V prostredí Arduino budeme programovať modul ESP8266, ktorý spôsobil revolúciu vo svete IoT vzhľadom na svoju nízku cenu, malé rozmery, integrovaný WiFi modul a vysoký výpočtový výkon. Dnes ho nájdeme v inteligentných žiarovkách alebo telefónom ovládaných zásuvkách a iných, často podomácky skonštruovaných zariadeniach, ktoré komunikujú cez internet.

### Prvý workshop:
Aby sme vnikli do tajov programovania, najprv skúsime naprogramovať program pre ovládanie LED pásika. Ten bude zložený z ôsmich adresovateľných LED diód s označením WS2812. To nám umožní každej dióde nezávisle nastaviť farbu. Po statických vzoroch skúsime LED pásik rozanimovať, aby sme pochopili ako fungujú cykly s príkazom for a ako vytvoriť dojem pohybu.
Ďalšou úlohou bude pripojenie digitálneho teplomera kombinovaného s vlhkomerom DHT22. 

### Druhý workshop:
Po zvládnutí komunikácie s týmito perifériami vyskúšame použiť modul ESP8266 ako webový server. Najprv začneme s jednoduchými statickými stránkami, potom tieto skúsime oživiť čerstvo nameranými dátami z teplomera. 
Ďalšie úlohy už budú na fantázii účastníkov. Buď môžeme nastavovať farbu LED pásika podľa nameranej teploty, alebo jeho farbu budeme riadiť cez mobilný telefón. Ďalšou možnosťou je ukladanie nameraných dát na webovej platforme dweet.com a zobrazenie teploty vo forme grafu.

Workshop je určený pre úplných začiatočníkov bez skúseností s programovaním alebo konštrukcie elektrických zariadení. Treba si priniesť laptop, nainštalovať anglickú klávesnicu (kvôli programovaniu), skontrolovať či viete na klávesnici nájst všetky zátvorky a interpunkciu (https://x.valky.eu/progk) nainštalovať program Arduino (https://x.valky.eu/arduino) a podporu pre ESP8266 (https://x.valky.eu/esp). Kábel na pripojenie zariadenia budete mať k dispozícii USBA-USB micro, ak nemáte na počítači štandardné USB porty, treba si priniesť vlastný usb micro kábel alebo redukciu.

## BOM

| Pocet | Oznacenie                     | GME kod produktu | GME oznacenie                                         | Jednotkova cena | Celkova cena | Linka         |
|-------|-------------------------------|---------|-----------------------------------------------|-----------------|--------------|---------------|
| 8x    | Wemos D1 mini                 | 775-052 | NodeMcu LUA D1 mini WIFI ESP-12F modul s ESP8266 | 7.76         | 62.08        | https://www.gme.sk/nodemcu-lua-d1-mini-wifi-esp-12f-modul-s-esp8266 |
| 8x    | DHT22                         | 775-004 | Digitálny teplomer a vlhkomer, THT DHT22      | 8.37            | 66.96        | https://www.gme.sk/digitalny-teplomer-a-vlhkomer-s-dht22 |
| 8x    | WS2812 LED pas                | 774-031 | Modul 8x RGB digitálny LED, pás               | 2.82            | 22.56        | https://www.gme.sk/modul-fc101-8x-rgb-digitalny-led-pas |
| 8x    | Micro USB kabel               | 052-135 | Prepojovací kábel USB A 2.0 (M) - Micro USB B 2.0 (M), 1m červený | 1.59 | 12.72 | https://www.gme.sk/prepojovaci-kabel-goobay-usb-2-0-a-m-usb-2-0-micro-m-1m-cerveny |
| 2x    | Dupont kabel F-F              | 661-205 | Prepojovacie vodiče zásuvka-zásuvka 40 kusov  | 4.04            | 8.08         | https://www.gme.sk/propojovaci-vodice-zasuvka-zasuvka-40-kusu |

Price per one attendant: (62.08+66.96+22.56+12.72+8.08)/8=21.55

## Tasks

### Workshop 1
[prezentacia 1](prezentacia1.pdf)

1. Nainstalovat Arduino
2. Nainstalovat podporu pre esp8266
3. Blink esp8266
4. Instalacia kniznice pre ws2812 (NeoPixelBus by Makuna)
5. Zapojte led pasik
  ![schemeled.jpeg](schemeled.jpeg)

6. Examples -> NeoPixel by Makuna -> NeoPixelCyclon, zmenit dva riadky:
    ```C
    // pocet bodov zvysit na 8 (povodne 4)
    const uint16_t PixelCount = 8;
    // driver nastavit na NeoEsp8266Uart1800KbpsMethod (povodne Neo800KbpsMethod)
    NeoPixelBus<NeoGrbFeature, NeoEsp8266Uart1800KbpsMethod> strip(PixelCount, PixelPin);
    ```

7. Co urobi nasledujuci program?

    ```C
    #include <NeoPixelBus.h>

    NeoPixelBus<NeoGrbFeature, NeoEsp8266Uart1800KbpsMethod> strip(8);

    void setup()
    {
      strip.Begin();
      strip.Show();
    }

    void loop()
    {
      // red, green, blue (0..255)
      strip.SetPixelColor(0, RgbColor(100, 0, 0));
      strip.SetPixelColor(1, RgbColor(0, 100, 0));
      strip.SetPixelColor(2, RgbColor(0, 0, 100));
      strip.SetPixelColor(3, RgbColor(32, 0, 0));
      strip.SetPixelColor(4, RgbColor(32, 32, 0));
      strip.SetPixelColor(5, RgbColor(32, 32, 32));
      strip.SetPixelColor(6, RgbColor(0, 32, 32));
      strip.SetPixelColor(7, RgbColor(16, 0, 32));

      // hue, saturation, lightness (0..1)
      strip.SetPixelColor(7, HslColor(0.5, 1.0, 0.1));
      
      strip.Show();
      delay(100);
    }

    ```

8. Upravit program na animaciu semaforu

    ```C
    #include <NeoPixelBus.h>

    NeoPixelBus<NeoGrbFeature, NeoEsp8266Uart1800KbpsMethod> strip(8);

    void setup()
    {
      strip.Begin();
      strip.Show();
    }

    void loop()
    {
      // red, green, blue (0..255)
      strip.SetPixelColor(0, RgbColor(10, 0, 0));
      strip.Show();
      delay(1000);

      strip.SetPixelColor(0, RgbColor(0, 10, 0));
      strip.Show();
      delay(1000);

      strip.SetPixelColor(0, RgbColor(0, 0, 10));
      strip.Show();
      delay(1000);
    }
    ```

8.5. Co urobi nasledujuci program?
  - Otvorte si monitor seriovej linky **Tools** -> **Serial monitor**
  - Nastavte prenosovu rychlost na **9600 baud**
    ```C
    void setup() {
      Serial.begin(9600);
    }

    void loop() {
      for (int i=0; i<100; i+=5)
      {
        Serial.println(i);
      }
      delay(1000);
    }
    ```
8.6. Upravte ho na vypis ciselnej postupnosti 10 az 20 (vratane) s krokom 2
8.7. Najdite hodnotu konstanty maximum aby bola animacia plynula
  - Zatvorte monitor seriovej linky
    ```C
    #include <NeoPixelBus.h>
    NeoPixelBus<NeoGrbFeature, NeoEsp8266Uart1800KbpsMethod> strip(8);

    void setup() {
      strip.Begin();
    }

    void loop() {
      const int maximum = 300;
      for (int i=0; i<maximum; i+=1)
      {
          strip.SetPixelColor(0, RgbColor(i, 0, 0));
          strip.Show();
          delay(10);
      }
      for (int i=maximum; i>0; i-=1)
      {
          strip.SetPixelColor(0, RgbColor(i, 0, 0));
          strip.Show();
          delay(10);
      }
    }
    ```
9. Naprogramujte:

  ![curve1](curve1.png)

  - Jednoduchy farebny prechod (0, 0, 0) -> (0, 50, 0) s trvanim 5 sekund

  ![curve2](curve2.png)

  - Jednoduchy farebny prechod (0, 0, 0) -> (25, 50, 25) s trvanim 5 sekund

  ![curve3](curve3.png)

  - Jednoduchy farebny prechod (0, 0, 25) -> (0, 0, 25) s trvanim 5 sekund

  ![curve4](curve4.png)

  - Jednoduchy farebny prechod (50, 0, 0) -> (0, 50, 0) s trvanim 5 sekund

11. Ako urobit prechod z tmavo modrej do svetlo zelenej? (7, 4, 15) -> (2, 17, 8)
12. Linearna interpolacia

  ![linear1](linear1.png)

  ![linear2](linear2.png)

  ![linear3](linear3.png)

  ![linear4](linear4.png)

  ![linear5](linear5.png)

  ![linear6](linear6.png)
          
  ![linear7](linear7.png)

  ![linear8](linear8.png)

13. DHT22 - nainstalovat kniznicu
14. Pripojenie senzora DHT
  ![schemedht.jpeg](schemedht.jpeg)

15. DHT sensor library for ESPx -> DHT_ESP8266
16. nefunguje, potrebujeme napajanie, upravit cislo pinu

    ```C
    pinMode(D1, OUTPUT);
    digitalWrite(D1, HIGH);
    pinMode(D3, OUTPUT);
    digitalWrite(D3, LOW);

    dht.setup(D2, DHTesp::DHT22); // Connect DHT sensor to GPIO 17
    ```

17. Porovnavanie hodnoty, zapnut led pri vyssej vlhkosti,
18. Kreslit graf s internym toolom

19. Bonus: Menit farbu podla vlhkosti/teploty
20. Bonus: Pekne animacie sin/cos

### Workshop 2

1. Ako prebieha HTTP request?

![http1.png](http1.png)

![http2.png](http2.png)

    ```
    gabrielvalky@Gabriels-MacBook-Air ~ % telnet 37.9.175.26 80
    GET /ahoj.html HTTP/1.0
    Host: gabo.guru

    ```

2. Vytvorte vlastny server: 
  - nastavte spravne prihlasovacie udaje pre nasu wifi, 
  - zistite na akej IP adrese bezi (pouzite seriovej linky) a 
  - nechajte ho vypisat vlastne meno

    ```C
    #include <ESP8266WiFi.h>
    #include <WiFiClient.h>
    #include <ESP8266WebServer.h>

    char* ssid = "******";
    char* password = "******";
     
    ESP8266WebServer server(80);

    void handleRoot() 
    {
     server.send(200, "text/html", "Ahoj, ja sa volam Gabo!");
    }

    void setup(void)
    {
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
      server.begin();
    }

    void loop(void)
    {
      server.handleClient();
    }
    ```

3. Skuste vyuzit niektore html tagy (b-bold, u-underline, hr-line, body bgcolor)

    ```
    #include <ESP8266WiFi.h>
    #include <WiFiClient.h>
    #include <ESP8266WebServer.h>

    char* ssid = "******";
    char* password = "******";
     
    ESP8266WebServer server(80);

    char* html = R""(
    <HTML>
      <HEAD>
          <TITLE>My first web page</TITLE>
      </HEAD>
    <BODY>
      <CENTER>
          <B>Hello World.... </B>
      </CENTER> 
    </BODY>
    </HTML>
    )"";
      
    void handleRoot() 
    {
     server.send(200, "text/html", html);
    }

    void setup(void)
    {
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
      server.begin();
    }

    void loop(void)
    {
      server.handleClient();
    }
    ```

## Notes

1. Workshop
  - programovanie ESP8266 v prostredi Arduino
  - praca s adresovatelnymi LED
  - meranie teploty a vlhkosti s ESP8266
2. Workshop
  - webserver s ESP8266
  - generovanie HTML
  - generovanie HTML s nameranymi udajmi (teplota vlhkost)
  - nastavovanie farby led pasika cez web rozhranie
  - zobrazovanie udajov vo forme grafu na webe
  - captive portal
  - falosna login stranka

TBD
