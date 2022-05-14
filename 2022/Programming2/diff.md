# Diff
## Diff 01 vs 00

```diff
12,13d11
< var vx = 0;
< var vy = 0;
22,23d19
<     x = x + vx;
<     y = y + vy;
```

## Diff 02 vs 01

```diff
14d13
< var radius = 20;
25,35d23
< 
<     if (x < 20)
<       vx = Math.abs(vx);
<     if (x > width-20)
<       vx = -Math.abs(vx);
< 
<     if (y < 20)
<       vy = Math.abs(vy);
<     if (y > height-20)
<       vy = -Math.abs(vy);
< 
```

## Diff 03 vs 02

```diff
12,15c12,13
< var vx = 5;
< var vy = -2;
< var ax = 0;
< var ay = 0.1;
---
> var vx = 0;
> var vy = 0;
25,28d22
<     vx = vx + ax;
<     vy = vy + ay;
<     vx = vx * 0.99;
<     vy = vy * 0.99;
40d33
<     {
42,45d34
<       y = height-20;
<       vy *= 0.8;
<       vx *= 0.8;
<     }
```

## Diff 04 vs 03

```diff
10,15c10,15
< var x = []; //width/2;
< var y = []; //height/2;
< var vx = []; //5;
< var vy = []; //-2;
< var ax = []; //0;
< var ay = []; //0.1;
---
> var x = width/2;
> var y = height/2;
> var vx = 5;
> var vy = -2;
> var ax = 0;
> var ay = 0.1;
17,18c17,18
< var balls = []; 
< /*document.createElement("img");
---
> 
> var ball = document.createElement("img");
21,38c21
< document.querySelector("#game").appendChild(ball);
< */
< 
< for (var i=0; i<10; i++)
< {
<   var b = document.createElement("img");
<   b.src = "red.png";
<   b.setAttribute("style", "position:absolute");
<   element.appendChild(b);
<   balls.push(b);
< 
<   x.push(Math.random()*width);
<   y.push(Math.random()*height);
<   vx.push(Math.random()*5-2.5);
<   vy.push(Math.random()*5-2.5);
<   ax.push(0);
<   ay.push(0);
< }
---
> element.appendChild(ball);
42,58c25,39
<   for (var i=0; i<balls.length; i++)
<   {
<     vx[i] = vx[i] + ax[i];
<     vy[i] = vy[i] + ay[i];
< //    vx[i] = vx[i] * 0.99;
< //    vy[i] = vy[i] * 0.99;
<     x[i] = x[i] + vx[i];
<     y[i] = y[i] + vy[i];
< 
<     if (x[i] < 20)
<       vx[i] = Math.abs(vx[i]);
<     if (x[i] > width-20)
<       vx[i] = -Math.abs(vx[i]);
< 
<     if (y[i] < 20)
<       vy[i] = Math.abs(vy[i]);
<     if (y[i] > height-20)
---
>     vx = vx + ax;
>     vy = vy + ay;
>     vx = vx * 0.99;
>     vy = vy * 0.99;
>     x = x + vx;
>     y = y + vy;
> 
>     if (x < 20)
>       vx = Math.abs(vx);
>     if (x > width-20)
>       vx = -Math.abs(vx);
> 
>     if (y < 20)
>       vy = Math.abs(vy);
>     if (y > height-20)
60,63c41,44
<       vy[i] = -Math.abs(vy[i]);
<       y[i] = height-20;
<       vy[i] *= 0.8;
<       vx[i] *= 0.8;
---
>       vy = -Math.abs(vy);
>       y = height-20;
>       vy *= 0.8;
>       vx *= 0.8;
66,68c47,48
<     balls[i].style.left = x[i]-20;
<     balls[i].style.top = y[i]-20;
<   }
---
>     ball.style.left = x-20;
>     ball.style.top = y-20;
```

## Diff 05 vs 04

```diff
24c24
< for (var i=0; i<100; i++)
---
> for (var i=0; i<10; i++)
29c29
<   document.querySelector("#game").appendChild(b);
---
>   element.appendChild(b);
44,65d43
<     ax[i] = 0;
<     ay[i] = 0.05;
<   
<     for (var j=0; j<balls.length; j++)
<       if (i!=j)
<       {
<         var ux = x[j] - x[i];
<         var uy = y[j] - y[i];
<         var angleRad = Math.atan2(uy, ux);
<         var dist = Math.sqrt(ux**2+uy**2);
<         if (dist < 20)
<         {
<           dist = 21-dist;
<           ax[i] -= Math.cos(angleRad)*(dist/50); 
<           ay[i] -= Math.sin(angleRad)*(dist/50); 
<         } else {
<           ax[i] += Math.cos(angleRad)*(dist/10000)**2; 
<           ay[i] += Math.sin(angleRad)*(dist/10000)**2; 
<         }
< 
<       }
< 
68,69c46,47
<     vx[i] = vx[i] * 0.99;
<     vy[i] = vy[i] * 0.99;
---
> //    vx[i] = vx[i] * 0.99;
> //    vy[i] = vy[i] * 0.99;
```

## Diff 06 vs 05

```diff
24c24
< for (var i=0; i<10; i++)
---
> for (var i=0; i<100; i++)
27c27
<   b.src = ["red.png", "green.png", "blue.png"][Math.floor(Math.random()*3)];
---
>   b.src = "red.png";
43,49c43,48
<   {  
<     for (var j=i+1; j<balls.length; j++)
<     {
<       var ux = x[i] - x[j];
<       var uy = y[i] - y[j];
<       var dist = Math.sqrt(ux**2+uy**2);
<       if (dist<40)
---
>   {
>     ax[i] = 0;
>     ay[i] = 0.05;
>   
>     for (var j=0; j<balls.length; j++)
>       if (i!=j)
51,65c50,54
<         var mtd = 40-dist;
<         var mtdx = ux/dist*mtd;
<         var mtdy = uy/dist*mtd;
<         var mtdl = Math.sqrt(mtdx**2+mtdy**2);
<         x[i] += mtdx/2;
<         y[i] += mtdy/2;
<         x[j] -= mtdx/2;
<         y[j] -= mtdy/2;
< 
<         mtdx /= mtdl;
<         mtdy /= mtdl;
<         var velx = vx[i] - vx[j];
<         var vely = vy[i] - vy[j];
<         var vn = velx*mtdx+vely*mtdy;
<         if (vn < 0)
---
>         var ux = x[j] - x[i];
>         var uy = y[j] - y[i];
>         var angleRad = Math.atan2(uy, ux);
>         var dist = Math.sqrt(ux**2+uy**2);
>         if (dist < 20)
67,74c56,61
<           var rest = 1;
<           var im = -(-(1+rest)*vn) / 2;
<           var impx = mtdx*im;
<           var impy = mtdy*im;
<           vx[i] -= impx;
<           vy[i] -= impy;
<           vx[j] += impx;
<           vy[j] += impy;
---
>           dist = 21-dist;
>           ax[i] -= Math.cos(angleRad)*(dist/50); 
>           ay[i] -= Math.sin(angleRad)*(dist/50); 
>         } else {
>           ax[i] += Math.cos(angleRad)*(dist/10000)**2; 
>           ay[i] += Math.sin(angleRad)*(dist/10000)**2; 
75a63
> 
77d64
<     }
80a68,69
>     vx[i] = vx[i] * 0.99;
>     vy[i] = vy[i] * 0.99;
```

## Diff 07 vs 06

```diff
10,47c10,16
< class Ball
< {
<   constructor(width, height)
<   {
<     this.width = width;
<     this.height = height;
<     this.element = document.createElement("img");
<     this.element.src = ["red.png", "green.png", "blue.png"][Math.floor(Math.random()*3)];
<     this.element.setAttribute("style", "position:absolute");
<     document.querySelector("#game").appendChild(this.element);
<     this.x = Math.random()*width;
<     this.y = Math.random()*height;
<     this.vx = Math.random()*5-2.5;
<     this.vy = Math.random()*5-2.5;
<     this.ax = 0;
<     this.ay = 0;
<   }
<   update()
<   {
<     this.vx = this.vx + this.ax;
<     this.vy = this.vy + this.ay;
<     this.x = this.x + this.vx;
<     this.y = this.y + this.vy;
< 
<     if (this.x < 20)
<       this.vx = Math.abs(this.vx);
<     if (this.x > this.width-20)
<       this.vx = -Math.abs(this.vx);
<     if (this.y < 20)
<       this.vy = Math.abs(this.vy);
<     if (this.y > this.height-20)
<       this.vy = -Math.abs(this.vy);
< 
<     this.element.style.left = this.x-20;
<     this.element.style.top = this.y-20;
<   }
< }
< 
---
> var x = []; //width/2;
> var y = []; //height/2;
> var vx = []; //5;
> var vy = []; //-2;
> var ax = []; //0;
> var ay = []; //0.1;
> var radius = 20;
48a18,22
> /*document.createElement("img");
> ball.src = "red.png";
> ball.setAttribute("style", "position:absolute");
> document.querySelector("#game").appendChild(ball);
> */
51c25,38
<   balls.push(new Ball(width, height))
---
> {
>   var b = document.createElement("img");
>   b.src = ["red.png", "green.png", "blue.png"][Math.floor(Math.random()*3)];
>   b.setAttribute("style", "position:absolute");
>   document.querySelector("#game").appendChild(b);
>   balls.push(b);
> 
>   x.push(Math.random()*width);
>   y.push(Math.random()*height);
>   vx.push(Math.random()*5-2.5);
>   vy.push(Math.random()*5-2.5);
>   ax.push(0);
>   ay.push(0);
> }
56c43,101
<     balls[i].update();
---
>   {  
>     for (var j=i+1; j<balls.length; j++)
>     {
>       var ux = x[i] - x[j];
>       var uy = y[i] - y[j];
>       var dist = Math.sqrt(ux**2+uy**2);
>       if (dist<40)
>       {
>         var mtd = 40-dist;
>         var mtdx = ux/dist*mtd;
>         var mtdy = uy/dist*mtd;
>         var mtdl = Math.sqrt(mtdx**2+mtdy**2);
>         x[i] += mtdx/2;
>         y[i] += mtdy/2;
>         x[j] -= mtdx/2;
>         y[j] -= mtdy/2;
> 
>         mtdx /= mtdl;
>         mtdy /= mtdl;
>         var velx = vx[i] - vx[j];
>         var vely = vy[i] - vy[j];
>         var vn = velx*mtdx+vely*mtdy;
>         if (vn < 0)
>         {
>           var rest = 1;
>           var im = -(-(1+rest)*vn) / 2;
>           var impx = mtdx*im;
>           var impy = mtdy*im;
>           vx[i] -= impx;
>           vy[i] -= impy;
>           vx[j] += impx;
>           vy[j] += impy;
>         }
>       }
>     }
> 
>     vx[i] = vx[i] + ax[i];
>     vy[i] = vy[i] + ay[i];
>     x[i] = x[i] + vx[i];
>     y[i] = y[i] + vy[i];
> 
>     if (x[i] < 20)
>       vx[i] = Math.abs(vx[i]);
>     if (x[i] > width-20)
>       vx[i] = -Math.abs(vx[i]);
> 
>     if (y[i] < 20)
>       vy[i] = Math.abs(vy[i]);
>     if (y[i] > height-20)
>     {
>       vy[i] = -Math.abs(vy[i]);
>       y[i] = height-20;
>       vy[i] *= 0.8;
>       vx[i] *= 0.8;
>     }
> 
>     balls[i].style.left = x[i]-20;
>     balls[i].style.top = y[i]-20;
>   }
```

## Diff 08 vs 07

```diff
20,23c20,23
<     this.x = 0;
<     this.y = 0;
<     this.vx = 0;
<     this.vy = 0;
---
>     this.x = Math.random()*width;
>     this.y = Math.random()*height;
>     this.vx = Math.random()*5-2.5;
>     this.vy = Math.random()*5-2.5;
27,31d26
<   setPosition(x, y)
<   {
<     this.x = x;
<     this.y = y;
<   }
55,64c50,51
< for (var y=0; y<18; y++)
<   for (var x=0; x<11-(y%2); x++)
<   {
<     var b = new Ball(width, height);
<     if (y%2==0)
<       b.setPosition(x*36+20, 20+y*32);
<     else
<       b.setPosition(x*36+20+18, 20+y*32);
<     balls.push(b)
<   }
---
> for (var i=0; i<10; i++)
>   balls.push(new Ball(width, height))
```

## Diff 09 vs 08

```diff
32,50d31
<   setAngle(angleDeg)
<   {
<     var angleRad = angleDeg/180*Math.PI;
<     this.vx = Math.cos(angleRad);
<     this.vy = -Math.sin(angleRad);
<   }
<   setSpeed(s)
<   {
<     this.vx *= s;
<     this.vy *= s;
<   }
<   hide()
<   {
<     this.element.style.visibility = "hidden";
<   }
<   show()
<   {
<     this.element.style.visibility = "visible";
<   }
82d62
<     b.hide();
86,90d65
< var fire = new Ball(width, height);
< fire.setPosition(width/2, height-50);
< fire.setAngle(45);
< fire.setSpeed(5);
< balls.push(fire);
```

## Diff 10 vs 09

```diff
43,46d42
<   isFire()
<   {
<     return this.vx != 0 || this.vy != 0;
<   }
55,87c51
<   isHidden()
<   {
<     return this.element.style.visibility == "hidden";
<   }
<   distance(b)
<   {
<     return Math.sqrt((this.x-b.x)**2 + (this.y-b.y)**2);
<   }
<   getColor(c)
<   {
<     return this.element.src;
<   }
<   setColor(c)
<   {
<     this.element.src = c;
<   }
<   hit(balls)
<   {
<     var besti = -1;
<     for (var i=0; i<balls.length; i++)
<       if (balls[i].isHidden())
<       {
<         if (besti == -1 || 
<             this.distance(balls[i]) < this.distance(balls[besti]))
<           besti = i;
<       }
<     if (besti != -1)
<     {
<       balls[besti].show();
<       balls[besti].setColor(this.getColor());
<     }
<   }
<   update(balls)
---
>   update()
99d62
<     {
101,105d63
<       if (this.isFire())
<       {
<         this.hit(balls);
<       }
<     }
136c94
<     balls[i].update(balls);
---
>     balls[i].update();
```

## Diff 11 vs 10

```diff
59,62d58
<   isVisible()
<   {
<     return !this.isHidden();
<   }
75,78d70
<   randomColor()
<   {
<     this.element.src = ["red.png", "green.png", "blue.png"][Math.floor(Math.random()*3)];
<   }
97,111d88
<     if (this.isFire())
<     {
<       for (var i=0; i<balls.length; i++)
<         if (!balls[i].isFire() && 
<             balls[i].isVisible() &&
<             this.distance(balls[i]) < 40)
<         {
<           this.hit(balls);
<           this.setPosition(this.width/2, this.height-40);
<           this.setAngle(20+Math.random()*140);
<           this.setSpeed(5);
<           this.randomColor();
<           break;
<         }
<     }
127,130d103
<         this.setPosition(this.width/2, this.height-40);
<         this.setAngle(20+Math.random()*140);
<         this.setSpeed(5);
<         this.randomColor();
```

## Diff 12 vs 11

```diff
79,91d78
<   nearbyBalls(balls)
<   {
<     var aux = [];
<     for (var i=0; i<balls.length; i++)
<       if (balls[i].isVisible() && !balls[i].isFire() && 
<           balls[i].element != this.element && 
<           balls[i].distance(this) < 40)
<       {
<         aux.push(balls[i]);
<       }
<     return aux;
<   }
< 
102,111c89
< 
<     if (besti == -1)
<       return;
< 
<     balls[besti].show();
<     balls[besti].setColor(this.getColor());
< 
<     var process = [balls[besti]];
<     var matching = [];
<     while (process.length > 0)
---
>     if (besti != -1)
113,121c91,92
<       var b = process.shift();
<       matching.push(b);
<       var nearby = b.nearbyBalls(balls);
<       for (var i=0; i<nearby.length; i++)
<         if (nearby[i].getColor() == this.getColor())
<         {
<           if (matching.indexOf(nearby[i]) == -1)
<             process.push(nearby[i]);
<         }
---
>       balls[besti].show();
>       balls[besti].setColor(this.getColor());
123d93
<     console.log(matching.length);
125d94
< 
```

## Diff 13 vs 12

```diff
91,102d90
<   topBalls(balls)
<   {
<     var aux = [];
<     for (var i=0; i<balls.length; i++)
<       if (balls[i].isVisible() && !balls[i].isFire() && 
<           balls[i].element != this.element && 
<           balls[i].y < 30)
<       {
<         aux.push(balls[i]);
<       }
<     return aux;
<   }
135,160c123
< 
<     if (matching.length >= 3)
<     {
<       for (var i=0; i<matching.length; i++)
<         matching[i].hide();
< 
<       var process = this.topBalls(balls);
<       var hanging = [];
<       while (process.length > 0)
<       {
<         var b = process.shift();
<         hanging.push(b);
<         var nearby = b.nearbyBalls(balls);
<         for (var i=0; i<nearby.length; i++)
<         {
<           if (hanging.indexOf(nearby[i]) == -1)
<             process.push(nearby[i]);
<         }
<       }
< 
<       for (var i=0; i<balls.length; i++)
<       {
<         if (hanging.indexOf(balls[i]) == -1 && !balls[i].isFire())
<           balls[i].hide();
<       }
<     }
---
>     console.log(matching.length);
```

## Diff 14 vs 13

```diff
47,50d46
<   isFalling()
<   {
<     return this.ay != 0;
<   }
87c83
<       if (balls[i].isVisible() && !balls[i].isFire() && !balls[i].isFalling() &&
---
>       if (balls[i].isVisible() && !balls[i].isFire() && 
99c95
<       if (balls[i].isVisible() && !balls[i].isFire() && !balls[i].isFalling() &&
---
>       if (balls[i].isVisible() && !balls[i].isFire() && 
161,163c157,158
<         if (balls[i].isVisible() && 
<             hanging.indexOf(balls[i]) == -1 && !balls[i].isFire())
<           matching.push(balls[i]);
---
>         if (hanging.indexOf(balls[i]) == -1 && !balls[i].isFire())
>           balls[i].hide();
165,179d159
< 
<       this.explode(balls, matching);
<     }
<   }
< 
<   explode(balls, expl)
<   {
<     for (var i=0; i<expl.length; i++)
<     {
<       expl[i].hide();
<       var b = new Ball(this.width, this.height);
<       b.setColor(expl[i].getColor());
<       b.setPosition(expl[i].x, expl[i].y);
<       b.ay = 0.1;
<       balls.push(b);
185c165
<     if (this.isFire() && !this.isFalling())
---
>     if (this.isFire())
212c192
<       if (!this.isFalling() && this.isFire())
---
>       if (this.isFire())
222,227d201
<     {
<       if (this.isFalling())
<       {
<         this.destroy();
<         return;
<       }
229d202
<     }
234,238d206
<   destroy()
<   {
<     document.querySelector("#game").removeChild(this.element);
<     delete this.element;
<   }
262d229
<   balls = balls.filter(b => b.element);
```

## Diff 15 vs 14

```diff
```

## Diff 16 vs 15

```diff
172d171
<     var sumx = 0, sumy = 0;
175,186d173
<       sumx += expl[i].x;
<       sumy += expl[i].y;
<     }
<     sumx /= expl.length;
<     sumy /= expl.length;
< 
<     for (var i=0; i<expl.length; i++)
<     {
<       var vectx = expl[i].x - sumx;
<       var vecty = expl[i].y - sumy;
<       var angle = Math.atan2(vecty, vectx) / Math.PI * 180;
< 
191d177
<       b.setAngle(angle);
```

## Diff 17 vs 16

```diff
4c4
< <script src="controls.js"></script>
---
> 
265,269c265
< 
<     if (y<5)
<       b.show();
<     else
<       b.hide();
---
>     b.hide();
278d273
< 
285,309d279
< 
< 
< class Handler
< {
<   onKeyLeft(b) 
<   { 
<     console.log("left", b); 
<   }
<   onKeyRight(b)
<   { 
<     console.log("right", b); 
<   }
<   onKeyFire(b)
<   { 
<     console.log("fire", b); 
<   }
<   onMouse(pt) 
<   {
<     console.log("mouse", pt);
<   }
< }
< 
< var handler = new Handler();
< new Controls(document.querySelector("#game"), handler);
< 
```

## Diff 18 vs 17

```diff
5a6,9
> var element = document.querySelector("#game");
> var width = parseInt(this.element.style.width);
> var height = parseInt(this.element.style.height);
> 
251,258c255
< class Game
< {
<   constructor()
<   {
<     this.balls = [];
<     var element = document.querySelector("#game");
<     this.width = parseInt(element.style.width);
<     this.height = parseInt(element.style.height);
---
> var balls = []; 
260,280c257,277
<     for (var y=0; y<18; y++)
<       for (var x=0; x<11-(y%2); x++)
<       {
<         var b = new Ball(this.width, this.height);
<         if (y%2==0)
<           b.setPosition(x*36+20, 20+y*32);
<         else
<           b.setPosition(x*36+20+18, 20+y*32);
< 
<         if (y<5)
<           b.show();
<         else
<           b.hide();
<         this.balls.push(b)
<       }
< 
<     var fire = new Ball(this.width, this.height);
<     fire.setPosition(this.width/2, this.height-50);
<     fire.setAngle(45);
<     fire.setSpeed(5);
<     this.balls.push(fire);
---
> for (var y=0; y<18; y++)
>   for (var x=0; x<11-(y%2); x++)
>   {
>     var b = new Ball(width, height);
>     if (y%2==0)
>       b.setPosition(x*36+20, 20+y*32);
>     else
>       b.setPosition(x*36+20+18, 20+y*32);
> 
>     if (y<5)
>       b.show();
>     else
>       b.hide();
>     balls.push(b)
>   }
> 
> var fire = new Ball(width, height);
> fire.setPosition(width/2, height-50);
> fire.setAngle(45);
> fire.setSpeed(5);
> balls.push(fire);
282,286c279,284
<     setInterval(() => 
<     {
<       this.update()
<     }, 10);
<   }
---
> setInterval(() => 
> {
>   balls = balls.filter(b => b.element);
>   for (var i=0; i<balls.length; i++)
>     balls[i].update(balls);
> }, 10);
288,293d285
<   update()
<   {
<     this.balls = this.balls.filter(b => b.element);
<     for (var i=0; i<this.balls.length; i++)
<       this.balls[i].update(this.balls);
<   }
294a287,288
> class Handler
> {
313,314c307,308
< var game = new Game();
< new Controls(document.querySelector("#game"), game);
---
> var handler = new Handler();
> new Controls(document.querySelector("#game"), handler);
```

## Diff 19 vs 18

```diff
276,282c276,280
<     this.fire = new Ball(this.width, this.height);
<     this.fire.setPosition(this.width/2, this.height-50);
<     this.balls.push(this.fire);
< 
<     this.cannon = new Ball(this.width, this.height);
<     this.cannon.setPosition(this.width/2, this.height-50);
<     this.cannon.show();
---
>     var fire = new Ball(this.width, this.height);
>     fire.setPosition(this.width/2, this.height-50);
>     fire.setAngle(45);
>     fire.setSpeed(5);
>     this.balls.push(fire);
295d292
<     this.cannon.update();
309,313d305
<     if (b)
<     {
<       this.fire.setAngle(45);
<       this.fire.setSpeed(5);
<     }
```

## Diff 20 vs 19

```diff
54,55d53
<     this.element.style.left = this.x-20;
<     this.element.style.top = this.y-20;
85c83
<       if (balls[i].element && balls[i].isVisible() && !balls[i].isFire() && !balls[i].isFalling() &&
---
>       if (balls[i].isVisible() && !balls[i].isFire() && !balls[i].isFalling() &&
97c95
<       if (balls[i].element && balls[i].isVisible() && !balls[i].isFire() && !balls[i].isFalling() &&
---
>       if (balls[i].isVisible() && !balls[i].isFire() && !balls[i].isFalling() &&
110c108
<       if (balls[i].element && balls[i].isHidden())
---
>       if (balls[i].isHidden())
159c157
<         if (balls[i].element && balls[i].isVisible() && 
---
>         if (balls[i].isVisible() && 
200c198
<         if (balls[i].element && !balls[i].isFire() && 
---
>         if (!balls[i].isFire() && 
205d202
< /*
210,212c207
< */
<           this.destroy();
<           return;
---
>           break;
230,232d224
<         this.destroy();
<         return;
< /*
237d228
< */
284a276,279
>     this.fire = new Ball(this.width, this.height);
>     this.fire.setPosition(this.width/2, this.height-50);
>     this.balls.push(this.fire);
> 
316,317d310
<       this.fire = new Ball(this.width, this.height);
<       this.fire.setPosition(this.width/2, this.height-50);
320,321d312
<       this.fire.show();
<       this.balls.push(this.fire);
```

## Diff 21 vs 20

```diff
289,299d288
<     this.angle = 90;
<     this.arrow = document.createElement("img");
<     this.arrow.setAttribute("src", "arrow.png");
<     this.arrow.setAttribute("style", "position:absolute");
<     this.arrow.style.left = this.width/2;
<     this.arrow.style.top = this.height-50;
<     document.querySelector("#game").appendChild(this.arrow);
<     this.updateArrow();
<     // zacat: "rotate(45deg)"
<     //translate(-23px, -20px) rotate(315deg) translate(22px, 0px)
< 
305,308c294
<   updateArrow()
<   {
<     this.arrow.style.transform = "translate(-24px, -20px) rotate(-"+this.angle+"deg) translate(20px, 0px)"
<   }
---
> 
```

## Diff 22 vs 21

```diff
285,286c285,288
<     this.left = false;
<     this.right = false;
---
>     this.cannon = new Ball(this.width, this.height);
>     this.cannon.setPosition(this.width/2, this.height-50);
>     this.cannon.show();
> 
298,301d299
<     this.cannon = new Ball(this.width, this.height);
<     this.cannon.setPosition(this.width/2, this.height-50);
<     this.cannon.show();
< 
313,318d310
<     if (this.left && this.angle < 160)
<       this.angle = this.angle + 1;
<     if (this.right && this.angle > 20)
<       this.angle = this.angle - 1;
<     this.updateArrow();
< 
327c319
<     this.left = b;
---
>     console.log("left", b); 
331c323
<     this.right = b;
---
>     console.log("right", b); 
339d330
<       this.fire.setColor(this.cannon.getColor());
341c332
<       this.fire.setAngle(this.angle);
---
>       this.fire.setAngle(45);
345d335
<       this.cannon.randomColor();
```

## Diff 23 vs 22

```diff
204a205,210
> /*
>           this.setPosition(this.width/2, this.height-40);
>           this.setAngle(20+Math.random()*140);
>           this.setSpeed(5);
>           this.randomColor();
> */
225a232,237
> /*
>         this.setPosition(this.width/2, this.height-40);
>         this.setAngle(20+Math.random()*140);
>         this.setSpeed(5);
>         this.randomColor();
> */
322a335
>     console.log("fire", b); 
337,340c350
<     var vx = pt.x - this.cannon.x;
<     var vy = pt.y - this.cannon.y;
<     this.angle = Math.floor(Math.atan2(-vy, vx) * 180 / Math.PI);
<     this.onKeyFire(true);
---
>     console.log("mouse", pt);
```

## Diff 24 vs 23

```diff
160c160
<             hanging.indexOf(balls[i]) == -1 && !balls[i].isFire() && !balls[i].isFalling())
---
>             hanging.indexOf(balls[i]) == -1 && !balls[i].isFire())
165,172d164
< 
<       var remaining = 0;
<       for (var i=0; i<balls.length; i++)
<       {
<         if (balls[i].element && balls[i].isVisible() && !balls[i].isFire() && !balls[i].isFalling())
<           remaining = remaining + 1;
<       }
<       console.log("Ostava ", remaining, "guliciek");
```

## Diff 25 vs 24

```diff
340,345c340
< 
<       var colors = this.balls.filter(b=>b.isVisible() && !b.isFire() && !b.isFalling())
<         .map(b=>b.getColor());
<       colors = colors.filter((v, i, a) => a.indexOf(v) === i);
<       var rcolor = colors[Math.floor(Math.random()*colors.length)];
<       this.cannon.setColor(rcolor);
---
>       this.cannon.randomColor();
```

## Diff 26 vs 25

```diff
173,176d172
<       if (remaining == 0)
<       {
<         console.log("Vyhral !");
<       }
207c203
<   checkHit(balls)
---
>   update(balls)
208a205,206
>     if (this.isFire() && !this.isFalling())
>     {
214c212,214
<           return true;
---
>           this.hit(balls);
>           this.destroy();
>           return;
216,225d215
<     return false;
<   }
< 
<   update(balls)
<   {
<     if (this.isFire() && !this.isFalling() && this.checkHit(balls))
<     {
<       this.hit(balls);
<       this.destroy();
<       return;
351,357c341
<       if (this.fire.checkHit(this.balls))
<       {
<         this.fire.destroy();
<         console.log("Prehral!");
<       }
< 
<       var colors = this.balls.filter(b=>b.element && b.isVisible() && !b.isFire() && !b.isFalling())
---
>       var colors = this.balls.filter(b=>b.isVisible() && !b.isFire() && !b.isFalling())
```

## Diff 27 vs 26

```diff
3,10d2
<   <div id="loser" class="wave" style="visibility:hidden">
<    <span style="--i:1">L</span>
<    <span style="--i:2">o</span>
<    <span style="--i:3">s</span>
<    <span style="--i:4">e</span>
<    <span style="--i:5">r</span>
<    <span style="--i:6">!</span>
<   </div>
12d3
< <link rel="stylesheet" href="wave.css">
280c271,289
<     this.restart();
---
>     var element = document.querySelector("#game");
>     this.width = parseInt(element.style.width);
>     this.height = parseInt(element.style.height);
> 
>     for (var y=0; y<18; y++)
>       for (var x=0; x<11-(y%2); x++)
>       {
>         var b = new Ball(this.width, this.height);
>         if (y%2==0)
>           b.setPosition(x*36+20, 20+y*32);
>         else
>           b.setPosition(x*36+20+18, 20+y*32);
> 
>         if (y<5)
>           b.show();
>         else
>           b.hide();
>         this.balls.push(b)
>       }
304,329d312
<   restart()
<   {
<     for (var i=0; i<this.balls.length; i++)
<       this.balls[i].destroy();
<     this.balls = [];
< 
<     var element = document.querySelector("#game");
<     this.width = parseInt(element.style.width);
<     this.height = parseInt(element.style.height);
< 
<     for (var y=0; y<18; y++)
<       for (var x=0; x<11-(y%2); x++)
<       {
<         var b = new Ball(this.width, this.height);
<         if (y%2==0)
<           b.setPosition(x*36+20, 20+y*32);
<         else
<           b.setPosition(x*36+20+18, 20+y*32);
< 
<         if (y<5)
<           b.show();
<         else
<           b.hide();
<         this.balls.push(b)
<       }
<   }
372d354
<         this.onLose();
389,403d370
< 
<   onLose()
<   {
<    document.querySelector("#loser").style.visibility = "visible";
<    setTimeout(()=>
<    {
<      this.onContinue();
<    }, 5000);
<   }
< 
<   onContinue()
<   {
<    document.querySelector("#loser").style.visibility = "hidden";
<    this.restart();
<   }
```

## Diff 28 vs 27

```diff
11,18d10
<   <div id="winner" class="wave" style="visibility:hidden">
<    <span style="--i:1">W</span>
<    <span style="--i:2">i</span>
<    <span style="--i:3">n</span>
<    <span style="--i:4">n</span>
<    <span style="--i:5">e</span>
<    <span style="--i:6">r</span>
<   </div>
25c17
<   constructor(game)
---
>   constructor(width, height)
27,29c19,20
<     this.game = game;
<     this.width = game.width;
<     this.height = game.height;
---
>     this.width = width;
>     this.height = height;
194d184
<         this.game.onWin();
217c207
<       var b = new Ball(this);
---
>       var b = new Ball(this.width, this.height);
305c295
<     this.cannon = new Ball(this);
---
>     this.cannon = new Ball(this.width, this.height);
327c317
<         var b = new Ball(this);
---
>         var b = new Ball(this.width, this.height);
339d328
<     this.playing = true;
369,370d357
<     if (!this.playing)
<       return;
373c360
<       this.fire = new Ball(this);
---
>       this.fire = new Ball(this.width, this.height);
405,408d391
<    if (!this.playing)
<      return;
<    this.playing = false;
< 
416,428d398
<   onWin()
<   {
<    if (!this.playing)
<      return;
<    this.playing = false;
< 
<    document.querySelector("#winner").style.visibility = "visible";
<    setTimeout(()=>
<    {
<      this.onContinue();
<    }, 5000);
<   }
< 
432d401
<    document.querySelector("#winner").style.visibility = "hidden";
```

## Diff 29 vs 28

```diff
290,293c290
< //    this.restart();
<     var element = document.querySelector("#game");
<     this.width = parseInt(element.style.width);
<     this.height = parseInt(element.style.height);
---
>     this.restart();
317d313
< 
323a320,323
>     var element = document.querySelector("#game");
>     this.width = parseInt(element.style.width);
>     this.height = parseInt(element.style.height);
> 
338a339
>     this.playing = true;
367a369,370
>     if (!this.playing)
>       return;
399,408d401
< }
< 
< class GameController extends Game
< {
<   constructor()
<   {
<     super();
<     this.playing = true;
<     this.restart();
<   }
440d432
<    this.playing = false;
445c437
< var game = new GameController();
---
> var game = new Game();
```

## Diff 30 vs 29

```diff
31c31
<     this.randomColor();
---
>     this.element.src = ["red.png", "green.png", "blue.png"][Math.floor(Math.random()*3)];
97c97
<     this.element.src = this.game.colors[Math.floor(Math.random()*this.game.colors.length)];
---
>     this.element.src = ["red.png", "green.png", "blue.png"][Math.floor(Math.random()*3)];
217c217
<       var b = new Ball(this.game);
---
>       var b = new Ball(this);
289d288
<     this.colors = [];
308a308,311
>     this.cannon = new Ball(this);
>     this.cannon.setPosition(this.width/2, this.height-50);
>     this.cannon.show();
> 
315c318
<   restart(levelconfig)
---
>   restart()
317,320d319
<     //this.levelconfig = levelconfig;
<     this.colors = levelconfig.colors;
<     if (this.cannon)
<       this.cannon.destroy();
334c333
<         if (y<levelconfig.rows)
---
>         if (y<5)
340,343d338
< 
<     this.cannon = new Ball(this);
<     this.cannon.setPosition(this.width/2, this.height-50);
<     this.cannon.show();
412,413c407
<     this.level = 1;
<     this.onContinue();
---
>     this.restart();
434c428
<    this.level = this.level + 1;
---
> 
446,449c440,441
<    this.playing = true;
< 
<    var levelconfig = {rows:3, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
<    this.restart(levelconfig);
---
>    this.playing = false;
>    this.restart();
```

## Diff 31 vs 30

```diff
448,456c448
<    var levelconfig;
< 
<    if (this.level == 1)
<      levelconfig = {rows:3, colors:["red.png", "green.png"]};
<    else if (this.level == 2)
<      levelconfig = {rows:4, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
<    else 
<      levelconfig = {rows:5, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
< 
---
>    var levelconfig = {rows:3, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
```

## Diff 32 vs 31

```diff
117c117
<           balls[i].y < this.game.top+30)
---
>           balls[i].y < 30)
255c255
<     if (this.y < this.game.top+20)
---
>     if (this.y < 20)
272,275d271
<       if (!this.isFire() && this.isVisible())
<       {
<         this.game.onLose(); // vsetko by malo vybuchnut
<       }
321d316
<     this.top = 0;
364,368d358
<       if (!this.balls[i].isFire() && !this.balls[i].isFalling())
<         this.balls[i].y += 0.1;
<     this.top += 0.1;
< 
<     for (var i=0; i<this.balls.length; i++)
```

## Diff 33 vs 32

```diff
3d2
< <img id="bar" src="bar.png" style="position:absolute;">
368,369c367
<     document.querySelector("#bar").style.top = this.top-282;
<  	
---
> 
```

## Diff 34 vs 33

```diff
183c183
<       this.game.explode(matching);
---
>       this.explode(balls, matching);
199a200,226
>   explode(balls, expl)
>   {
>     var sumx = 0, sumy = 0;
>     for (var i=0; i<expl.length; i++)
>     {
>       sumx += expl[i].x;
>       sumy += expl[i].y;
>     }
>     sumx /= expl.length;
>     sumy /= expl.length;
> 
>     for (var i=0; i<expl.length; i++)
>     {
>       var vectx = expl[i].x - sumx;
>       var vecty = expl[i].y - sumy;
>       var angle = Math.atan2(vecty, vectx) / Math.PI * 180;
> 
>       expl[i].hide();
>       var b = new Ball(this.game);
>       b.setColor(expl[i].getColor());
>       b.setPosition(expl[i].x, expl[i].y);
>       b.setAngle(angle);
>       b.ay = 0.1;
>       balls.push(b);
>     }
>   }
> 
389,415d415
< 
<   explode(expl)
<   {
<     var sumx = 0, sumy = 0;
<     for (var i=0; i<expl.length; i++)
<     {
<       sumx += expl[i].x;
<       sumy += expl[i].y;
<     }
<     sumx /= expl.length;
<     sumy /= expl.length;
< 
<     for (var i=0; i<expl.length; i++)
<     {
<       var vectx = expl[i].x - sumx;
<       var vecty = expl[i].y - sumy;
<       var angle = Math.atan2(vecty, vectx) / Math.PI * 180;
< 
<       expl[i].hide();
<       var b = new Ball(this);
<       b.setColor(expl[i].getColor());
<       b.setPosition(expl[i].x, expl[i].y);
<       b.setAngle(angle);
<       b.ay = 0.1;
<       this.balls.push(b);
<     }
<   }
433,449d432
< /*
<    var visible = [];
<    for (var i=0; i<this.balls.length; i++)
<      if (this.balls[i].element && this.balls[i].isVisible() && !this.balls[i].isFire() && !this.balls[i].isFalling())
<        visible.push(this.balls[i]);
<    this.explode(visible);
< */
< /*
<    var visible = [];
<    for (let ball of this.balls)
<      if (ball.element && ball.isVisible() && !ball.isFire() && !ball.isFalling())
<        visible.push(ball);
<    this.explode(visible);
< */
<    var visible = this.balls.filter(ball => ball.element && ball.isVisible() && 
<      !ball.isFire() && !ball.isFalling())
<    this.explode(visible);
```

## Diff 35 vs 34

```diff
298d297
<     this.scrollSpeed = levelconfig.speed;
340,346c339,340
<         this.balls[i].y += this.scrollSpeed;
< 
<     if (this.scrollSpeed == 0)
<       this.top = this.top * 0.9;
<     else
<       this.top += this.scrollSpeed;
< 
---
>         this.balls[i].y += 0.1;
>     this.top += 0.1;
364c358
<     if (this.playing && b)
---
>     if (b)
384,388c378,379
<       if (colors.length > 0)
<       {
<         var rcolor = colors[Math.floor(Math.random()*colors.length)];
<         this.cannon.setColor(rcolor);
<       }
---
>       var rcolor = colors[Math.floor(Math.random()*colors.length)];
>       this.cannon.setColor(rcolor);
442c433,446
<    this.scrollSpeed = 0;
---
> /*
>    var visible = [];
>    for (var i=0; i<this.balls.length; i++)
>      if (this.balls[i].element && this.balls[i].isVisible() && !this.balls[i].isFire() && !this.balls[i].isFalling())
>        visible.push(this.balls[i]);
>    this.explode(visible);
> */
> /*
>    var visible = [];
>    for (let ball of this.balls)
>      if (ball.element && ball.isVisible() && !ball.isFire() && !ball.isFalling())
>        visible.push(ball);
>    this.explode(visible);
> */
459d462
<    this.scrollSpeed = 0;
477c480
<      levelconfig = {rows:3, speed:0.5, colors:["red.png", "green.png"]};
---
>      levelconfig = {rows:3, colors:["red.png", "green.png"]};
479c482
<      levelconfig = {rows:4, speed:0.1, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
---
>      levelconfig = {rows:4, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
481c484
<      levelconfig = {rows:5, speed:0.1, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
---
>      levelconfig = {rows:5, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
```

## Diff 36 vs 35

```diff
299,300d298
<     this.wind = levelconfig.wind;
< 
368d365
<       this.angle = Math.min(Math.max(20, this.angle), 160);
374d370
<       this.fire.ax = this.wind;
481c477
<      levelconfig = {rows:3, speed:0.0, wind:0.02, colors:["red.png", "green.png"]};
---
>      levelconfig = {rows:3, speed:0.5, colors:["red.png", "green.png"]};
483c479
<      levelconfig = {rows:4, speed:0.0, wind:0, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
---
>      levelconfig = {rows:4, speed:0.1, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
485c481
<      levelconfig = {rows:5, speed:0.1, wind:0, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
---
>      levelconfig = {rows:5, speed:0.1, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
```

## Diff 37 vs 36

```diff
20d19
<   <div id="level" style="visibility:hidden">Level 1</div>
23d21
< <link rel="stylesheet" href="level.css">
476d473
<    this.showLevel();
481a479
> 
491,503d488
< 
<   showLevel()
<   {
<     var level = document.querySelector("#level");
<     level.innerHTML = "Level " + this.level;
<     level.style.visibility = "visible";
<     level.className = "level";
<     setTimeout(() =>
<     {
<       level.style.visibility = "hidden";
<       level.className = "";
<     }, 3000);
<   }
```

## Diff 38 vs 37

```diff
481c481,487
<    var levelconfig = this.getLevelConfig();
---
>    var levelconfig;
>    if (this.level == 1)
>      levelconfig = {rows:3, speed:0.0, wind:0.02, colors:["red.png", "green.png"]};
>    else if (this.level == 2)
>      levelconfig = {rows:4, speed:0.0, wind:0, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
>    else 
>      levelconfig = {rows:5, speed:0.1, wind:0, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
498,509d503
< 
<   getLevelConfig()
<   {
<     switch (this.level)
<     {
<       case 1: return {rows:3, speed:0.0, wind:0.02, colors:["red.png", "green.png"]};
<       case 2: return {rows:4, speed:0.0, wind:0, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
<       case 3: return {rows:5, speed:0.1, wind:0, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
<       default:
<         return {rows:5, speed:0.2, wind:0, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
<     }
<   }
```

## Diff 39 vs 38

```diff
161d160
<       this.game.sounds.playDrop();
219d217
<       this.game.sounds.playHit();
230d227
<     {
232,234d228
<       if (this.isFire() && !this.isFalling())
<         this.game.sounds.playSpring();
<     }
236d229
<     {
238,240d230
<       if (this.isFire() && !this.isFalling())
<         this.game.sounds.playSpring();
<     }
246d235
<         this.game.sounds.playHit();
444,482d432
< class Sounds 
< {
<   constructor()
<   {
<     this.spring = new Audio("spring.mp3");
<     this.throwing = new Audio("throw.mp3");
<     this.win = new Audio("win.mp3");
<     this.lose = new Audio("lose.mp3");
<     this.hit = new Audio("hit.mp3");
<     this.drop = new Audio("drop.mp3");
<   }
<   playWin()
<   {
<     this.win.play();
<   }
<   playLose()
<   {
<     this.lose.play();
<   }
<   playThrow()
<   {
<     this.throwing.play();
<   }
<   playSpring()
<   {
<     this.spring.pause();
<     this.spring.currentTime = 0;
<     this.spring.play();
<   }
<   playHit()
<   {
<     this.hit.play();
<   }
<   playDrop()
<   {
<     this.drop.play();
<   }
< }
< 
488d437
<     this.sounds = new Sounds();
498d446
<    this.sounds.playLose();
516d463
<    this.sounds.playWin();
556c503
<       case 1: return {rows:3, speed:0.0, wind:0, colors:["red.png", "green.png"]};
---
>       case 1: return {rows:3, speed:0.0, wind:0.02, colors:["red.png", "green.png"]};
558c505
<       case 3: return {rows:5, speed:0.1, wind:0.01, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
---
>       case 3: return {rows:5, speed:0.1, wind:0, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
```

## Diff 40 vs 39

```diff
3c3
<   <img id="bar" src="bar.png" style="position:absolute;">
---
> <img id="bar" src="bar.png" style="position:absolute;">
21,39d20
<   <div id="menu" class="menu" style="visibility:visible; z-index:100;">
< <!--    <div class="menu_white"></div>-->
<     <div class="menu_background"></div>
<     <div class="frozen">Frozen bubble</div>
<     <div style="padding-left:10px;">
<       <div class="chest_closed">1</div>
<       <div class="chest_closed">2</div>
<       <div class="chest_closed">3</div>
<       <div class="chest_open">4</div>
<       <div class="chest_open">5</div>
<       <div class="chest_closed">6</div>
<       <div class="chest_closed">7</div>
<       <div class="chest_closed">8</div>
<       <div class="chest_closed">9</div>
<       <div class="chest_closed">10</div>
<       <div class="chest_closed">11</div>
<       <div class="chest_closed">12</div>
<     </div>
<   </div>
43d23
< <link rel="stylesheet" href="menu.css">
512a493
> 
```

## Diff 41 vs 40

```diff
21,22c21,22
<   <div id="menu" class="menu" style="visibility:hidden; z-index:100;">
<     <div class="menu_white"></div>
---
>   <div id="menu" class="menu" style="visibility:visible; z-index:100;">
> <!--    <div class="menu_white"></div>-->
29,30c29,30
<       <div class="chest_closed">4</div>
<       <div class="chest_closed">5</div>
---
>       <div class="chest_open">4</div>
>       <div class="chest_open">5</div>
322,323c322
<       if (this.engineRunning)
<         this.update()
---
>       this.update()
334d332
<     this.engineRunning = true;
401,403d398
<     if (!this.engineRunning)
<       return;
< 
435,437d429
<     if (!this.engineRunning)
<       return;
< 
519,539c511
< 
<     this.unlockedLevels = [1];
<     this.showMenu();
<   }
<   showMenu()
<   {
<     this.engineRunning = false;
<     document.querySelector("#menu").style.visibility = "visible";
< //    document.querySelectorAll(".chest_open").forEach( elem => elem.className = "chest_closed" );
<     document.querySelectorAll(".chest_closed").forEach( elem => {
<       var l = parseInt(elem.innerHTML);
<       if (this.unlockedLevels.indexOf(l) != -1)
<         elem.className = "chest_open";
<     });
< 
<     document.querySelectorAll(".chest_open").forEach( elem => elem.onclick = (e) => {
<       var level = parseInt(e.target.innerHTML);
<       console.log("Set level: " + level);
<       this.level = level;
<       this.onContinue();
<     });
---
>     this.onContinue();
555,556c527
<      //this.onContinue();
<      this.showMenu();
---
>      this.onContinue();
567,568d537
<    if (this.unlockedLevels.indexOf(this.level+1) == -1)
<      this.unlockedLevels.push(this.level+1);
580d548
<    document.querySelector("#menu").style.visibility = "hidden";
607,620c575,577
<       case 1: return {speed: 0.00, rows: 5, wind:0, colors: ["red.png", "green.png", "blue.png"]};
<       case 2: return {speed: 0.00, rows: 5, wind:0.03, colors: ["red.png", "green.png", "blue.png"]};
<       case 3: return {speed: 0.01, rows: 6, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png"]};
<       case 4: return {speed: 0.04, rows: 3, wind:0, colors: ["bri050.png", "bri100.png", "bri150.png"]};
< 
<       case 5: return {speed: 0.01, rows: 6, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png", "mod200.png"]};
<       case 6: return {speed: 0.01, rows: 5, wind:-0.05,  colors: ["red.png", "green.png", "blue.png", "bri150.png"]};
<       case 7: return {speed: 0.02, rows: 6, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png", "mod200.png", "mod075.png"]};
<       case 8: return {speed: 0.07, rows: 4, wind:0.03, timeout:0, colors: ["red.png", "green.png", "blue.png"]};
< 
<       case 9: return {speed: 0.03, rows: 6, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png", "mod200.png", "mod075.png", "bri050.png"]};
<       case 10: return {speed: 0.06, rows: 3, wind:0.02, colors: ["bri050.png", "bri100.png", "bri150.png", "bri200.png"]};
<       case 11: return {speed: 0.05, rows: 6, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png", "mod200.png", "mod075.png"]};
<       case 12: return {speed: 0.08, rows: 5, wind:0.01, colors: ["red.png", "green.png", "blue.png", "mod150.png", "mod200.png", "mod075.png", "bri050.png"]};
---
>       case 1: return {rows:3, speed:0.0, wind:0, colors:["red.png", "green.png"]};
>       case 2: return {rows:4, speed:0.0, wind:0, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
>       case 3: return {rows:5, speed:0.1, wind:0.01, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
622c579
<         return {speed: 0.08, rows: 7, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png", "mod200.png", "mod075.png", "bri050.png", "bri150.png"]};
---
>         return {rows:5, speed:0.2, wind:0, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
```

## Diff 42 vs 41

```diff
519,520c519,520
<     this.loadUnlockedLevels();
< //    this.unlockedLevels = [1];
---
> 
>     this.unlockedLevels = [1];
523,535d522
<   loadUnlockedLevels()
<   {
<     var persistent = localStorage.getItem("unlocked_levels");
<     if (persistent)
<       this.unlockedLevels = JSON.parse(persistent);
<     else
<       this.unlockedLevels = [1];
<   }
<   saveUnlockedLevels()
<   {
<     var persistent = JSON.stringify(this.unlockedLevels);
<     localStorage.setItem("unlocked_levels", persistent);
<   }
581d567
<    {
583,584d568
<      this.saveUnlockedLevels();
<    }
626c610
<       case 4: return {speed: 0.06, rows: 3, wind:0, colors: ["bri050.png", "bri100.png", "bri150.png"]};
---
>       case 4: return {speed: 0.04, rows: 3, wind:0, colors: ["bri050.png", "bri100.png", "bri150.png"]};
628,630c612,614
<       case 5: return {speed: 0.02, rows: 6, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png", "mod200.png"]};
<       case 6: return {speed: 0.02, rows: 5, wind:-0.05,  colors: ["red.png", "green.png", "blue.png", "bri150.png"]};
<       case 7: return {speed: 0.04, rows: 6, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png", "mod200.png", "mod075.png"]};
---
>       case 5: return {speed: 0.01, rows: 6, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png", "mod200.png"]};
>       case 6: return {speed: 0.01, rows: 5, wind:-0.05,  colors: ["red.png", "green.png", "blue.png", "bri150.png"]};
>       case 7: return {speed: 0.02, rows: 6, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png", "mod200.png", "mod075.png"]};
633c617
<       case 9: return {speed: 0.05, rows: 6, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png", "mod200.png", "mod075.png", "bri050.png"]};
---
>       case 9: return {speed: 0.03, rows: 6, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png", "mod200.png", "mod075.png", "bri050.png"]};
```

## Diff 43 vs 42

```diff
2,5d1
< <head>
< <meta content="width=device-width" name="viewport"/>
< <meta name="viewport" content="width=device-width,initial-scale=0.9,minimum-scale=0.9,maximum-scale=3.9" />
< </head>
48d43
< <link rel="stylesheet" href="phone.css">
631c626
<       case 4: return {speed: 0.08, rows: 3, wind:0, colors: ["bri050.png", "bri100.png", "bri150.png"]};
---
>       case 4: return {speed: 0.06, rows: 3, wind:0, colors: ["bri050.png", "bri100.png", "bri150.png"]};
```

