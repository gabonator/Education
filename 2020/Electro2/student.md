- preview
- pripravok 

## Uloha 1:

- Vypisat cisla od 0..10

```C
void setup() 
{
  Serial.begin(9600);
}

void loop() 
{
  int x = 0;
  Serial.print("Vypisujem cisla od 0 po 10:\n");
  while (x<=10)
  {
    Serial.print("x=");
    Serial.print(x);
    Serial.print("\n");
    x = x + 1;
  }
  delay(5000);
}
```
+ obrazok

## Uloha 2

Najdite predpis pre y1, y2, y3 a vypiste funkcne hodnoty pre 0..10

| x  | y1  | y2  | y3  |
-----|-----|-----|-----|
| 0  | 0   | 3   | 100 |
| 1  | 5   | 8   | 92  |
| 2  | 10  | 13  | 84  |
| 3  | 15  | 18  | 76  |
| 4  | 20  | 23  | 68  |
| 5  | 25  | 28  | 60  |
| 6  | 30  | 33  | 52  |
| 7  | 35  | 38  | 44  |
| 8  | 40  | 43  | 36  |
| 9  | 45  | 48  | 28  |
| 10 | 50  | 53  | 20  |

- Riesenie u2a
+ obrazok
- Riesenie u2b
+ obrazok

## Uloha 3

- Otestovat funkciu interpoluj
- Interpolovat hodnotu od 50 do 100 (v sto alebo 20 krokoch)
- Riesenie u3

## Uloha 4
- otvorit ukazku "blink.ino"
- pripojit pripravok
+ obrazok pripojenia 
- Rozsvietit jednotlive kanaly
- Vyskusat rozne kombinacie farieb
- Kolko roznych kombinacii vieme vytvorit z troch kanalov? 
- Ak su rozsvietene vsetky kanaly naraz, svietia vsetky rovnakou intenzitou?
- Riesenie u4

## Uloha 5
- otvorit ukazku "blink.ino"
- skusat menit frekvenciu tak, aby blikajuci jav prestal byt pozorovatelny
- pri akej frekvencii tento jav prestava byt pozorovatelny?

## Uloha 6
Príkaz Analog.write
Zistite v akom rozsahu je vstupný argument
Vytvorte bielu farbu
Vytvorte vašu obľúbenú farbu

## Uloha 7
Farebný prechod z červenej do modrej a naspäť 
Príkaz while alebo for


## Uloha 8
Vytvorte farby dúhy a prepínajte medzi nimi
+ obrazok s duhou
```C
void loop() 
{
  farba(148, 0, 211);
  farba(74, 0, 130);
  farba(0, 0, 255);
  farba(0, 255, 0);
  farba(255, 255, 0);
  farba(255, 127, 0);
  farba(255, 0, 0);
}

``` 

## Uloha 9
Plynulý prechod farieb dúhy s interpoláciou

## Uloha 10
- bonusova

