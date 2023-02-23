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

```javascript
document.getElementById("mojdiv").innerHTML = "Bla bla"
document.getElementById("mojdiv").style.background = "red"
document.getElementById("mojdiv").style.background = "#00d0ff"
document.getElementById("mojdiv").style.fontSize = "100px"
document.getElementById("mojdiv").style.textColor = "gray"
```

## Loopy

- pouzitie prikazu `for` a vnoreny `for`

- Uloha: napiste vase meno bielou na ciernom pozadi
- Uloha: dopln kod s prikazom `for`
```
for (var i=0; i<20; i++)
{
  document.getElementById("mojdiv").innerHTML += `obvod stvorca so stranou ${i} je ?`;
}
```
- Uloha: Vypis pre kazdy rozmer stvorca v rozsahu 1..10 jeho obvod a obsah
- Uloha: Vypis svoje meno 100 krat
- Uloha: Vypis svoje meno 100 krat, tak aby bolo v kazdom riadku prave 10 krat

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

- Uloha: Ako ziskat prvy a posledny prvok?
- Uloha: Ako ziskat treti znak stvrteho slova?
- Uloha: Doplnte nasledujuci kod tak, aby ste vytvorili maticu 5x5 elementov a kazdy z nich bude obsahovat prislusny znak podla pola `slova`

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

- Uloha: Preiterujte pole este raz a tie bunkam ktore obsahuju samohlasku nastavte zelene pozadie
```
for (var y=0; y<?; y++)
{
  for (var x=0; x<?; x++)
  {
    var cell = document.getElementById(`cell_${x}_${y}`);
    // tuto doplnit kod
  }
}
```

- Uloha: upravte predosly program tak aby ste pouzili prikaz `switch`:
```
  switch (nieco)
  {
    case "a": console.log("Samohlaska a"); break;
    case "b": console.log("Spoluhlaska b"); break;
    case "c": console.log("Spoluhlaska c"); break;
    case "d": console.log("Spoluhlaska d"); break;
    default: console.log("Nieco ine");
  }
```

- Uloha: nastavte kazdej bunke rozmery 55x55 pixelov (`cell.style.width = "55px"`, `cell.style.height = "55px"`, `cell.style.display = "inline-block"`)

## Mapa hry

- Uloha: Vytvorte s pomocou znakov mriezka a medzera bludisko

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

- Uloha: Vykreslite bludisko, prazdny priestor sivou a steny cervenou
- Uloha: Ulozte do premennych `hracx` a `hracy` suradnicu (x - stlpec, y - riadok) kde ma hrac zacinat

## Pohyb po hracom poli

- Uloha: Vyfarbite policko urcene tymito suradnicami namodro
- Uloha: Doplnte funkciu `pohyb` tak, aby sa hrac presuval po bludisku

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

- Uloha: Osetrite situaciu kedy by sa chcel hrac posunut na miesto kde sa pred tym nachadzala stena (prikaz `if`)
- Checkpoint 1: bludisko so smajlikom

## UTF8 symboly
- Uloha: Hraca vykreslite ako hviezdicku `*` (s nastavenim `innerHTML`)
- Uloha: Hraca vykreslite s pomocou symbolu `"&#x1f600;"`
- Uloha: Vyberte iny symbol na zobrazenie hraca

- Utf8 symboly: 
  - [symbl.cc - emoticons](https://symbl.cc/en/unicode/blocks/emoticons/)
  - [symbl.cc - misc](https://symbl.cc/en/unicode/blocks/miscellaneous-symbols-and-pictographs/)
  - [utf8-icons.com](https://utf8-icons.com/subset/miscellaneous-symbols-and-pictographs)
  - [unicode.org](https://unicode.org/emoji/charts/full-emoji-list.html)

- nastylovanie textu (overflow, fontSize, textAlign, lineHeight)
- pridanie ciela
- pridanie kluca a dveri

- Checkpoint 2: puzzle s cielom

## Tile map
- pridanie tile map (background, backgroundRepeat, backgroundPosition)
- Checkpoint 3: otexturovana mapa

## Sokoban
- pridanie predmetov a posuvanie
- pouzite level:
  - [sokoban/level01.js](sokoban/level01.js)
  - [sokoban/level02.js](sokoban/level02.js)
  - [sokoban/level03.js](sokoban/level03.js)
  - [sokoban/level04.js](sokoban/level04.js)
  - [sokoban/level05.js](sokoban/level05.js)
- Checkpoint 4: sokoban
