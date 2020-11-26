# Electro workshop 4 - Standalone doska

Minimalne zapojenie bateriou napajaneho mikrokontrolera atmel ATTiny84 s diodami a spinacom v tvare Vianocnej hviezdice. Jas diod je riadeny softarovou implementaciou modifikovaneho PWM algoritmu. Mikrokontroler programujeme s pomocou ICSP interfacu, na tento ucel mozeme pouzit vhodny programator alebo lubovolne ine arduino. Pozrieme sa na moznosti, ako predlzit zivotnost bateriou napajaneho zariadenia a ake komponenty vyzaduje mikrokontroler pre svoju prevadzku.

[![Blikajuca hviezda](https://img.youtube.com/vi/yC3a1zbonJ0/0.jpg)](https://www.youtube.com/watch?v=yC3a1zbonJ0 "Blikajuca hviezda")

## BOM

- Nakup pre 8 ucastnikov kurzu dokopy 51.99 eur

| Pocet | Co                            | Oznacenie GME/TME                             | Jednotkova cena | Celkova cena | Linka         |
|-------|-------------------------------|-----------------------------------------------|-----------------|--------------|---------------|
| 8x    | AtTiny84, DIP14               | ATTINY84-20PU MICROCHIP (ATMEL)               | 2.6             | 20.8         | https://www.tme.eu/sk/details/attiny84-20pu/modelovy-rad-avr-8-bit/microchip-atmel/ |
| 8x    | Mikrospinac                   | Mikrospínač TC-0103-T (WM)                    | 0.11            | 0.88         | https://www.gme.sk/tc-0103-t |
| 40x   | Rezistor 470Ohm               | Metalizovaný rezistor RM 470R 0207 0,6W 1%    | 0.11            | 4.4          | https://www.gme.sk/rm-10k-0207-0-6w-1 | 
| 40x   | Cervena LED 5mm obycajna      | LED 5MM RED 400/50                            | 0.09            | 3.6          | https://www.gme.sk/led-5mm-red-400-50-bl-bje5v4v-2 |
| 1x    | Lista rovna 2x40              | Kolíková lišta S2G80 2,54mm                   | 0.39            | 0.39         | https://www.gme.sk/oboustranny-kolik-s2g80-2-54mm |
| 8x    | Kondenzator 100n              | Keramický kondenzátor CK 100n/100V X7R RM5,08 | 0.11            | 0.88         | https://www.gme.sk/ck-100n-100v-x7r-rm5-08-10-hitano |
| 8x    | Drziak baterie CR2032         | Držáik baterie do DPS DS1092-04 B6P           | 0.22            | 1.76         | https://www.gme.sk/drzaik-baterie-do-dps-ds1092-04-b6p |
| 8x    | Bateria CR2032                | Westinghouse CR2032 3V 220mAh lithiová        | 0.71            | 5.68         | https://www.gme.sk/baterie-gombikova-westinghouse-cr2032-3v-220mah-lithiova |
| 5x    | Doska PCB 20x10cm             | Cuprextit 200x100x1,5mm, jednovrstvový EPCU200X100 | 2.72       | 13.6         | https://www.gme.sk/cuprextit-200x100x1-5-jednovrstvy |

## Draft

![Isolation milling](isolationMilling.jpg)

![Lines](lines.png)

![Render](render1.png)

![Render](render2.png)


CNC Milling: [Milling](hviezda.bot.etch.tap)

CNC Holes: ![Holes](hviezda.bot.drill.tap)

Star script: ![Star script](star.js)
