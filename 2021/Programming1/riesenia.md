# uloha 3
```javascript
strana = 5
obvod = 4*strana
// -------
obsah = strana*strana
// alebo
obsah = Math.pow(strana, 2)
```

# uloha 4

```javascript
true == 1
false == 0
```

*true* ma hodnotu 1, *false* ma hodnotu 0. Podmienka if je pravdiva ak argument nie je nula (akekolvek cislo okrem nuly je pravda).

# uloha 5
- prompt(nadpis, pociatocna hodnota) - okienko na zadanie vstupu 
- alert(text) - okienko upozornenia s textovou informaciou

# uloha 6

```javascript
var i = 1
while (i <= 10)
{
    document.write(i)
    document.write("<br>")
    i = i + 1
}
```

alebo

```javascript
var i = 1
while (i <= 10)
{
    document.write(i + "<br>")
    i = i + 1
}
```

# uloha 7 a

```javascript
var i = 1
while (i <= 10)
{
    var obvod = 4*i
    document.write("Stvorec so stranou " + i + " ma obvod " + obvod + "<br>")
    i = i + 1
}
```

# uloha 7 b

```javascript
var i = 1
while (i <= 10)
{
    var obvod = 4*i
    var obsah = i*i
    document.write("Stvorec so stranou " + i + " ma obvod " + obvod + " a obsah " + obsah + "<br>")
    i = i + 1
}
```

# uloha 8 a

```javascript
var i = 1
while (i <= 10)
{
    var podiel = Math.floor(i / 2)
    var zvysok = i - podiel*2
    var parne = zvysok == 0

    document.write(i + " po deleni dvomi je " + podiel + " a zvysok " + 
      zvysok + ", cislo je parne: " + parne + "<br>")
    i = i + 1
}
```

# uloha 8 b

```javascript
var i = 1
while (i <= 10)
{
    var podiel = Math.floor(i / 3)
    var zvysok = i - podiel*3
    var delitelne = zvysok == 0

    document.write(i + " po deleni tromi je " + podiel + " a zvysok " + 
      zvysok + ", cislo je delitelne tromi: " + delitelne + "<br>")
    i = i + 1
}
```

# uloha 9 a

```html
<img src=red.png><img src=red.png><img src=red.png>
```

# uloha 9 b

```html
<img src=red.png><img src=green.png><img src=blue.png><br>
<img src=red.png><img src=green.png><img src=blue.png><br>
<img src=red.png><img src=green.png><img src=blue.png><br>
```

# uloha 10 a

```javascript
var i = 1
while (i <= 10)
{
    document.write("<img src=red.png>");
    i = i + 1
}
```

# uloha 10 b

```javascript
var i = 1
while (i <= 10)
{
    document.write("<img src=red.png>");
    i = i + 1
}

document.write("<br>");

var i = 1
while (i <= 10)
{
    document.write("<img src=red.png>");
    i = i + 1
}
```

## uloha 11

```javascript
var j = 1
while (j <= 10)
{

    var i = 1
    while (i <= 10)
    {
        document.write("<img src=red.png>");
        i = i + 1
    }

    document.write("<br>");
    j = j + 1
}
```

## uloha 12

```javascript
var y = 1
while (y <= 5)
{

    var x = 1
    while (x <= 5)
    {
        document.write(x + "," + y);
        document.write("<img src=red.png>");
        x = x + 1
    }

    document.write("<br>");
    y = y + 1
}
```

## uloha 13

```javascript
var y = 1
while (y <= 5)
{

    var x = 1
    while (x <= 5)
    {
        document.write(x + "," + y);
        if (x < y)
        {
            document.write("<img src=blue.png>");
        } 
        else 
        {
            document.write("<img src=red.png>");
        }
        x = x + 1
    }

    document.write("<br>");
    y = y + 1
}
```

- modry trojuholnik pod hlavnou diagonalou

## uloha 14

```javascript
var y = 1
while (y <= 5)
{

    var x = 1
    while (x <= 5)
    {
        document.write(x + "," + y);

        if (x == y)
        {
            document.write("<img src=green.png>");
        }
        else 
        if (x < y)
        {
            document.write("<img src=blue.png>");
        } 
        else 
        {
            document.write("<img src=red.png>");
        }
        x = x + 1
    }

    document.write("<br>");
    y = y + 1
}
```

## uloha 15

```javascript
var y = 1
while (y <= 5)
{

    var x = 1
    while (x <= 5)
    {
        document.write(x + "," + y);

        if (y == 1)
        {
            document.write("<img src=blue.png>");
        }
        else 
        if (y == 5)
        {
            document.write("<img src=blue.png>");
        } 
        else 
        {
            document.write("<img src=red.png>");
        }
        x = x + 1
    }

    document.write("<br>");
    y = y + 1
}
```   

## uloha 16

```javascript
var y = 1
while (y <= 5)
{

    var x = 1
    while (x <= 5)
    {
        document.write( (y == 1) + (y == 5) );

        if ((y == 1) + (y == 5) == 1)
        {
            document.write("<img src=blue.png>");
        }
        else 
        {
            document.write("<img src=red.png>");
        }
        x = x + 1
    }

    document.write("<br>");
    y = y + 1
}
```

## uloha 17

```javascript
var y = 1
while (y <= 5)
{

    var x = 1
    while (x <= 5)
    {
        document.write( (y == 1) || (y == 5) );

        if ((y == 1) || (y == 5))
        {
            document.write("<img src=blue.png>");
        }
        else 
        {
            document.write("<img src=red.png>");
        }
        x = x + 1
    }

    document.write("<br>");
    y = y + 1
}
```

## uloha 18 a

```javascript
var y = 1
while (y <= 5)
{

    var x = 1
    while (x <= 5)
    {
        if (x == 1 || x == 5 || y == 1 || y == 5)
        {
            document.write("<img src=blue.png>");
        }
        else 
        {
            document.write("<img src=red.png>");
        }
        x = x + 1
    }

    document.write("<br>");
    y = y + 1
}
```


## uloha 18 b

```javascript
var y = 1
while (y <= 5)
{

    var x = 1
    while (x <= 5)
    {
        if (x > 1 && x < 5 && y > 1 && y < 5)
        {
            document.write("<img src=blue.png>");
        }
        else 
        {
            document.write("<img src=red.png>");
        }
        x = x + 1
    }

    document.write("<br>");
    y = y + 1
}
```

## uloha 19
```javascript
var y = 1
while (y <= 5)
{

    var x = 1
    while (x <= 5)
    {
        document.write(x + ", " + y);
        if (x == 1 || x == 5 || y == 1 || y == 5 || (x == 3 && y == 3))
            document.write("<img src=blue.png>");
        else
            document.write("<img src=red.png>");
        x = x + 1
    }
    document.write("<br>")

    y = y + 1
}
```

## uloha 20

```javascript
var y = 1
while (y <= 5)
{

    var x = 1
    while (x <= 5)
    {
        document.write(x + ", " + y);
        if (x == 6-y)
            document.write("<img src=blue.png>");
        else
            document.write("<img src=red.png>");
        x = x + 1
    }
    document.write("<br>")

    y = y + 1
}
```

## uloha 21 a
```javascript
var y = 1
while (y <= 8)
{
    var x = 1
    while (x <= 8)
    {
        document.write(x + y);            
        if (x%2 == 0)
            document.write("<img src=blue.png>");
        else 
            document.write("<img src=red.png>");
        x = x + 1
    }
    document.write("<br>")
    y = y + 1
}
```

### uloha 21 b

```javascript
var y = 1
while (y <= 8)
{
    var x = 1
    while (x <= 8)
    {
        document.write(x + y);            
        if ((x+y)%2 == 0)
            document.write("<img src=blue.png>");
        else 
            document.write("<img src=red.png>");
        x = x + 1
    }
    document.write("<br>")
    y = y + 1
}
```

### uloha 21 c
```javascript
var y = 1
while (y <= 8)
{
    var x = 1
    while (x <= 8)
    {
        document.write(x);            
        if (Math.floor(x/2)%2 == 0)
            document.write("<img src=blue.png>");
        else 
            document.write("<img src=red.png>");
        x = x + 1
    }
    document.write("<br>")
    y = y + 1
}
```

### uloha 21 d
```javascript
var y = 0
while (y <= 7)
{
    var x = 0
    while (x <= 7)
    {
        document.write(x);            
        if ((Math.floor(x/2) + Math.floor(y/2))%2 == 0)
            document.write("<img src=blue.png>");
        else 
            document.write("<img src=red.png>");
        x = x + 1
    }
    document.write("<br>")
    y = y + 1
}
```

## uloha 22 a
```javascript
var y = -6
while (y <= 6)
{
    var x = -6
    while (x <= 6)
    {
        if (Math.abs(x) < 3)
            document.write("<img src=blue.png>");
        else 
            document.write("<img src=red.png>");
        x = x + 1
    }
    document.write("<br>")
    y = y + 1
}
```

## uloha 22 b

```javascript
var y = -6
while (y <= 6)
{
    var x = -6
    while (x <= 6)
    {
        if (Math.abs(x) < Math.abs(y))
            document.write("<img src=blue.png>");
        else 
            document.write("<img src=red.png>");
        x = x + 1
    }
    document.write("<br>")
    y = y + 1
}
```

## uloha 23 a

```javascript
var y = -6
while (y <= 6)
{
    var x = -6
    while (x <= 6)
    {
        if (x*x + y*y == 5*5)
            document.write("<img src=blue.png>");
        else 
            document.write("<img src=red.png>");
        x = x + 1
    }
    document.write("<br>")
    y = y + 1
}
```

### uloha 23 b

```
var y = -6
while (y <= 6)
{
    var x = -6
    while (x <= 6)
    {
        if (x * x + y * y < 5 * 5)
            document.write("<img src=blue.png>");
        else 
            document.write("<img src=red.png>");
        x = x + 1
    }
    document.write("<br>")
    y = y + 1
}
```

### uloha 23 c

```javascript
var y = -6
while (y <= 6)
{
    var x = -6
    while (x <= 6)
    {
        if (Math.abs(x * x + y * y - 5*5) < 5)
            document.write("<img src=blue.png>");
        else 
            document.write("<img src=red.png>");
        x = x + 1
    }
    document.write("<br>")
    y = y + 1
}

```

- skuste pre hodnoty 5, 10, 20

## uloha 24

```javascript
function vykresli(stlpcov, riadkov, farba)
{
    var y = 1
    while (y <= riadkov)
    {
        var x = 1
        while (x <= stlpcov)
        {
            document.write("<img src="+farba+".png>");
            x = x + 1
        }
        document.write("<br>")
        y = y + 1
    }
}

vykresli(3, 2, "red")
vykresli(5, 3, "green")
vykresli(2, 2, "blue")
```

## uloha 25 a

```javascript
function naFarenheity(stupne)
{
  return stupne * 1.8 + 32
}

for (var teplota = 0; teplota < 100; teplota = teplota + 10) 
{
  document.write("Teplota " + teplota + " &deg; C = " + naFarenheity(teplota) + "&deg;F<br>")
}
```

## uloha 25 b

```javascript
function naFarenheity(stupne)
{
  return stupne * 1.8 + 32
}

for (var teplota = -20; teplota <= 100; teplota = teplota + 5) 
{
  document.write("Teplota " + teplota + " &deg; C = " + naFarenheity(teplota) + "&deg;F<br>")
}
```

## uloha 27 a
```javascript
for (var a=0; a<=9; a=a+1)
{
  for (var b=0; b<=9; b=b+1)
  {
    for (var c=0; c<=9; c=c+1)
    {
      if (a+b+c == 5)
        document.write("a="+a+" b="+b+" c="+c+"<br>")
    }
  }
}

```

## uloha 27 b

```javascript
var pocet = 0;
for (var a=0; a<=9; a=a+1)
{
  for (var b=0; b<=9; b=b+1)
  {
    for (var c=0; c<=9; c=c+1)
    {
      if (a+b+c == 5)
      {
          pocet = pocet + 1
      }
    }
  }
}
document.write("Pocet je " + pocet)
```

## uloha 28
```javascript
function pocetnost(sucet)
{
    var pocet = 0;
    for (var a=0; a<=9; a=a+1)
    {
      for (var b=0; b<=9; b=b+1)
      {
        for (var c=0; c<=9; c=c+1)
        {
          if (a+b+c == sucet)
          {
              pocet = pocet + 1
          }
        }
      }
    }
    return pocet
}

for (var i=0; i<=27; i=i+1)
  document.write("sucet " + i + " pocetnost " + pocetnost(i) + "<br>")
```

## uloha 29

```html
<script src="https://code.highcharts.com/highcharts.js"></script><div id="container"></div>

<script src="test.js">
</script>
```

```javascript
function pocetnost(sucet)
{
    var pocet = 0;
    for (var a=0; a<=9; a=a+1)
    {
      for (var b=0; b<=9; b=b+1)
      {
        for (var c=0; c<=9; c=c+1)
        {
          if (a+b+c == sucet)
          {
              pocet = pocet + 1
          }
        }
      }
    }
    return pocet
}

pole = []
for (var i=0; i<=27; i=i+1)
  pole.push(pocetnost(i))

Highcharts.chart("container", {
    chart: {
        type: "bar"
    },
    series: [{
        data: pole
    }]
});
```
## uloha 30 a

```
<script language="javascript">
var ctx = canvas.getContext('2d');
var imdata = ctx.createImageData(canvas.width, canvas.height);
var width = canvas.width
var height = canvas.height
var i = 0

for (var y=0; y<width; y++)
{
  for (var x=0; x<height; x++)
  {
    var vzdialenost = Math.sqrt(Math.pow(x-width/2, 2) + Math.pow(y-height/2, 2))
    if (vzdialenost % 20 < 10)
    {
      imdata.data[i++] = 0;    // cervena
      imdata.data[i++] = 255;  // zelena
      imdata.data[i++] = 0;    // modra
      imdata.data[i++] = 255;  // alpha
    } else
    {
      imdata.data[i++] = 255;  // cervena
      imdata.data[i++] = 0;    // zelena
      imdata.data[i++] = 0;    // modra
      imdata.data[i++] = 255;  // alpha
    }
  }
}
ctx.putImageData(imdata, 0, 0);
</script>
```

## uloha 30 b

```javascript
var posun = 0

function kresli()
{
  var ctx = canvas.getContext('2d')
  var imdata = ctx.createImageData(canvas.width, canvas.height)
  var width = canvas.width
  var height = canvas.height
  var i = 0

  posun = posun + 1

  for (var y=0; y<width; y++)
  {
    for (var x=0; x<height; x++)
    {
      var vzdialenost = Math.sqrt(Math.pow(x-width/2, 2) + Math.pow(y-height/2, 2)) + posun
      if (vzdialenost % 20 < 10)
      {
        imdata.data[i++] = 0    // cervena
        imdata.data[i++] = 255  // zelena
        imdata.data[i++] = 0    // modra
        imdata.data[i++] = 255  // alpha
      } else
      {
        imdata.data[i++] = 255  // cervena
        imdata.data[i++] = 0    // zelena
        imdata.data[i++] = 0    // modra
        imdata.data[i++] = 255  // alpha
      }
    }
  }
  ctx.putImageData(imdata, 0, 0)
}

setInterval(kresli, 20)
```

## uloha 31

```javascript
for (var a=0; a<360; a+=30)
{
  var adeg = (a+90)/180*Math.PI
  var x = Math.cos(adeg)*300+300;
  var y = Math.sin(adeg)*300+300;
  document.write("<img src=cat.png style='position:absolute; left:"+x+"px; top:"+y+"px;'>");
}
```

## uloha 32
```javascript
  for (var i=0; i<10; i++)
  {
    document.write("<img id=macka"+i+" src=cat.png style='position:absolute;'>");    
  }

  var tick = 0;
  setInterval( ()=>
  {
    tick+=.1;
    for (var i=0; i<10; i++)
    {
      var macka = document.getElementById("macka"+i);
      var a = i*360/10+tick*5;
      var adeg = (a+tick)/180*Math.PI

      var x = Math.cos(adeg)*220+300;
      var y = Math.sin(adeg)*220+300;

      macka.style.left = x;
      macka.style.top = y;
      macka.style.transform = "rotate("+(a+180)+"deg)"
    }

  }, 10);
```
