# Ulohy

## string ako premenna, zakladne operacie

- scitavanie, alert, indexovanie, vkladanie premennych do textu

```javascript
// premenna a scitavanie
moja = "ahoj"
meno = "Gabo"
alert(moja + meno)

// prilepovanie
nieco = "abc"
nieco = nieco + "def"
nieco += "ghi"

abeceda = "abcdefghijklmnopqrstuvwxyz"
abeceda[3]
abeceda[100]
abeceda[-5]
abeceda[3.5]
console.log("Pismeno na piatom mieste je " + abeceda[5])
console.log("Pismeno na piatom mieste je ", abeceda[5])
console.log(`Pismeno na piatom mieste je ${abeceda[5]}`)

// split a join
veta = "Toto je moja jednoducha rozvita veta"
slova = veta.split(" ")
novaveta = slova.join(",")
cisla = [5, 6, 7, 2, 1, 9, 0]
cisla.join(" a ")
"jablko".split("")
"jablko".split("").join("  ")

// pokrocile funkcie
abeceda.substr(5, 4)
abeceda.indexOf("m")
abeceda.indexOf("M")
abeceda.length
```

## praca s DOM

- getElementById, innerHTML, style, background

```html
<div id="mojdiv">Toto je moj div</div>
```

```html
<script>
document.getElementById("mojdiv").innerHTML = "Bla bla"
document.getElementById("mojdiv").style.background = "red"
document.getElementById("mojdiv").style.background = "#00d0ff"
document.getElementById("mojdiv").style.fontSize = "100px"
document.getElementById("mojdiv").style.textColor = "gray"
</script>
```

## Loopy

- pouzitie prikazu `for` a vnoreny `for`

- Uloha 1: napiste vase meno bielou na ciernom pozadi
- Uloha 2: dopln kod s prikazom `for`

```javascript
for (var i=0; i<20; i++)
{
  document.getElementById("mojdiv").innerHTML += `obvod stvorca so stranou ${i} je ?`;
}
```
- Uloha 3: Uprav program aby vypisal kazdy obvod na samostatny riadok
- Uloha 4: Vypis pre kazdy rozmer stvorca v rozsahu 1..10 jeho obvod a obsah
- Uloha 5: Vypis svoje meno 100 krat
- Uloha 6: Vypis svoje meno 100 krat, tak aby bolo v kazdom riadku prave 10 krat

## Dvojrozmerne pole a DOM

```javascript
var slova = [
    "macka",
    "kniha",
    "pavuk",
    "krtko",
    "mrkva"
  ];
```

- Uloha 7: Ako ziskat prvy a posledny prvok?
- Uloha 8: Ako ziskat treti znak stvrteho slova?
- Uloha 9: Doplnte nasledujuci kod tak, aby ste vytvorili maticu 5x5 elementov a kazdy z nich bude obsahovat prislusny znak podla pola `slova`

```html
<div id="hra"></div>

<script>
var hra = document.getElementById("hra");

for (var y=0; y<?; y++)
{
  for (var x=0; x<?; x++)
    hra.innerHTML += `<span id='cell_${x}_${y}'></span>`;
  hra.innerHTML += "<br>";
}
</script>
```

- Uloha 10: Preiterujte pole este raz a tym bunkam ktore obsahuju samohlasku nastavte zelene pozadie

```javascript
for (var y=0; y<?; y++)
{
  for (var x=0; x<?; x++)
  {
    var cell = document.getElementById(`cell_${x}_${y}`);
    // tuto doplnit kod
  }
}
```

- Uloha 11: upravte predosly program tak aby ste pouzili prikaz `switch`:

```javascript
  switch (nieco)
  {
    case "a": console.log("Samohlaska a"); break;
    case "b": console.log("Spoluhlaska b"); break;
    case "c": console.log("Spoluhlaska c"); break;
    case "d": console.log("Spoluhlaska d"); break;
    default: console.log("Nieco ine");
  }
```

- Uloha 12: nastavte kazdej bunke rozmery 55x55 pixelov (`cell.style.width = "55px"`, `cell.style.height = "55px"`, `cell.style.display = "inline-block"`)

## Mapa hry

- Uloha 13: Vytvorte s pomocou znakov mriezka a medzera bludisko

```javascript
var mapa = [
  "##########",
  "#        #",
  "#        #",
  "#        #",
  "#        #",
  "#        #",
  "#        #",
  "#        #",
  "#        #",
  "##########"];
```

- Uloha 14: Vykreslite bludisko, prazdny priestor sivou a steny cervenou
- Uloha 15: Ulozte do premennych `hracx` a `hracy` suradnicu (x - stlpec, y - riadok) kde ma hrac zacinat

## Pohyb po hracom poli

- Uloha 16: Vyfarbite policko urcene tymito suradnicami namodro
- Uloha 17: Doplnte funkciu `pohyb` tak, aby sa hrac presuval po bludisku

```javascript
function pohyb(dx, dy)
{
  // dopln kod
}

document.addEventListener("keydown", e => {
  var leftKey = 37, upKey = 38, rightKey = 39, downKey = 40, spaceKey = 32;
  switch (e.keyCode)
  {
    case leftKey: pohyb(-1, 0); break;
    case rightKey: pohyb(+1, 0); break;
    case upKey: pohyb(0, -1); break;
    case downKey: pohyb(0, +1); break;
  }
});
```

- Uloha 18: Osetrite situaciu kedy by sa chcel hrac posunut na miesto kde sa pred tym nachadzala stena (prikaz `if`)
- Checkpoint 1: bludisko so smajlikom

## UTF8 symboly
- Uloha 19: Hraca vykreslite ako hviezdicku `*` (s nastavenim `innerHTML`)
- Uloha 20: Hraca vykreslite s pomocou symbolu `"&#x1f600;"`
- Uloha 21: Vyberte iny symbol na zobrazenie hraca

- Utf8 symboly: 
  - [utf8-icons.com](https://utf8-icons.com/subset/miscellaneous-symbols-and-pictographs)
  - [symbl.cc - emoticons](https://symbl.cc/en/unicode/blocks/emoticons/)
  - [symbl.cc - misc](https://symbl.cc/en/unicode/blocks/miscellaneous-symbols-and-pictographs/)
  - [unicode.org](https://unicode.org/emoji/charts/full-emoji-list.html)

- nastylovanie textu (overflow, fontSize, textAlign, lineHeight)

```html
<span id="cell"></span>

<script>
  var cell = document.getElementById(`cell`)
  cell.style.display = "inline-block"
  cell.style.overflow = "hidden"
  cell.style.width = "55px"
  cell.style.height = "55px"
  cell.style.fontSize = "40px"
  cell.style.textAlign = "center"
  cell.style.lineHeight = "60px"
  cell.style.background = "#d0d0d0"
  cell.innerHTML = "&#x1f511;"
</script>
```

- Uloha 22: Pridanie ciela
- Uloha 23: Pridanie kluca a dveri (treba prerobit mapu z pola retazov na pole poli znakov s prikazom `split`)

- Checkpoint 2: puzzle s cielom

## Tile map

```html
<span id="cell"></span>
<script>
var cell = document.getElementById(`cell`);
cell.style.display = "inline-block";
cell.style.overflow = "hidden";
cell.style.width = "55px";
cell.style.height = "55px";
cell.style.background = "url(tiles.png)";
cell.style.backgroundRepeat = "no-repeat";
cell.style.backgroundPosition = "-250px -128px";
</script>
```
- Uloha 24: Cez element inspector upravit `backgroundPosition` atribut tak, aby sme ziskali tehlovu stenu
- Uloha 25: Pridanie tile map do hry (background, backgroundRepeat, backgroundPosition)
- Checkpoint 3: Otexturovana mapa

## Sokoban
- Uloha 26: pridanie predmetov a posuvanie
- Uloha 27: pouzite level:
  - [sokoban/level01.js](sokoban/level01.js)
  - [sokoban/level02.js](sokoban/level02.js)
  - [sokoban/level03.js](sokoban/level03.js)
  - [sokoban/level04.js](sokoban/level04.js)
  - [sokoban/level05.js](sokoban/level05.js)
- Checkpoint 4: sokoban
