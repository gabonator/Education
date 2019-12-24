# Elektro bootcamp

## Session1: elektrika - paralela s vodou

### bom

- LED cervena, LED zelena, LED oranzova, 3x predradny rezistor, lamacia lista 4 piny, arduino uno

### teoria (60 min)

- jednoduchy obvod, zdroj, spotrebic, sirka rury, ventil zuzi prietok iba na par centimetroch
- potencial, aky tlak ukazuje manometer?
- prudovy kirchhoffov zakon
- napatovy kirchhoffov zakon, rozdiel potencialov
- ohmov zakon, linearne prvky
- nelinearne prvky, paralela s diodou

### prax (45 min)

- pozriet datasheet ku diode a zvolit rezistor pri 5V napajani
- zletovat 3x led + 3x rezistor, spolocna anoda, katoda, semafor


### programovanie (75 min)
- rozblikat ledku ako skutocny semafor
- frekvencia, rozblikat tak, aby sa nam to javilo ako konstantny jas
- softwarove PWM, menit jas podla trojuholnikoveho signalu
- hardwarove PWM

## Session2: adresovatelne led diody

### bom
- adresovatelne ledky, pripajacie kable, arduino uno
- https://www.gme.sk/modul-fc101-8x-rgb-digitalny-led-pas, 8x RGB, 2.72 eur

### teoria (60 min)
- protokol WS2812
- aditivny model zmiesavania farieb

### prax (30 min)
- priletovat si kabik ku rgb stripu

### programovanie (90 min)
- ovladat jednu ledku, ovladat vsetky ledky
- zakladne farby
- rozne animacie
- harmonicke funkcie
- pohyb

## Session3: digitalny vstup

### bom
- spinac, prepinac, pullup rezistor, arduino

### teoria (60 min)
- analogovy vstup, digitalny vstup
- HiZ impedance, antena
- pull up/pull down/integrovany
- debounce

### prax (30 min)
- zletovat tlacitko a prepinac s pull down rezistorom

### programovaine (90 min)
- rozsvietit ledku podla stavu na HiZ (prst)
- vypisovat hodnoty, bude tam nieco periodicke (antena)
- pripojit spinac/prepinac ku vstupnemu pinu, rozsvietit led podla toho ci je zopnuty
- switcher, debounce
- pozriet si to na osciloskope

## Session4: most useless box

### bom
- krabicka, servo, arduino uno, prepajacie kabliky, 9v klip, 9v bateria

### design
- Andrej

### teoria
- ovladanie serva
- pullup prepimac

### programovanie
- prepinac - servo
