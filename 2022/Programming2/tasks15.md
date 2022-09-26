# Opakovanie pred druhym workshopom

## Chrome 

- ukazat ako schovat element

## program 1 - ovocie

```javascript
ovocie = ["banany", "jablka", "hrusky", "pomarance", "kiwi"]

for (var i=0; i<5; i=i+1)
{
  document.write(ovocie[i])
  document.write(", ")
}
document.write("<br>")
```

- Upravte program tak, aby vypisal ovocie v opacnom poradi
- Otazka: co vrati vyraz "ovocie.length" v console? Ako ho zapracovat do predosleho programu?
- vyskusat v konzole: `ovocie.reverse()`, `ovocie.sort()`, `ovocie.indexOf("hrusky")`

## program 2 - push

```javascript
var pole = [];

for (var i=0; i<10; i++)
  pole.push(i*10)

document.write(pole)
```

## program 2 - vnoreny for

```javascript
ludia = ["tomas", "oliver", "ludo", "laco"]

for (var i=0; i<ludia.length; i++)
{
  for (var j=0; j<ludia.length; j++)
  {
    // co tuto dopiseme?
  }
}

```

- Uloha: Vytvorte pary vsetkych ludi v skupine:

```
peter - peter
peter - adam
peter - igor
peter - ondrej
adam - peter
adam - adam
adam - igor
adam - ondrej
igor - peter
igor - adam
igor - igor
igor - ondrej
ondrej - peter
ondrej - adam
ondrej - igor
ondrej - ondrej
```

## program 3 - pomienka if
- Zo vsetkych parov vyhodte tie, ktore nedavaju zmysel (`peter - peter`, `adam - adam`, ...)

## program 4 - sachova partia
- Vytvorte neopakujuce sa pary

```javascript
peter - adam
peter - igor
peter - ondrej
adam - igor
adam - ondrej
igor - ondrej
```

## program 5 - swap

```javascript
var a = 7
var b = 3

// tuto dopln

document.write("a = " + a + "<br>")
document.write("b = " + b + "<br>")
```

- Co urobi tento program?
- Dopln program tak, aby prehodil hodnoty `a` a `b`


## program 6 - bubble sort

- Znazornit algorimtus

```
var pole = [5, 9, 7, 2, 6]

// zorad
for (var i=0; i<pole.length; i++)
  for (var j=i+1; j<pole.length; j++)
  {
    // dopln kod
  }

// vypis
document.write(pole);
```

- Doplnte kod tak, aby vypisal zoradene pole

## program 7 - pseudo random number generator

```javascript
var seed = 12347

function prng()
{
    seed = 8253729 * seed + 2396403;
    return seed % 1000;
}
```

- Co robi funkcia `prng()` ? Vyskusajte v konzole
- Co vrati nasledujuci vyraz v konzole? `new Date().getTime()`
- Co vrati nasledujuci vyraz v konzole? `new Date("1/1/1970 01:00").getTime()`
- [PS3 hacked](https://www.engadget.com/2010-12-29-hackers-obtain-ps3-private-cryptography-key-due-to-epic-programm.html)