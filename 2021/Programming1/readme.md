# Uvod do programovania 1

![readme](readme.png)

![readme2](readme2.jpg)

## Anotacia
Beseda: Vedeli ste o tom, že programovať sa dá naučiť za pol roka? Možno niektorí z vás už stáli pred rozhodnutím naučiť sa programovať, no po pr votnom prieskume množstva všetkých jazykov a technológií ste to radšej odložili na neskôr. Počas besedy si ukážeme ako napísať krátky program pre viac ako 10 rôznych jazykov. Vysvetlíme si, aké su medzi nimi rozdiely, a ako postupovať pri zoznamovaní sa s novým programovacím jazykom. Pozrieme sa na zakladné pojmy ako premenná, funkcia a podmienka. Taktiež predstavíme možnosti programovania aj bez použitia špeciálnych, často platených, integrovaných editorov IDE (Integrated development environment).

Workshop: Aj účastník bez predošlých algoritmických základov sa naučí zostaviť jednoduchý program a zapísať matematický alebo logický výraz tak, aby mu počítač rozumel. Pridáme premenné, slučky, funkcie a s pomocou týchto zakladných stavebných prkvov začneme generovať jednoduchú grafiku.
Na to, aby sme pretavili naše nápady do formy programu, nebude potrebný žiadny špeciálny software. Ukážeme si, že na programovanie stačí aj Microsoft Word alebo obyčajný browser.
A práve nástroj Developer Tools v browseri Chrome použijeme ako editor a debugger. S pomocou jazyka Javascript budeme generovať HTML kód, v ktorom budeme kombinovať obrázky, z ktorých zostavíme mozaiky a geometrické tvary.

## Priprava
- [stiahnut si balicek](prazdny.zip)
- rozbalit a otvorit test.html v Chrome
- otvorit developer konzolu (Ctrl + Shift + J, alebo tri bodky vpravo hore, More Tools -> Developer Tools)
  ![chrome1](chrome1.png)
- pridat adresar s rozbalenym balickom Source -> Filesystem -> Add folder to workspace
  ![chrome2](chrome2.png)
- vyskusat modifikovat test.html. Pri kazdom zmenenom subore sa zobrazi hviezdicka. Treba subor ulozit (Ctrl + S) a refreshnut stranku (Ctrl + R)
  ![chrome3](chrome3.png)
- Pocas workshopu budeme fotografovat nase vytvory s pomocou "Snipping tool"-u a zdielat v chate v Teamsoch. Ak tento nastroj nepoznate, natrenujte podla [tejto stranky](https://exaktime.zendesk.com/hc/en-us/articles/360037477253-FAQ-Capturing-Effective-Screenshots)
  ![snip1](https://exaktime.zendesk.com/hc/article_attachments/360049280033/Snipping-Selection.gif)
  ![snip2](https://exaktime.zendesk.com/hc/article_attachments/360049284273/Snipping.gif)

## Prezentacia
- Prezentacia je sucastou besedy: [prezentacia.pdf](prezentacia.pdf)

## Ulohy

### Uloha 1: Vyskusat si HTML tagy

```html
<h1>H1: Toto je moja stranka</h1>
<b>Bold</b> 
<i>Italic</i> 
<u>Underlined</u> 
Break<br>
Break<br>
<font color=gray>gray</font>
<font color=#ff0000>#ff0000</font>
<!-- poznamka -->
<br>
<br>
```

### Uloha 2: Kalkulacka
![uloha2](uloha2.png)

| Operacia                    | Zapis |
|-----------------------------|-----|
| Scitanie                    | 2 + 3 = 5 |
| Odcitanie                   | 2 - 3 = -1 |
| Nasobenie                   | 2 * 3 = 6 |
| Scitanie                    | 2 / 3 = 0.66666 |
| Umocnenie                   | Math.pow(2, 3) = 8 |
| Druha odmocnina             | Math.sqrt(9) = 3 |
| Zaokruhlenie nadol          | Math.floor(3.9) = 3 |
| Zvysok po deleni            | 7 % 4 = 3 |
| Absolutna hodnota           | Math.abs(-3) = 3 |
| PI                          | Math.PI = 3.141592653 |
| Sinus v radianoch           | Math.sin(Math.PI/4) = 0.70716 |
| Kosinus v radianoch         | Math.sin(Math.PI/4) = 0.70716 |
| Sinus v stupnoch            | Math.sin(45 / 180 * Math.PI) = 0.70716 |

### Uloha 3: Obvod a obsah stvorca

- doplnte riadok pre vypocet obsahu stvorca
```javascript
strana = 5
obvod = 4*strana
```
!!! riesenie 3

### Uloha 4: Porovnavanie
```javascript
5 < 10
5 >= 10
5 = 5
5 == 5
true == 15
```

- aj true a false mozeme porovnat s cislami, zistite akej numerickej hodnote sa rovna true a false

| Operator                    | Vyznam                    |
|-----------------------------|---------------------------|
| a >= b                      | a je vacsie alebo rovne b |
| a > b                       | a je vacsie ako b |
| a < b                       | a je mensie ako b |
| a <= b                      | a je mensie alebo rovne b |
| a == b                      | a je rovne b |
| a = b                       | nastav hodnotu b do premennej a |
| a != b                      | a je ine ako b |
| a                           | ak a je pravda (nie je nulove) |
| !a                          | ak a nie je pravda (ak a je nula) |
| !(a == b)                   | a je ine ako b |
| !(a > b)                    | a je mensie |

### Uloha 5: Alert a prompt
```javascript
meno = prompt("Ako sa volas")
alert("Ahoj " + meno)
```
- co robia funkcie prompt a alert?

### Uloha 6: Vypis cisel od 1 po 10
- editujeme test.js
- upravte program tak, aby cisla vypisal pod seba 
- !!!riesenie 6

```javascript
var i = 1
while (i <= 10)
{
    document.write(i);
    i = i + 1
}
```

### Uloha 7: Vypis cisel od 1 po 10 - obvod a obsah
- Upravte program tak, aby pre kazde cislo napisal "Stvorec so stranou X ma obvod X"
- !!! riesenie 7a
- Upravte program tak, aby pre kazde cislo napisal "Stvorec so stranou X ma obvod X a obsah X"
- !!! riesenie 7b

### Uloha 8:
- Modifikaciou test.html nakreslit tri cervene gulicky vedla seba
- TODO: obrazok (rrr)
- !!! riesenie 8a
- nakreslite maticu guliciek 3x3 podla obrazku
- TODO: obrazok (rgb,rgb,rgb)
- !!! riesenie 8b

### Uloha 9:
- vygenerovat HTML ktore nakresli 10 cervenych guliciek vedla seba

!!! debug 


| a     | b     | And <br> a && b <br> a zaroven | Or <br> a || b <br> alebo |
|-------|-------|-----------------|----------------|
| false | false | false           | false          |
| false | true  | false           | true           |
| true  | false | false           | true           |
| true  | true  | true            | true           |

```javascript
//???
```

