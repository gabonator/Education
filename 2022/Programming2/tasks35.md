# Opakovanie pred stvrtym workshopom

## Stack overflow survey

[Stack overflow survey](https://survey.stackoverflow.co/2022/#most-popular-technologies-language)

## Uloha 1 

```javascrpt
for (var i=0; i<10; i++)
{
  for (var j=0; j<10; j++)
  {
    document.write(i, j, "<br>");
  }
}
```

- Co robi tento program?
- Upravte program tak, aby vypisal cisla pre ktore plati, ze sucet cifier je 5
- Upravte program tak, aby vypisal iba pocet cisiel, ktorych sucet cifier bol 5
- Upravte program tak, aby vypisal pocet trojcifernych cisel, ktorych sucet cifier je 10

## Uloha 2

```javascript
var slovo = "slnecnica"
for (var i=0; i<slovo.length; i++)
{
  var z = slovo[i]
  document.write(i, " ", z, "<br>")
}

```

- Co robi tento program?
- Vypiste ku kazdemu pismenu ci je samohlaska alebo spoluhlaska
- Kolko najviac spoluhlasok je v tomto slove za sebou?

## nodejs

```javascript
// zoznam stiahnuty z: https://github.com/flowernal/slovnik-slovenskeho-jazyka
var fs = require("fs")
var slova = fs.readFileSync("slovnik.txt").toString().split("\n")

var najlepsie = 0
var spoluhlasky = ["b", "c", "č", "d", "ď", "f", "g", "h", "j", "k", "l", "ĺ", "ľ", "m", "n", "ň", "p", "q", "r", "s", "š", "t", "ť", "v", "w", "x", "z", "ž"]
for (var i=0; i<slova.length; i++)
{
  var slovo = slova[i].split("/")[0]
  var spoluhlasok = 0
  for (var j=0; j<slovo.length; j++)
  {
    var pismeno = slovo[j]
    if (spoluhlasky.indexOf(pismeno) != -1)
      spoluhlasok++
    else
      spoluhlasok = 0
  }
  if (spoluhlasok > najlepsie)
  {
    console.log(slovo)
    najlepsie = spoluhlasok
  }
}
```
