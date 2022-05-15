# Diff

## Reference

```html
<html>
<div id="game" style="width:400px; height:600px; border:1px solid #d0d0d0; position:relative; background:url(background1.jpg); overflow:hidden;">
</div>

<script>
var element = document.querySelector("#game");
var width = parseInt(this.element.style.width);
var height = parseInt(this.element.style.height);

var x = width/2;
var y = height/2;

var ball = document.createElement("img");
ball.src = "red.png";
ball.setAttribute("style", "position:absolute");
element.appendChild(ball);

setInterval(() => 
{
    ball.style.left = x-20;
    ball.style.top = y-20;
}, 10);
</script>
</html>
```
## Diff 01 vs 00

 - [clean01/index.html](clean01/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean01/index.html)

```diff
--- ../clean00/index.html	2022-05-14 09:08:56.000000000 +0200
+++ ../clean01/index.html	2022-05-06 08:53:19.000000000 +0200
@@ -9,6 +9,8 @@
 
 var x = width/2;
 var y = height/2;
+var vx = 0;
+var vy = 0;
 
 var ball = document.createElement("img");
 ball.src = "red.png";
@@ -17,6 +19,8 @@
 
 setInterval(() => 
 {
+    x = x + vx;
+    y = y + vy;
     ball.style.left = x-20;
     ball.style.top = y-20;
 }, 10);
```

## Diff 02 vs 01

 - [clean02/index.html](clean02/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean02/index.html)

```diff
--- ../clean01/index.html	2022-05-06 08:53:19.000000000 +0200
+++ ../clean02/index.html	2022-05-06 08:53:28.000000000 +0200
@@ -11,6 +11,7 @@
 var y = height/2;
 var vx = 0;
 var vy = 0;
+var radius = 20;
 
 var ball = document.createElement("img");
 ball.src = "red.png";
@@ -21,6 +22,17 @@
 {
     x = x + vx;
     y = y + vy;
+
+    if (x < 20)
+      vx = Math.abs(vx);
+    if (x > width-20)
+      vx = -Math.abs(vx);
+
+    if (y < 20)
+      vy = Math.abs(vy);
+    if (y > height-20)
+      vy = -Math.abs(vy);
+
     ball.style.left = x-20;
     ball.style.top = y-20;
 }, 10);
```

## Diff 03 vs 02

 - [clean03/index.html](clean03/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean03/index.html)

```diff
--- ../clean02/index.html	2022-05-06 08:53:28.000000000 +0200
+++ ../clean03/index.html	2022-05-06 08:53:35.000000000 +0200
@@ -9,8 +9,10 @@
 
 var x = width/2;
 var y = height/2;
-var vx = 0;
-var vy = 0;
+var vx = 5;
+var vy = -2;
+var ax = 0;
+var ay = 0.1;
 var radius = 20;
 
 var ball = document.createElement("img");
@@ -20,6 +22,10 @@
 
 setInterval(() => 
 {
+    vx = vx + ax;
+    vy = vy + ay;
+    vx = vx * 0.99;
+    vy = vy * 0.99;
     x = x + vx;
     y = y + vy;
 
@@ -31,7 +37,12 @@
     if (y < 20)
       vy = Math.abs(vy);
     if (y > height-20)
+    {
       vy = -Math.abs(vy);
+      y = height-20;
+      vy *= 0.8;
+      vx *= 0.8;
+    }
 
     ball.style.left = x-20;
     ball.style.top = y-20;
```

## Diff 04 vs 03

 - [clean04/index.html](clean04/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean04/index.html)

```diff
--- ../clean03/index.html	2022-05-06 08:53:35.000000000 +0200
+++ ../clean04/index.html	2022-05-06 08:53:45.000000000 +0200
@@ -7,45 +7,65 @@
 var width = parseInt(this.element.style.width);
 var height = parseInt(this.element.style.height);
 
-var x = width/2;
-var y = height/2;
-var vx = 5;
-var vy = -2;
-var ax = 0;
-var ay = 0.1;
+var x = []; //width/2;
+var y = []; //height/2;
+var vx = []; //5;
+var vy = []; //-2;
+var ax = []; //0;
+var ay = []; //0.1;
 var radius = 20;
-
-var ball = document.createElement("img");
+var balls = []; 
+/*document.createElement("img");
 ball.src = "red.png";
 ball.setAttribute("style", "position:absolute");
-element.appendChild(ball);
+document.querySelector("#game").appendChild(ball);
+*/
+
+for (var i=0; i<10; i++)
+{
+  var b = document.createElement("img");
+  b.src = "red.png";
+  b.setAttribute("style", "position:absolute");
+  element.appendChild(b);
+  balls.push(b);
+
+  x.push(Math.random()*width);
+  y.push(Math.random()*height);
+  vx.push(Math.random()*5-2.5);
+  vy.push(Math.random()*5-2.5);
+  ax.push(0);
+  ay.push(0);
+}
 
 setInterval(() => 
 {
-    vx = vx + ax;
-    vy = vy + ay;
-    vx = vx * 0.99;
-    vy = vy * 0.99;
-    x = x + vx;
-    y = y + vy;
-
-    if (x < 20)
-      vx = Math.abs(vx);
-    if (x > width-20)
-      vx = -Math.abs(vx);
-
-    if (y < 20)
-      vy = Math.abs(vy);
-    if (y > height-20)
+  for (var i=0; i<balls.length; i++)
+  {
+    vx[i] = vx[i] + ax[i];
+    vy[i] = vy[i] + ay[i];
+//    vx[i] = vx[i] * 0.99;
+//    vy[i] = vy[i] * 0.99;
+    x[i] = x[i] + vx[i];
+    y[i] = y[i] + vy[i];
+
+    if (x[i] < 20)
+      vx[i] = Math.abs(vx[i]);
+    if (x[i] > width-20)
+      vx[i] = -Math.abs(vx[i]);
+
+    if (y[i] < 20)
+      vy[i] = Math.abs(vy[i]);
+    if (y[i] > height-20)
     {
-      vy = -Math.abs(vy);
-      y = height-20;
-      vy *= 0.8;
-      vx *= 0.8;
+      vy[i] = -Math.abs(vy[i]);
+      y[i] = height-20;
+      vy[i] *= 0.8;
+      vx[i] *= 0.8;
     }
 
-    ball.style.left = x-20;
-    ball.style.top = y-20;
+    balls[i].style.left = x[i]-20;
+    balls[i].style.top = y[i]-20;
+  }
 }, 10);
 </script>
 </html>
\ No newline at end of file
```

## Diff 05 vs 04

 - [clean05/index.html](clean05/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean05/index.html)

```diff
--- ../clean04/index.html	2022-05-06 08:53:45.000000000 +0200
+++ ../clean05/index.html	2022-05-12 22:51:07.000000000 +0200
@@ -21,12 +21,12 @@
 document.querySelector("#game").appendChild(ball);
 */
 
-for (var i=0; i<10; i++)
+for (var i=0; i<100; i++)
 {
   var b = document.createElement("img");
   b.src = "red.png";
   b.setAttribute("style", "position:absolute");
-  element.appendChild(b);
+  document.querySelector("#game").appendChild(b);
   balls.push(b);
 
   x.push(Math.random()*width);
@@ -41,10 +41,32 @@
 {
   for (var i=0; i<balls.length; i++)
   {
+    ax[i] = 0;
+    ay[i] = 0.05;
+  
+    for (var j=0; j<balls.length; j++)
+      if (i!=j)
+      {
+        var ux = x[j] - x[i];
+        var uy = y[j] - y[i];
+        var angleRad = Math.atan2(uy, ux);
+        var dist = Math.sqrt(ux**2+uy**2);
+        if (dist < 20)
+        {
+          dist = 21-dist;
+          ax[i] -= Math.cos(angleRad)*(dist/50); 
+          ay[i] -= Math.sin(angleRad)*(dist/50); 
+        } else {
+          ax[i] += Math.cos(angleRad)*(dist/10000)**2; 
+          ay[i] += Math.sin(angleRad)*(dist/10000)**2; 
+        }
+
+      }
+
     vx[i] = vx[i] + ax[i];
     vy[i] = vy[i] + ay[i];
-//    vx[i] = vx[i] * 0.99;
-//    vy[i] = vy[i] * 0.99;
+    vx[i] = vx[i] * 0.99;
+    vy[i] = vy[i] * 0.99;
     x[i] = x[i] + vx[i];
     y[i] = y[i] + vy[i];
 
```

## Diff 06 vs 05

 - [clean06/index.html](clean06/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean06/index.html)

```diff
--- ../clean05/index.html	2022-05-12 22:51:07.000000000 +0200
+++ ../clean06/index.html	2022-04-21 22:17:28.000000000 +0200
@@ -21,10 +21,10 @@
 document.querySelector("#game").appendChild(ball);
 */
 
-for (var i=0; i<100; i++)
+for (var i=0; i<10; i++)
 {
   var b = document.createElement("img");
-  b.src = "red.png";
+  b.src = ["red.png", "green.png", "blue.png"][Math.floor(Math.random()*3)];
   b.setAttribute("style", "position:absolute");
   document.querySelector("#game").appendChild(b);
   balls.push(b);
@@ -40,33 +40,44 @@
 setInterval(() => 
 {
   for (var i=0; i<balls.length; i++)
-  {
-    ax[i] = 0;
-    ay[i] = 0.05;
-  
-    for (var j=0; j<balls.length; j++)
-      if (i!=j)
+  {  
+    for (var j=i+1; j<balls.length; j++)
+    {
+      var ux = x[i] - x[j];
+      var uy = y[i] - y[j];
+      var dist = Math.sqrt(ux**2+uy**2);
+      if (dist<40)
       {
-        var ux = x[j] - x[i];
-        var uy = y[j] - y[i];
-        var angleRad = Math.atan2(uy, ux);
-        var dist = Math.sqrt(ux**2+uy**2);
-        if (dist < 20)
+        var mtd = 40-dist;
+        var mtdx = ux/dist*mtd;
+        var mtdy = uy/dist*mtd;
+        var mtdl = Math.sqrt(mtdx**2+mtdy**2);
+        x[i] += mtdx/2;
+        y[i] += mtdy/2;
+        x[j] -= mtdx/2;
+        y[j] -= mtdy/2;
+
+        mtdx /= mtdl;
+        mtdy /= mtdl;
+        var velx = vx[i] - vx[j];
+        var vely = vy[i] - vy[j];
+        var vn = velx*mtdx+vely*mtdy;
+        if (vn < 0)
         {
-          dist = 21-dist;
-          ax[i] -= Math.cos(angleRad)*(dist/50); 
-          ay[i] -= Math.sin(angleRad)*(dist/50); 
-        } else {
-          ax[i] += Math.cos(angleRad)*(dist/10000)**2; 
-          ay[i] += Math.sin(angleRad)*(dist/10000)**2; 
+          var rest = 1;
+          var im = -(-(1+rest)*vn) / 2;
+          var impx = mtdx*im;
+          var impy = mtdy*im;
+          vx[i] -= impx;
+          vy[i] -= impy;
+          vx[j] += impx;
+          vy[j] += impy;
         }
-
       }
+    }
 
     vx[i] = vx[i] + ax[i];
     vy[i] = vy[i] + ay[i];
-    vx[i] = vx[i] * 0.99;
-    vy[i] = vy[i] * 0.99;
     x[i] = x[i] + vx[i];
     y[i] = y[i] + vy[i];
 
```

## Diff 07 vs 06

 - [clean07/index.html](clean07/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean07/index.html)

```diff
--- ../clean06/index.html	2022-04-21 22:17:28.000000000 +0200
+++ ../clean07/index.html	2022-04-21 22:24:08.000000000 +0200
@@ -7,98 +7,53 @@
 var width = parseInt(this.element.style.width);
 var height = parseInt(this.element.style.height);
 
-var x = []; //width/2;
-var y = []; //height/2;
-var vx = []; //5;
-var vy = []; //-2;
-var ax = []; //0;
-var ay = []; //0.1;
-var radius = 20;
+class Ball
+{
+  constructor(width, height)
+  {
+    this.width = width;
+    this.height = height;
+    this.element = document.createElement("img");
+    this.element.src = ["red.png", "green.png", "blue.png"][Math.floor(Math.random()*3)];
+    this.element.setAttribute("style", "position:absolute");
+    document.querySelector("#game").appendChild(this.element);
+    this.x = Math.random()*width;
+    this.y = Math.random()*height;
+    this.vx = Math.random()*5-2.5;
+    this.vy = Math.random()*5-2.5;
+    this.ax = 0;
+    this.ay = 0;
+  }
+  update()
+  {
+    this.vx = this.vx + this.ax;
+    this.vy = this.vy + this.ay;
+    this.x = this.x + this.vx;
+    this.y = this.y + this.vy;
+
+    if (this.x < 20)
+      this.vx = Math.abs(this.vx);
+    if (this.x > this.width-20)
+      this.vx = -Math.abs(this.vx);
+    if (this.y < 20)
+      this.vy = Math.abs(this.vy);
+    if (this.y > this.height-20)
+      this.vy = -Math.abs(this.vy);
+
+    this.element.style.left = this.x-20;
+    this.element.style.top = this.y-20;
+  }
+}
+
 var balls = []; 
-/*document.createElement("img");
-ball.src = "red.png";
-ball.setAttribute("style", "position:absolute");
-document.querySelector("#game").appendChild(ball);
-*/
 
 for (var i=0; i<10; i++)
-{
-  var b = document.createElement("img");
-  b.src = ["red.png", "green.png", "blue.png"][Math.floor(Math.random()*3)];
-  b.setAttribute("style", "position:absolute");
-  document.querySelector("#game").appendChild(b);
-  balls.push(b);
-
-  x.push(Math.random()*width);
-  y.push(Math.random()*height);
-  vx.push(Math.random()*5-2.5);
-  vy.push(Math.random()*5-2.5);
-  ax.push(0);
-  ay.push(0);
-}
+  balls.push(new Ball(width, height))
 
 setInterval(() => 
 {
   for (var i=0; i<balls.length; i++)
-  {  
-    for (var j=i+1; j<balls.length; j++)
-    {
-      var ux = x[i] - x[j];
-      var uy = y[i] - y[j];
-      var dist = Math.sqrt(ux**2+uy**2);
-      if (dist<40)
-      {
-        var mtd = 40-dist;
-        var mtdx = ux/dist*mtd;
-        var mtdy = uy/dist*mtd;
-        var mtdl = Math.sqrt(mtdx**2+mtdy**2);
-        x[i] += mtdx/2;
-        y[i] += mtdy/2;
-        x[j] -= mtdx/2;
-        y[j] -= mtdy/2;
-
-        mtdx /= mtdl;
-        mtdy /= mtdl;
-        var velx = vx[i] - vx[j];
-        var vely = vy[i] - vy[j];
-        var vn = velx*mtdx+vely*mtdy;
-        if (vn < 0)
-        {
-          var rest = 1;
-          var im = -(-(1+rest)*vn) / 2;
-          var impx = mtdx*im;
-          var impy = mtdy*im;
-          vx[i] -= impx;
-          vy[i] -= impy;
-          vx[j] += impx;
-          vy[j] += impy;
-        }
-      }
-    }
-
-    vx[i] = vx[i] + ax[i];
-    vy[i] = vy[i] + ay[i];
-    x[i] = x[i] + vx[i];
-    y[i] = y[i] + vy[i];
-
-    if (x[i] < 20)
-      vx[i] = Math.abs(vx[i]);
-    if (x[i] > width-20)
-      vx[i] = -Math.abs(vx[i]);
-
-    if (y[i] < 20)
-      vy[i] = Math.abs(vy[i]);
-    if (y[i] > height-20)
-    {
-      vy[i] = -Math.abs(vy[i]);
-      y[i] = height-20;
-      vy[i] *= 0.8;
-      vx[i] *= 0.8;
-    }
-
-    balls[i].style.left = x[i]-20;
-    balls[i].style.top = y[i]-20;
-  }
+    balls[i].update();
 }, 10);
 </script>
 </html>
\ No newline at end of file
```

## Diff 08 vs 07

 - [clean08/index.html](clean08/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean08/index.html)

```diff
--- ../clean07/index.html	2022-04-21 22:24:08.000000000 +0200
+++ ../clean08/index.html	2022-04-21 22:28:55.000000000 +0200
@@ -17,13 +17,18 @@
     this.element.src = ["red.png", "green.png", "blue.png"][Math.floor(Math.random()*3)];
     this.element.setAttribute("style", "position:absolute");
     document.querySelector("#game").appendChild(this.element);
-    this.x = Math.random()*width;
-    this.y = Math.random()*height;
-    this.vx = Math.random()*5-2.5;
-    this.vy = Math.random()*5-2.5;
+    this.x = 0;
+    this.y = 0;
+    this.vx = 0;
+    this.vy = 0;
     this.ax = 0;
     this.ay = 0;
   }
+  setPosition(x, y)
+  {
+    this.x = x;
+    this.y = y;
+  }
   update()
   {
     this.vx = this.vx + this.ax;
@@ -47,8 +52,16 @@
 
 var balls = []; 
 
-for (var i=0; i<10; i++)
-  balls.push(new Ball(width, height))
+for (var y=0; y<18; y++)
+  for (var x=0; x<11-(y%2); x++)
+  {
+    var b = new Ball(width, height);
+    if (y%2==0)
+      b.setPosition(x*36+20, 20+y*32);
+    else
+      b.setPosition(x*36+20+18, 20+y*32);
+    balls.push(b)
+  }
 
 setInterval(() => 
 {
```

## Diff 09 vs 08

 - [clean09/index.html](clean09/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean09/index.html)

```diff
--- ../clean08/index.html	2022-04-21 22:28:55.000000000 +0200
+++ ../clean09/index.html	2022-04-21 22:33:05.000000000 +0200
@@ -29,6 +29,25 @@
     this.x = x;
     this.y = y;
   }
+  setAngle(angleDeg)
+  {
+    var angleRad = angleDeg/180*Math.PI;
+    this.vx = Math.cos(angleRad);
+    this.vy = -Math.sin(angleRad);
+  }
+  setSpeed(s)
+  {
+    this.vx *= s;
+    this.vy *= s;
+  }
+  hide()
+  {
+    this.element.style.visibility = "hidden";
+  }
+  show()
+  {
+    this.element.style.visibility = "visible";
+  }
   update()
   {
     this.vx = this.vx + this.ax;
@@ -60,9 +79,15 @@
       b.setPosition(x*36+20, 20+y*32);
     else
       b.setPosition(x*36+20+18, 20+y*32);
+    b.hide();
     balls.push(b)
   }
 
+var fire = new Ball(width, height);
+fire.setPosition(width/2, height-50);
+fire.setAngle(45);
+fire.setSpeed(5);
+balls.push(fire);
 setInterval(() => 
 {
   for (var i=0; i<balls.length; i++)
```

## Diff 10 vs 09

 - [clean10/index.html](clean10/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean10/index.html)

```diff
--- ../clean09/index.html	2022-04-21 22:33:05.000000000 +0200
+++ ../clean10/index.html	2022-04-21 22:40:47.000000000 +0200
@@ -40,6 +40,10 @@
     this.vx *= s;
     this.vy *= s;
   }
+  isFire()
+  {
+    return this.vx != 0 || this.vy != 0;
+  }
   hide()
   {
     this.element.style.visibility = "hidden";
@@ -48,7 +52,39 @@
   {
     this.element.style.visibility = "visible";
   }
-  update()
+  isHidden()
+  {
+    return this.element.style.visibility == "hidden";
+  }
+  distance(b)
+  {
+    return Math.sqrt((this.x-b.x)**2 + (this.y-b.y)**2);
+  }
+  getColor(c)
+  {
+    return this.element.src;
+  }
+  setColor(c)
+  {
+    this.element.src = c;
+  }
+  hit(balls)
+  {
+    var besti = -1;
+    for (var i=0; i<balls.length; i++)
+      if (balls[i].isHidden())
+      {
+        if (besti == -1 || 
+            this.distance(balls[i]) < this.distance(balls[besti]))
+          besti = i;
+      }
+    if (besti != -1)
+    {
+      balls[besti].show();
+      balls[besti].setColor(this.getColor());
+    }
+  }
+  update(balls)
   {
     this.vx = this.vx + this.ax;
     this.vy = this.vy + this.ay;
@@ -60,7 +96,13 @@
     if (this.x > this.width-20)
       this.vx = -Math.abs(this.vx);
     if (this.y < 20)
+    {
       this.vy = Math.abs(this.vy);
+      if (this.isFire())
+      {
+        this.hit(balls);
+      }
+    }
     if (this.y > this.height-20)
       this.vy = -Math.abs(this.vy);
 
@@ -91,7 +133,7 @@
 setInterval(() => 
 {
   for (var i=0; i<balls.length; i++)
-    balls[i].update();
+    balls[i].update(balls);
 }, 10);
 </script>
 </html>
\ No newline at end of file
```

## Diff 11 vs 10

 - [clean11/index.html](clean11/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean11/index.html)

```diff
--- ../clean10/index.html	2022-04-21 22:40:47.000000000 +0200
+++ ../clean11/index.html	2022-05-14 09:09:00.000000000 +0200
@@ -56,6 +56,10 @@
   {
     return this.element.style.visibility == "hidden";
   }
+  isVisible()
+  {
+    return !this.isHidden();
+  }
   distance(b)
   {
     return Math.sqrt((this.x-b.x)**2 + (this.y-b.y)**2);
@@ -68,6 +72,10 @@
   {
     this.element.src = c;
   }
+  randomColor()
+  {
+    this.element.src = ["red.png", "green.png", "blue.png"][Math.floor(Math.random()*3)];
+  }
   hit(balls)
   {
     var besti = -1;
@@ -86,6 +94,21 @@
   }
   update(balls)
   {
+    if (this.isFire())
+    {
+      for (var i=0; i<balls.length; i++)
+        if (!balls[i].isFire() && 
+            balls[i].isVisible() &&
+            this.distance(balls[i]) < 40)
+        {
+          this.hit(balls);
+          this.setPosition(this.width/2, this.height-40);
+          this.setAngle(20+Math.random()*140);
+          this.setSpeed(5);
+          this.randomColor();
+          break;
+        }
+    }
     this.vx = this.vx + this.ax;
     this.vy = this.vy + this.ay;
     this.x = this.x + this.vx;
@@ -101,6 +124,10 @@
       if (this.isFire())
       {
         this.hit(balls);
+        this.setPosition(this.width/2, this.height-40);
+        this.setAngle(20+Math.random()*140);
+        this.setSpeed(5);
+        this.randomColor();
       }
     }
     if (this.y > this.height-20)
```

## Diff 12 vs 11

 - [clean12/index.html](clean12/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean12/index.html)

```diff
--- ../clean11/index.html	2022-05-14 09:09:00.000000000 +0200
+++ ../clean12/index.html	2022-04-21 23:03:00.000000000 +0200
@@ -76,6 +76,19 @@
   {
     this.element.src = ["red.png", "green.png", "blue.png"][Math.floor(Math.random()*3)];
   }
+  nearbyBalls(balls)
+  {
+    var aux = [];
+    for (var i=0; i<balls.length; i++)
+      if (balls[i].isVisible() && !balls[i].isFire() && 
+          balls[i].element != this.element && 
+          balls[i].distance(this) < 40)
+      {
+        aux.push(balls[i]);
+      }
+    return aux;
+  }
+
   hit(balls)
   {
     var besti = -1;
@@ -86,12 +99,30 @@
             this.distance(balls[i]) < this.distance(balls[besti]))
           besti = i;
       }
-    if (besti != -1)
+
+    if (besti == -1)
+      return;
+
+    balls[besti].show();
+    balls[besti].setColor(this.getColor());
+
+    var process = [balls[besti]];
+    var matching = [];
+    while (process.length > 0)
     {
-      balls[besti].show();
-      balls[besti].setColor(this.getColor());
+      var b = process.shift();
+      matching.push(b);
+      var nearby = b.nearbyBalls(balls);
+      for (var i=0; i<nearby.length; i++)
+        if (nearby[i].getColor() == this.getColor())
+        {
+          if (matching.indexOf(nearby[i]) == -1)
+            process.push(nearby[i]);
+        }
     }
+    console.log(matching.length);
   }
+
   update(balls)
   {
     if (this.isFire())
```

## Diff 13 vs 12

 - [clean13/index.html](clean13/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean13/index.html)

```diff
--- ../clean12/index.html	2022-04-21 23:03:00.000000000 +0200
+++ ../clean13/index.html	2022-04-21 23:17:55.000000000 +0200
@@ -88,6 +88,18 @@
       }
     return aux;
   }
+  topBalls(balls)
+  {
+    var aux = [];
+    for (var i=0; i<balls.length; i++)
+      if (balls[i].isVisible() && !balls[i].isFire() && 
+          balls[i].element != this.element && 
+          balls[i].y < 30)
+      {
+        aux.push(balls[i]);
+      }
+    return aux;
+  }
 
   hit(balls)
   {
@@ -120,7 +132,32 @@
             process.push(nearby[i]);
         }
     }
-    console.log(matching.length);
+
+    if (matching.length >= 3)
+    {
+      for (var i=0; i<matching.length; i++)
+        matching[i].hide();
+
+      var process = this.topBalls(balls);
+      var hanging = [];
+      while (process.length > 0)
+      {
+        var b = process.shift();
+        hanging.push(b);
+        var nearby = b.nearbyBalls(balls);
+        for (var i=0; i<nearby.length; i++)
+        {
+          if (hanging.indexOf(nearby[i]) == -1)
+            process.push(nearby[i]);
+        }
+      }
+
+      for (var i=0; i<balls.length; i++)
+      {
+        if (hanging.indexOf(balls[i]) == -1 && !balls[i].isFire())
+          balls[i].hide();
+      }
+    }
   }
 
   update(balls)
```

## Diff 14 vs 13

 - [clean14/index.html](clean14/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean14/index.html)

```diff
--- ../clean13/index.html	2022-04-21 23:17:55.000000000 +0200
+++ ../clean14/index.html	2022-04-22 09:52:04.000000000 +0200
@@ -44,6 +44,10 @@
   {
     return this.vx != 0 || this.vy != 0;
   }
+  isFalling()
+  {
+    return this.ay != 0;
+  }
   hide()
   {
     this.element.style.visibility = "hidden";
@@ -80,7 +84,7 @@
   {
     var aux = [];
     for (var i=0; i<balls.length; i++)
-      if (balls[i].isVisible() && !balls[i].isFire() && 
+      if (balls[i].isVisible() && !balls[i].isFire() && !balls[i].isFalling() &&
           balls[i].element != this.element && 
           balls[i].distance(this) < 40)
       {
@@ -92,7 +96,7 @@
   {
     var aux = [];
     for (var i=0; i<balls.length; i++)
-      if (balls[i].isVisible() && !balls[i].isFire() && 
+      if (balls[i].isVisible() && !balls[i].isFire() && !balls[i].isFalling() &&
           balls[i].element != this.element && 
           balls[i].y < 30)
       {
@@ -154,15 +158,31 @@
 
       for (var i=0; i<balls.length; i++)
       {
-        if (hanging.indexOf(balls[i]) == -1 && !balls[i].isFire())
-          balls[i].hide();
+        if (balls[i].isVisible() && 
+            hanging.indexOf(balls[i]) == -1 && !balls[i].isFire())
+          matching.push(balls[i]);
       }
+
+      this.explode(balls, matching);
+    }
+  }
+
+  explode(balls, expl)
+  {
+    for (var i=0; i<expl.length; i++)
+    {
+      expl[i].hide();
+      var b = new Ball(this.width, this.height);
+      b.setColor(expl[i].getColor());
+      b.setPosition(expl[i].x, expl[i].y);
+      b.ay = 0.1;
+      balls.push(b);
     }
   }
 
   update(balls)
   {
-    if (this.isFire())
+    if (this.isFire() && !this.isFalling())
     {
       for (var i=0; i<balls.length; i++)
         if (!balls[i].isFire() && 
@@ -189,7 +209,7 @@
     if (this.y < 20)
     {
       this.vy = Math.abs(this.vy);
-      if (this.isFire())
+      if (!this.isFalling() && this.isFire())
       {
         this.hit(balls);
         this.setPosition(this.width/2, this.height-40);
@@ -199,11 +219,23 @@
       }
     }
     if (this.y > this.height-20)
+    {
+      if (this.isFalling())
+      {
+        this.destroy();
+        return;
+      }
       this.vy = -Math.abs(this.vy);
+    }
 
     this.element.style.left = this.x-20;
     this.element.style.top = this.y-20;
   }
+  destroy()
+  {
+    document.querySelector("#game").removeChild(this.element);
+    delete this.element;
+  }
 }
 
 var balls = []; 
@@ -227,6 +259,7 @@
 balls.push(fire);
 setInterval(() => 
 {
+  balls = balls.filter(b => b.element);
   for (var i=0; i<balls.length; i++)
     balls[i].update(balls);
 }, 10);
```

## Diff 15 vs 14

 - [clean15/index.html](clean15/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean15/index.html)

```diff
```

## Diff 16 vs 15

 - [clean16/index.html](clean16/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean16/index.html)

```diff
--- ../clean15/index.html	2022-04-22 10:52:04.000000000 +0200
+++ ../clean16/index.html	2022-04-26 22:05:26.000000000 +0200
@@ -169,12 +169,26 @@
 
   explode(balls, expl)
   {
+    var sumx = 0, sumy = 0;
     for (var i=0; i<expl.length; i++)
     {
+      sumx += expl[i].x;
+      sumy += expl[i].y;
+    }
+    sumx /= expl.length;
+    sumy /= expl.length;
+
+    for (var i=0; i<expl.length; i++)
+    {
+      var vectx = expl[i].x - sumx;
+      var vecty = expl[i].y - sumy;
+      var angle = Math.atan2(vecty, vectx) / Math.PI * 180;
+
       expl[i].hide();
       var b = new Ball(this.width, this.height);
       b.setColor(expl[i].getColor());
       b.setPosition(expl[i].x, expl[i].y);
+      b.setAngle(angle);
       b.ay = 0.1;
       balls.push(b);
     }
```

## Diff 17 vs 16

 - [clean17/index.html](clean17/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean17/index.html)

```diff
--- ../clean16/index.html	2022-04-26 22:05:26.000000000 +0200
+++ ../clean17/index.html	2022-04-27 16:43:39.000000000 +0200
@@ -1,7 +1,7 @@
 <html>
 <div id="game" style="width:400px; height:600px; border:1px solid #d0d0d0; position:relative; background:url(background1.jpg); overflow:hidden;">
 </div>
-
+<script src="controls.js"></script>
 <script>
 var element = document.querySelector("#game");
 var width = parseInt(this.element.style.width);
@@ -262,7 +262,11 @@
       b.setPosition(x*36+20, 20+y*32);
     else
       b.setPosition(x*36+20+18, 20+y*32);
-    b.hide();
+
+    if (y<5)
+      b.show();
+    else
+      b.hide();
     balls.push(b)
   }
 
@@ -271,11 +275,37 @@
 fire.setAngle(45);
 fire.setSpeed(5);
 balls.push(fire);
+
 setInterval(() => 
 {
   balls = balls.filter(b => b.element);
   for (var i=0; i<balls.length; i++)
     balls[i].update(balls);
 }, 10);
+
+
+class Handler
+{
+  onKeyLeft(b) 
+  { 
+    console.log("left", b); 
+  }
+  onKeyRight(b)
+  { 
+    console.log("right", b); 
+  }
+  onKeyFire(b)
+  { 
+    console.log("fire", b); 
+  }
+  onMouse(pt) 
+  {
+    console.log("mouse", pt);
+  }
+}
+
+var handler = new Handler();
+new Controls(document.querySelector("#game"), handler);
+
 </script>
 </html>
\ No newline at end of file
```

## Diff 18 vs 17

 - [clean18/index.html](clean18/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean18/index.html)

```diff
--- ../clean17/index.html	2022-04-27 16:43:39.000000000 +0200
+++ ../clean18/index.html	2022-04-27 16:50:55.000000000 +0200
@@ -3,10 +3,6 @@
 </div>
 <script src="controls.js"></script>
 <script>
-var element = document.querySelector("#game");
-var width = parseInt(this.element.style.width);
-var height = parseInt(this.element.style.height);
-
 class Ball
 {
   constructor(width, height)
@@ -252,40 +248,50 @@
   }
 }
 
-var balls = []; 
-
-for (var y=0; y<18; y++)
-  for (var x=0; x<11-(y%2); x++)
+class Game
+{
+  constructor()
   {
-    var b = new Ball(width, height);
-    if (y%2==0)
-      b.setPosition(x*36+20, 20+y*32);
-    else
-      b.setPosition(x*36+20+18, 20+y*32);
-
-    if (y<5)
-      b.show();
-    else
-      b.hide();
-    balls.push(b)
-  }
-
-var fire = new Ball(width, height);
-fire.setPosition(width/2, height-50);
-fire.setAngle(45);
-fire.setSpeed(5);
-balls.push(fire);
+    this.balls = [];
+    var element = document.querySelector("#game");
+    this.width = parseInt(element.style.width);
+    this.height = parseInt(element.style.height);
 
-setInterval(() => 
-{
-  balls = balls.filter(b => b.element);
-  for (var i=0; i<balls.length; i++)
-    balls[i].update(balls);
-}, 10);
+    for (var y=0; y<18; y++)
+      for (var x=0; x<11-(y%2); x++)
+      {
+        var b = new Ball(this.width, this.height);
+        if (y%2==0)
+          b.setPosition(x*36+20, 20+y*32);
+        else
+          b.setPosition(x*36+20+18, 20+y*32);
+
+        if (y<5)
+          b.show();
+        else
+          b.hide();
+        this.balls.push(b)
+      }
 
+    var fire = new Ball(this.width, this.height);
+    fire.setPosition(this.width/2, this.height-50);
+    fire.setAngle(45);
+    fire.setSpeed(5);
+    this.balls.push(fire);
+
+    setInterval(() => 
+    {
+      this.update()
+    }, 10);
+  }
+
+  update()
+  {
+    this.balls = this.balls.filter(b => b.element);
+    for (var i=0; i<this.balls.length; i++)
+      this.balls[i].update(this.balls);
+  }
 
-class Handler
-{
   onKeyLeft(b) 
   { 
     console.log("left", b); 
@@ -304,8 +310,8 @@
   }
 }
 
-var handler = new Handler();
-new Controls(document.querySelector("#game"), handler);
+var game = new Game();
+new Controls(document.querySelector("#game"), game);
 
 </script>
 </html>
\ No newline at end of file
```

## Diff 19 vs 18

 - [clean19/index.html](clean19/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean19/index.html)

```diff
--- ../clean18/index.html	2022-04-27 16:50:55.000000000 +0200
+++ ../clean19/index.html	2022-04-27 16:54:41.000000000 +0200
@@ -273,11 +273,13 @@
         this.balls.push(b)
       }
 
-    var fire = new Ball(this.width, this.height);
-    fire.setPosition(this.width/2, this.height-50);
-    fire.setAngle(45);
-    fire.setSpeed(5);
-    this.balls.push(fire);
+    this.fire = new Ball(this.width, this.height);
+    this.fire.setPosition(this.width/2, this.height-50);
+    this.balls.push(this.fire);
+
+    this.cannon = new Ball(this.width, this.height);
+    this.cannon.setPosition(this.width/2, this.height-50);
+    this.cannon.show();
 
     setInterval(() => 
     {
@@ -290,6 +292,7 @@
     this.balls = this.balls.filter(b => b.element);
     for (var i=0; i<this.balls.length; i++)
       this.balls[i].update(this.balls);
+    this.cannon.update();
   }
 
   onKeyLeft(b) 
@@ -303,6 +306,11 @@
   onKeyFire(b)
   { 
     console.log("fire", b); 
+    if (b)
+    {
+      this.fire.setAngle(45);
+      this.fire.setSpeed(5);
+    }
   }
   onMouse(pt) 
   {
```

## Diff 20 vs 19

 - [clean20/index.html](clean20/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean20/index.html)

```diff
--- ../clean19/index.html	2022-04-27 16:54:41.000000000 +0200
+++ ../clean20/index.html	2022-04-27 17:38:51.000000000 +0200
@@ -51,6 +51,8 @@
   show()
   {
     this.element.style.visibility = "visible";
+    this.element.style.left = this.x-20;
+    this.element.style.top = this.y-20;
   }
   isHidden()
   {
@@ -80,7 +82,7 @@
   {
     var aux = [];
     for (var i=0; i<balls.length; i++)
-      if (balls[i].isVisible() && !balls[i].isFire() && !balls[i].isFalling() &&
+      if (balls[i].element && balls[i].isVisible() && !balls[i].isFire() && !balls[i].isFalling() &&
           balls[i].element != this.element && 
           balls[i].distance(this) < 40)
       {
@@ -92,7 +94,7 @@
   {
     var aux = [];
     for (var i=0; i<balls.length; i++)
-      if (balls[i].isVisible() && !balls[i].isFire() && !balls[i].isFalling() &&
+      if (balls[i].element && balls[i].isVisible() && !balls[i].isFire() && !balls[i].isFalling() &&
           balls[i].element != this.element && 
           balls[i].y < 30)
       {
@@ -105,7 +107,7 @@
   {
     var besti = -1;
     for (var i=0; i<balls.length; i++)
-      if (balls[i].isHidden())
+      if (balls[i].element && balls[i].isHidden())
       {
         if (besti == -1 || 
             this.distance(balls[i]) < this.distance(balls[besti]))
@@ -154,7 +156,7 @@
 
       for (var i=0; i<balls.length; i++)
       {
-        if (balls[i].isVisible() && 
+        if (balls[i].element && balls[i].isVisible() && 
             hanging.indexOf(balls[i]) == -1 && !balls[i].isFire())
           matching.push(balls[i]);
       }
@@ -195,16 +197,19 @@
     if (this.isFire() && !this.isFalling())
     {
       for (var i=0; i<balls.length; i++)
-        if (!balls[i].isFire() && 
+        if (balls[i].element && !balls[i].isFire() && 
             balls[i].isVisible() &&
             this.distance(balls[i]) < 40)
         {
           this.hit(balls);
+/*
           this.setPosition(this.width/2, this.height-40);
           this.setAngle(20+Math.random()*140);
           this.setSpeed(5);
           this.randomColor();
-          break;
+*/
+          this.destroy();
+          return;
         }
     }
     this.vx = this.vx + this.ax;
@@ -222,10 +227,14 @@
       if (!this.isFalling() && this.isFire())
       {
         this.hit(balls);
+        this.destroy();
+        return;
+/*
         this.setPosition(this.width/2, this.height-40);
         this.setAngle(20+Math.random()*140);
         this.setSpeed(5);
         this.randomColor();
+*/
       }
     }
     if (this.y > this.height-20)
@@ -273,10 +282,6 @@
         this.balls.push(b)
       }
 
-    this.fire = new Ball(this.width, this.height);
-    this.fire.setPosition(this.width/2, this.height-50);
-    this.balls.push(this.fire);
-
     this.cannon = new Ball(this.width, this.height);
     this.cannon.setPosition(this.width/2, this.height-50);
     this.cannon.show();
@@ -308,8 +313,12 @@
     console.log("fire", b); 
     if (b)
     {
+      this.fire = new Ball(this.width, this.height);
+      this.fire.setPosition(this.width/2, this.height-50);
       this.fire.setAngle(45);
       this.fire.setSpeed(5);
+      this.fire.show();
+      this.balls.push(this.fire);
     }
   }
   onMouse(pt) 
```

## Diff 21 vs 20

 - [clean21/index.html](clean21/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean21/index.html)

```diff
--- ../clean20/index.html	2022-04-27 17:38:51.000000000 +0200
+++ ../clean21/index.html	2022-04-27 18:22:28.000000000 +0200
@@ -286,12 +286,26 @@
     this.cannon.setPosition(this.width/2, this.height-50);
     this.cannon.show();
 
+    this.angle = 90;
+    this.arrow = document.createElement("img");
+    this.arrow.setAttribute("src", "arrow.png");
+    this.arrow.setAttribute("style", "position:absolute");
+    this.arrow.style.left = this.width/2;
+    this.arrow.style.top = this.height-50;
+    document.querySelector("#game").appendChild(this.arrow);
+    this.updateArrow();
+    // zacat: "rotate(45deg)"
+    //translate(-23px, -20px) rotate(315deg) translate(22px, 0px)
+
     setInterval(() => 
     {
       this.update()
     }, 10);
   }
-
+  updateArrow()
+  {
+    this.arrow.style.transform = "translate(-24px, -20px) rotate(-"+this.angle+"deg) translate(20px, 0px)"
+  }
   update()
   {
     this.balls = this.balls.filter(b => b.element);
```

## Diff 22 vs 21

 - [clean22/index.html](clean22/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean22/index.html)

```diff
--- ../clean21/index.html	2022-04-27 18:22:28.000000000 +0200
+++ ../clean22/index.html	2022-04-27 18:32:17.000000000 +0200
@@ -282,10 +282,8 @@
         this.balls.push(b)
       }
 
-    this.cannon = new Ball(this.width, this.height);
-    this.cannon.setPosition(this.width/2, this.height-50);
-    this.cannon.show();
-
+    this.left = false;
+    this.right = false;
     this.angle = 90;
     this.arrow = document.createElement("img");
     this.arrow.setAttribute("src", "arrow.png");
@@ -297,6 +295,10 @@
     // zacat: "rotate(45deg)"
     //translate(-23px, -20px) rotate(315deg) translate(22px, 0px)
 
+    this.cannon = new Ball(this.width, this.height);
+    this.cannon.setPosition(this.width/2, this.height-50);
+    this.cannon.show();
+
     setInterval(() => 
     {
       this.update()
@@ -308,6 +310,12 @@
   }
   update()
   {
+    if (this.left && this.angle < 160)
+      this.angle = this.angle + 1;
+    if (this.right && this.angle > 20)
+      this.angle = this.angle - 1;
+    this.updateArrow();
+
     this.balls = this.balls.filter(b => b.element);
     for (var i=0; i<this.balls.length; i++)
       this.balls[i].update(this.balls);
@@ -316,11 +324,11 @@
 
   onKeyLeft(b) 
   { 
-    console.log("left", b); 
+    this.left = b;
   }
   onKeyRight(b)
   { 
-    console.log("right", b); 
+    this.right = b;
   }
   onKeyFire(b)
   { 
@@ -328,11 +336,13 @@
     if (b)
     {
       this.fire = new Ball(this.width, this.height);
+      this.fire.setColor(this.cannon.getColor());
       this.fire.setPosition(this.width/2, this.height-50);
-      this.fire.setAngle(45);
+      this.fire.setAngle(this.angle);
       this.fire.setSpeed(5);
       this.fire.show();
       this.balls.push(this.fire);
+      this.cannon.randomColor();
     }
   }
   onMouse(pt) 
```

## Diff 23 vs 22

 - [clean23/index.html](clean23/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean23/index.html)

```diff
--- ../clean22/index.html	2022-04-27 18:32:17.000000000 +0200
+++ ../clean23/index.html	2022-04-28 09:51:46.000000000 +0200
@@ -202,12 +202,6 @@
             this.distance(balls[i]) < 40)
         {
           this.hit(balls);
-/*
-          this.setPosition(this.width/2, this.height-40);
-          this.setAngle(20+Math.random()*140);
-          this.setSpeed(5);
-          this.randomColor();
-*/
           this.destroy();
           return;
         }
@@ -229,12 +223,6 @@
         this.hit(balls);
         this.destroy();
         return;
-/*
-        this.setPosition(this.width/2, this.height-40);
-        this.setAngle(20+Math.random()*140);
-        this.setSpeed(5);
-        this.randomColor();
-*/
       }
     }
     if (this.y > this.height-20)
@@ -332,7 +320,6 @@
   }
   onKeyFire(b)
   { 
-    console.log("fire", b); 
     if (b)
     {
       this.fire = new Ball(this.width, this.height);
@@ -347,7 +334,10 @@
   }
   onMouse(pt) 
   {
-    console.log("mouse", pt);
+    var vx = pt.x - this.cannon.x;
+    var vy = pt.y - this.cannon.y;
+    this.angle = Math.floor(Math.atan2(-vy, vx) * 180 / Math.PI);
+    this.onKeyFire(true);
   }
 }
 
```

## Diff 24 vs 23

 - [clean24/index.html](clean24/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean24/index.html)

```diff
--- ../clean23/index.html	2022-04-28 09:51:46.000000000 +0200
+++ ../clean24/index.html	2022-04-28 10:00:54.000000000 +0200
@@ -157,11 +157,19 @@
       for (var i=0; i<balls.length; i++)
       {
         if (balls[i].element && balls[i].isVisible() && 
-            hanging.indexOf(balls[i]) == -1 && !balls[i].isFire())
+            hanging.indexOf(balls[i]) == -1 && !balls[i].isFire() && !balls[i].isFalling())
           matching.push(balls[i]);
       }
 
       this.explode(balls, matching);
+
+      var remaining = 0;
+      for (var i=0; i<balls.length; i++)
+      {
+        if (balls[i].element && balls[i].isVisible() && !balls[i].isFire() && !balls[i].isFalling())
+          remaining = remaining + 1;
+      }
+      console.log("Ostava ", remaining, "guliciek");
     }
   }
 
```

## Diff 25 vs 24

 - [clean25/index.html](clean25/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean25/index.html)

```diff
--- ../clean24/index.html	2022-04-28 10:00:54.000000000 +0200
+++ ../clean25/index.html	2022-04-28 10:10:42.000000000 +0200
@@ -337,7 +337,12 @@
       this.fire.setSpeed(5);
       this.fire.show();
       this.balls.push(this.fire);
-      this.cannon.randomColor();
+
+      var colors = this.balls.filter(b=>b.isVisible() && !b.isFire() && !b.isFalling())
+        .map(b=>b.getColor());
+      colors = colors.filter((v, i, a) => a.indexOf(v) === i);
+      var rcolor = colors[Math.floor(Math.random()*colors.length)];
+      this.cannon.setColor(rcolor);
     }
   }
   onMouse(pt) 
```

## Diff 26 vs 25

 - [clean26/index.html](clean26/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean26/index.html)

```diff
--- ../clean25/index.html	2022-04-28 10:10:42.000000000 +0200
+++ ../clean26/index.html	2022-04-28 11:38:42.000000000 +0200
@@ -170,6 +170,10 @@
           remaining = remaining + 1;
       }
       console.log("Ostava ", remaining, "guliciek");
+      if (remaining == 0)
+      {
+        console.log("Vyhral !");
+      }
     }
   }
 
@@ -200,19 +204,25 @@
     }
   }
 
-  update(balls)
+  checkHit(balls)
   {
-    if (this.isFire() && !this.isFalling())
-    {
       for (var i=0; i<balls.length; i++)
         if (balls[i].element && !balls[i].isFire() && 
             balls[i].isVisible() &&
             this.distance(balls[i]) < 40)
         {
-          this.hit(balls);
-          this.destroy();
-          return;
+          return true;
         }
+    return false;
+  }
+
+  update(balls)
+  {
+    if (this.isFire() && !this.isFalling() && this.checkHit(balls))
+    {
+      this.hit(balls);
+      this.destroy();
+      return;
     }
     this.vx = this.vx + this.ax;
     this.vy = this.vy + this.ay;
@@ -338,7 +348,13 @@
       this.fire.show();
       this.balls.push(this.fire);
 
-      var colors = this.balls.filter(b=>b.isVisible() && !b.isFire() && !b.isFalling())
+      if (this.fire.checkHit(this.balls))
+      {
+        this.fire.destroy();
+        console.log("Prehral!");
+      }
+
+      var colors = this.balls.filter(b=>b.element && b.isVisible() && !b.isFire() && !b.isFalling())
         .map(b=>b.getColor());
       colors = colors.filter((v, i, a) => a.indexOf(v) === i);
       var rcolor = colors[Math.floor(Math.random()*colors.length)];
```

## Diff 27 vs 26

 - [clean27/index.html](clean27/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean27/index.html)

```diff
--- ../clean26/index.html	2022-04-28 11:38:42.000000000 +0200
+++ ../clean27/index.html	2022-04-28 12:53:46.000000000 +0200
@@ -1,6 +1,15 @@
 <html>
 <div id="game" style="width:400px; height:600px; border:1px solid #d0d0d0; position:relative; background:url(background1.jpg); overflow:hidden;">
+  <div id="loser" class="wave" style="visibility:hidden">
+   <span style="--i:1">L</span>
+   <span style="--i:2">o</span>
+   <span style="--i:3">s</span>
+   <span style="--i:4">e</span>
+   <span style="--i:5">r</span>
+   <span style="--i:6">!</span>
+  </div>
 </div>
+<link rel="stylesheet" href="wave.css">
 <script src="controls.js"></script>
 <script>
 class Ball
@@ -268,25 +277,7 @@
   constructor()
   {
     this.balls = [];
-    var element = document.querySelector("#game");
-    this.width = parseInt(element.style.width);
-    this.height = parseInt(element.style.height);
-
-    for (var y=0; y<18; y++)
-      for (var x=0; x<11-(y%2); x++)
-      {
-        var b = new Ball(this.width, this.height);
-        if (y%2==0)
-          b.setPosition(x*36+20, 20+y*32);
-        else
-          b.setPosition(x*36+20+18, 20+y*32);
-
-        if (y<5)
-          b.show();
-        else
-          b.hide();
-        this.balls.push(b)
-      }
+    this.restart();
 
     this.left = false;
     this.right = false;
@@ -310,6 +301,32 @@
       this.update()
     }, 10);
   }
+  restart()
+  {
+    for (var i=0; i<this.balls.length; i++)
+      this.balls[i].destroy();
+    this.balls = [];
+
+    var element = document.querySelector("#game");
+    this.width = parseInt(element.style.width);
+    this.height = parseInt(element.style.height);
+
+    for (var y=0; y<18; y++)
+      for (var x=0; x<11-(y%2); x++)
+      {
+        var b = new Ball(this.width, this.height);
+        if (y%2==0)
+          b.setPosition(x*36+20, 20+y*32);
+        else
+          b.setPosition(x*36+20+18, 20+y*32);
+
+        if (y<5)
+          b.show();
+        else
+          b.hide();
+        this.balls.push(b)
+      }
+  }
   updateArrow()
   {
     this.arrow.style.transform = "translate(-24px, -20px) rotate(-"+this.angle+"deg) translate(20px, 0px)"
@@ -352,6 +369,7 @@
       {
         this.fire.destroy();
         console.log("Prehral!");
+        this.onLose();
       }
 
       var colors = this.balls.filter(b=>b.element && b.isVisible() && !b.isFire() && !b.isFalling())
@@ -368,6 +386,21 @@
     this.angle = Math.floor(Math.atan2(-vy, vx) * 180 / Math.PI);
     this.onKeyFire(true);
   }
+
+  onLose()
+  {
+   document.querySelector("#loser").style.visibility = "visible";
+   setTimeout(()=>
+   {
+     this.onContinue();
+   }, 5000);
+  }
+
+  onContinue()
+  {
+   document.querySelector("#loser").style.visibility = "hidden";
+   this.restart();
+  }
 }
 
 var game = new Game();
```

## Diff 28 vs 27

 - [clean28/index.html](clean28/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean28/index.html)

```diff
--- ../clean27/index.html	2022-04-28 12:53:46.000000000 +0200
+++ ../clean28/index.html	2022-04-29 11:33:00.000000000 +0200
@@ -8,16 +8,25 @@
    <span style="--i:5">r</span>
    <span style="--i:6">!</span>
   </div>
+  <div id="winner" class="wave" style="visibility:hidden">
+   <span style="--i:1">W</span>
+   <span style="--i:2">i</span>
+   <span style="--i:3">n</span>
+   <span style="--i:4">n</span>
+   <span style="--i:5">e</span>
+   <span style="--i:6">r</span>
+  </div>
 </div>
 <link rel="stylesheet" href="wave.css">
 <script src="controls.js"></script>
 <script>
 class Ball
 {
-  constructor(width, height)
+  constructor(game)
   {
-    this.width = width;
-    this.height = height;
+    this.game = game;
+    this.width = game.width;
+    this.height = game.height;
     this.element = document.createElement("img");
     this.element.src = ["red.png", "green.png", "blue.png"][Math.floor(Math.random()*3)];
     this.element.setAttribute("style", "position:absolute");
@@ -182,6 +191,7 @@
       if (remaining == 0)
       {
         console.log("Vyhral !");
+        this.game.onWin();
       }
     }
   }
@@ -204,7 +214,7 @@
       var angle = Math.atan2(vecty, vectx) / Math.PI * 180;
 
       expl[i].hide();
-      var b = new Ball(this.width, this.height);
+      var b = new Ball(this);
       b.setColor(expl[i].getColor());
       b.setPosition(expl[i].x, expl[i].y);
       b.setAngle(angle);
@@ -292,7 +302,7 @@
     // zacat: "rotate(45deg)"
     //translate(-23px, -20px) rotate(315deg) translate(22px, 0px)
 
-    this.cannon = new Ball(this.width, this.height);
+    this.cannon = new Ball(this);
     this.cannon.setPosition(this.width/2, this.height-50);
     this.cannon.show();
 
@@ -314,7 +324,7 @@
     for (var y=0; y<18; y++)
       for (var x=0; x<11-(y%2); x++)
       {
-        var b = new Ball(this.width, this.height);
+        var b = new Ball(this);
         if (y%2==0)
           b.setPosition(x*36+20, 20+y*32);
         else
@@ -326,6 +336,7 @@
           b.hide();
         this.balls.push(b)
       }
+    this.playing = true;
   }
   updateArrow()
   {
@@ -355,9 +366,11 @@
   }
   onKeyFire(b)
   { 
+    if (!this.playing)
+      return;
     if (b)
     {
-      this.fire = new Ball(this.width, this.height);
+      this.fire = new Ball(this);
       this.fire.setColor(this.cannon.getColor());
       this.fire.setPosition(this.width/2, this.height-50);
       this.fire.setAngle(this.angle);
@@ -389,6 +402,10 @@
 
   onLose()
   {
+   if (!this.playing)
+     return;
+   this.playing = false;
+
    document.querySelector("#loser").style.visibility = "visible";
    setTimeout(()=>
    {
@@ -396,9 +413,23 @@
    }, 5000);
   }
 
+  onWin()
+  {
+   if (!this.playing)
+     return;
+   this.playing = false;
+
+   document.querySelector("#winner").style.visibility = "visible";
+   setTimeout(()=>
+   {
+     this.onContinue();
+   }, 5000);
+  }
+
   onContinue()
   {
    document.querySelector("#loser").style.visibility = "hidden";
+   document.querySelector("#winner").style.visibility = "hidden";
    this.restart();
   }
 }
```

## Diff 29 vs 28

 - [clean29/index.html](clean29/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean29/index.html)

```diff
--- ../clean28/index.html	2022-04-29 11:33:00.000000000 +0200
+++ ../clean29/index.html	2022-04-29 11:43:25.000000000 +0200
@@ -287,7 +287,10 @@
   constructor()
   {
     this.balls = [];
-    this.restart();
+//    this.restart();
+    var element = document.querySelector("#game");
+    this.width = parseInt(element.style.width);
+    this.height = parseInt(element.style.height);
 
     this.left = false;
     this.right = false;
@@ -311,16 +314,13 @@
       this.update()
     }, 10);
   }
+
   restart()
   {
     for (var i=0; i<this.balls.length; i++)
       this.balls[i].destroy();
     this.balls = [];
 
-    var element = document.querySelector("#game");
-    this.width = parseInt(element.style.width);
-    this.height = parseInt(element.style.height);
-
     for (var y=0; y<18; y++)
       for (var x=0; x<11-(y%2); x++)
       {
@@ -336,7 +336,6 @@
           b.hide();
         this.balls.push(b)
       }
-    this.playing = true;
   }
   updateArrow()
   {
@@ -366,8 +365,6 @@
   }
   onKeyFire(b)
   { 
-    if (!this.playing)
-      return;
     if (b)
     {
       this.fire = new Ball(this);
@@ -399,6 +396,16 @@
     this.angle = Math.floor(Math.atan2(-vy, vx) * 180 / Math.PI);
     this.onKeyFire(true);
   }
+}
+
+class GameController extends Game
+{
+  constructor()
+  {
+    super();
+    this.playing = true;
+    this.restart();
+  }
 
   onLose()
   {
@@ -430,11 +437,12 @@
   {
    document.querySelector("#loser").style.visibility = "hidden";
    document.querySelector("#winner").style.visibility = "hidden";
+   this.playing = false;
    this.restart();
   }
 }
 
-var game = new Game();
+var game = new GameController();
 new Controls(document.querySelector("#game"), game);
 
 </script>
```

## Diff 30 vs 29

 - [clean30/index.html](clean30/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean30/index.html)

```diff
--- ../clean29/index.html	2022-04-29 11:43:25.000000000 +0200
+++ ../clean30/index.html	2022-04-29 11:59:25.000000000 +0200
@@ -28,7 +28,7 @@
     this.width = game.width;
     this.height = game.height;
     this.element = document.createElement("img");
-    this.element.src = ["red.png", "green.png", "blue.png"][Math.floor(Math.random()*3)];
+    this.randomColor();
     this.element.setAttribute("style", "position:absolute");
     document.querySelector("#game").appendChild(this.element);
     this.x = 0;
@@ -94,7 +94,7 @@
   }
   randomColor()
   {
-    this.element.src = ["red.png", "green.png", "blue.png"][Math.floor(Math.random()*3)];
+    this.element.src = this.game.colors[Math.floor(Math.random()*this.game.colors.length)];
   }
   nearbyBalls(balls)
   {
@@ -214,7 +214,7 @@
       var angle = Math.atan2(vecty, vectx) / Math.PI * 180;
 
       expl[i].hide();
-      var b = new Ball(this);
+      var b = new Ball(this.game);
       b.setColor(expl[i].getColor());
       b.setPosition(expl[i].x, expl[i].y);
       b.setAngle(angle);
@@ -286,6 +286,7 @@
 {
   constructor()
   {
+    this.colors = [];
     this.balls = [];
 //    this.restart();
     var element = document.querySelector("#game");
@@ -305,18 +306,18 @@
     // zacat: "rotate(45deg)"
     //translate(-23px, -20px) rotate(315deg) translate(22px, 0px)
 
-    this.cannon = new Ball(this);
-    this.cannon.setPosition(this.width/2, this.height-50);
-    this.cannon.show();
-
     setInterval(() => 
     {
       this.update()
     }, 10);
   }
 
-  restart()
+  restart(levelconfig)
   {
+    //this.levelconfig = levelconfig;
+    this.colors = levelconfig.colors;
+    if (this.cannon)
+      this.cannon.destroy();
     for (var i=0; i<this.balls.length; i++)
       this.balls[i].destroy();
     this.balls = [];
@@ -330,12 +331,16 @@
         else
           b.setPosition(x*36+20+18, 20+y*32);
 
-        if (y<5)
+        if (y<levelconfig.rows)
           b.show();
         else
           b.hide();
         this.balls.push(b)
       }
+
+    this.cannon = new Ball(this);
+    this.cannon.setPosition(this.width/2, this.height-50);
+    this.cannon.show();
   }
   updateArrow()
   {
@@ -404,7 +409,8 @@
   {
     super();
     this.playing = true;
-    this.restart();
+    this.level = 1;
+    this.onContinue();
   }
 
   onLose()
@@ -425,7 +431,7 @@
    if (!this.playing)
      return;
    this.playing = false;
-
+   this.level = this.level + 1;
    document.querySelector("#winner").style.visibility = "visible";
    setTimeout(()=>
    {
@@ -437,8 +443,10 @@
   {
    document.querySelector("#loser").style.visibility = "hidden";
    document.querySelector("#winner").style.visibility = "hidden";
-   this.playing = false;
-   this.restart();
+   this.playing = true;
+
+   var levelconfig = {rows:3, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
+   this.restart(levelconfig);
   }
 }
 
```

## Diff 31 vs 30

 - [clean31/index.html](clean31/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean31/index.html)

```diff
--- ../clean30/index.html	2022-04-29 11:59:25.000000000 +0200
+++ ../clean31/index.html	2022-04-29 11:59:49.000000000 +0200
@@ -445,7 +445,15 @@
    document.querySelector("#winner").style.visibility = "hidden";
    this.playing = true;
 
-   var levelconfig = {rows:3, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
+   var levelconfig;
+
+   if (this.level == 1)
+     levelconfig = {rows:3, colors:["red.png", "green.png"]};
+   else if (this.level == 2)
+     levelconfig = {rows:4, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
+   else 
+     levelconfig = {rows:5, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
+
    this.restart(levelconfig);
   }
 }
```

## Diff 32 vs 31

 - [clean32/index.html](clean32/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean32/index.html)

```diff
--- ../clean31/index.html	2022-04-29 11:59:49.000000000 +0200
+++ ../clean32/index.html	2022-04-29 17:14:05.000000000 +0200
@@ -114,7 +114,7 @@
     for (var i=0; i<balls.length; i++)
       if (balls[i].element && balls[i].isVisible() && !balls[i].isFire() && !balls[i].isFalling() &&
           balls[i].element != this.element && 
-          balls[i].y < 30)
+          balls[i].y < this.game.top+30)
       {
         aux.push(balls[i]);
       }
@@ -252,7 +252,7 @@
       this.vx = Math.abs(this.vx);
     if (this.x > this.width-20)
       this.vx = -Math.abs(this.vx);
-    if (this.y < 20)
+    if (this.y < this.game.top+20)
     {
       this.vy = Math.abs(this.vy);
       if (!this.isFalling() && this.isFire())
@@ -269,6 +269,10 @@
         this.destroy();
         return;
       }
+      if (!this.isFire() && this.isVisible())
+      {
+        this.game.onLose(); // vsetko by malo vybuchnut
+      }
       this.vy = -Math.abs(this.vy);
     }
 
@@ -314,6 +318,7 @@
 
   restart(levelconfig)
   {
+    this.top = 0;
     //this.levelconfig = levelconfig;
     this.colors = levelconfig.colors;
     if (this.cannon)
@@ -356,6 +361,11 @@
 
     this.balls = this.balls.filter(b => b.element);
     for (var i=0; i<this.balls.length; i++)
+      if (!this.balls[i].isFire() && !this.balls[i].isFalling())
+        this.balls[i].y += 0.1;
+    this.top += 0.1;
+
+    for (var i=0; i<this.balls.length; i++)
       this.balls[i].update(this.balls);
     this.cannon.update();
   }
```

## Diff 33 vs 32

 - [clean33/index.html](clean33/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean33/index.html)

```diff
--- ../clean32/index.html	2022-04-29 17:14:05.000000000 +0200
+++ ../clean33/index.html	2022-04-29 17:17:11.000000000 +0200
@@ -1,5 +1,6 @@
 <html>
 <div id="game" style="width:400px; height:600px; border:1px solid #d0d0d0; position:relative; background:url(background1.jpg); overflow:hidden;">
+<img id="bar" src="bar.png" style="position:absolute;">
   <div id="loser" class="wave" style="visibility:hidden">
    <span style="--i:1">L</span>
    <span style="--i:2">o</span>
@@ -364,7 +365,8 @@
       if (!this.balls[i].isFire() && !this.balls[i].isFalling())
         this.balls[i].y += 0.1;
     this.top += 0.1;
-
+    document.querySelector("#bar").style.top = this.top-282;
+ 	
     for (var i=0; i<this.balls.length; i++)
       this.balls[i].update(this.balls);
     this.cannon.update();
```

## Diff 34 vs 33

 - [clean34/index.html](clean34/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean34/index.html)

```diff
--- ../clean33/index.html	2022-04-29 17:17:11.000000000 +0200
+++ ../clean34/index.html	2022-04-29 17:31:39.000000000 +0200
@@ -180,7 +180,7 @@
           matching.push(balls[i]);
       }
 
-      this.explode(balls, matching);
+      this.game.explode(matching);
 
       var remaining = 0;
       for (var i=0; i<balls.length; i++)
@@ -197,33 +197,6 @@
     }
   }
 
-  explode(balls, expl)
-  {
-    var sumx = 0, sumy = 0;
-    for (var i=0; i<expl.length; i++)
-    {
-      sumx += expl[i].x;
-      sumy += expl[i].y;
-    }
-    sumx /= expl.length;
-    sumy /= expl.length;
-
-    for (var i=0; i<expl.length; i++)
-    {
-      var vectx = expl[i].x - sumx;
-      var vecty = expl[i].y - sumy;
-      var angle = Math.atan2(vecty, vectx) / Math.PI * 180;
-
-      expl[i].hide();
-      var b = new Ball(this.game);
-      b.setColor(expl[i].getColor());
-      b.setPosition(expl[i].x, expl[i].y);
-      b.setAngle(angle);
-      b.ay = 0.1;
-      balls.push(b);
-    }
-  }
-
   checkHit(balls)
   {
       for (var i=0; i<balls.length; i++)
@@ -413,6 +386,33 @@
     this.angle = Math.floor(Math.atan2(-vy, vx) * 180 / Math.PI);
     this.onKeyFire(true);
   }
+
+  explode(expl)
+  {
+    var sumx = 0, sumy = 0;
+    for (var i=0; i<expl.length; i++)
+    {
+      sumx += expl[i].x;
+      sumy += expl[i].y;
+    }
+    sumx /= expl.length;
+    sumy /= expl.length;
+
+    for (var i=0; i<expl.length; i++)
+    {
+      var vectx = expl[i].x - sumx;
+      var vecty = expl[i].y - sumy;
+      var angle = Math.atan2(vecty, vectx) / Math.PI * 180;
+
+      expl[i].hide();
+      var b = new Ball(this);
+      b.setColor(expl[i].getColor());
+      b.setPosition(expl[i].x, expl[i].y);
+      b.setAngle(angle);
+      b.ay = 0.1;
+      this.balls.push(b);
+    }
+  }
 }
 
 class GameController extends Game
@@ -430,6 +430,23 @@
    if (!this.playing)
      return;
    this.playing = false;
+/*
+   var visible = [];
+   for (var i=0; i<this.balls.length; i++)
+     if (this.balls[i].element && this.balls[i].isVisible() && !this.balls[i].isFire() && !this.balls[i].isFalling())
+       visible.push(this.balls[i]);
+   this.explode(visible);
+*/
+/*
+   var visible = [];
+   for (let ball of this.balls)
+     if (ball.element && ball.isVisible() && !ball.isFire() && !ball.isFalling())
+       visible.push(ball);
+   this.explode(visible);
+*/
+   var visible = this.balls.filter(ball => ball.element && ball.isVisible() && 
+     !ball.isFire() && !ball.isFalling())
+   this.explode(visible);
 
    document.querySelector("#loser").style.visibility = "visible";
    setTimeout(()=>
```

## Diff 35 vs 34

 - [clean35/index.html](clean35/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean35/index.html)

```diff
--- ../clean34/index.html	2022-04-29 17:31:39.000000000 +0200
+++ ../clean35/index.html	2022-04-29 18:39:13.000000000 +0200
@@ -295,6 +295,7 @@
     this.top = 0;
     //this.levelconfig = levelconfig;
     this.colors = levelconfig.colors;
+    this.scrollSpeed = levelconfig.speed;
     if (this.cannon)
       this.cannon.destroy();
     for (var i=0; i<this.balls.length; i++)
@@ -336,8 +337,13 @@
     this.balls = this.balls.filter(b => b.element);
     for (var i=0; i<this.balls.length; i++)
       if (!this.balls[i].isFire() && !this.balls[i].isFalling())
-        this.balls[i].y += 0.1;
-    this.top += 0.1;
+        this.balls[i].y += this.scrollSpeed;
+
+    if (this.scrollSpeed == 0)
+      this.top = this.top * 0.9;
+    else
+      this.top += this.scrollSpeed;
+
     document.querySelector("#bar").style.top = this.top-282;
  	
     for (var i=0; i<this.balls.length; i++)
@@ -355,7 +361,7 @@
   }
   onKeyFire(b)
   { 
-    if (b)
+    if (this.playing && b)
     {
       this.fire = new Ball(this);
       this.fire.setColor(this.cannon.getColor());
@@ -375,8 +381,11 @@
       var colors = this.balls.filter(b=>b.element && b.isVisible() && !b.isFire() && !b.isFalling())
         .map(b=>b.getColor());
       colors = colors.filter((v, i, a) => a.indexOf(v) === i);
-      var rcolor = colors[Math.floor(Math.random()*colors.length)];
-      this.cannon.setColor(rcolor);
+      if (colors.length > 0)
+      {
+        var rcolor = colors[Math.floor(Math.random()*colors.length)];
+        this.cannon.setColor(rcolor);
+      }
     }
   }
   onMouse(pt) 
@@ -430,20 +439,7 @@
    if (!this.playing)
      return;
    this.playing = false;
-/*
-   var visible = [];
-   for (var i=0; i<this.balls.length; i++)
-     if (this.balls[i].element && this.balls[i].isVisible() && !this.balls[i].isFire() && !this.balls[i].isFalling())
-       visible.push(this.balls[i]);
-   this.explode(visible);
-*/
-/*
-   var visible = [];
-   for (let ball of this.balls)
-     if (ball.element && ball.isVisible() && !ball.isFire() && !ball.isFalling())
-       visible.push(ball);
-   this.explode(visible);
-*/
+   this.scrollSpeed = 0;
    var visible = this.balls.filter(ball => ball.element && ball.isVisible() && 
      !ball.isFire() && !ball.isFalling())
    this.explode(visible);
@@ -460,6 +456,7 @@
    if (!this.playing)
      return;
    this.playing = false;
+   this.scrollSpeed = 0;
    this.level = this.level + 1;
    document.querySelector("#winner").style.visibility = "visible";
    setTimeout(()=>
@@ -477,11 +474,11 @@
    var levelconfig;
 
    if (this.level == 1)
-     levelconfig = {rows:3, colors:["red.png", "green.png"]};
+     levelconfig = {rows:3, speed:0.5, colors:["red.png", "green.png"]};
    else if (this.level == 2)
-     levelconfig = {rows:4, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
+     levelconfig = {rows:4, speed:0.1, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
    else 
-     levelconfig = {rows:5, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
+     levelconfig = {rows:5, speed:0.1, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
 
    this.restart(levelconfig);
   }
```

## Diff 36 vs 35

 - [clean36/index.html](clean36/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean36/index.html)

```diff
--- ../clean35/index.html	2022-04-29 18:39:13.000000000 +0200
+++ ../clean36/index.html	2022-04-29 18:47:33.000000000 +0200
@@ -296,6 +296,8 @@
     //this.levelconfig = levelconfig;
     this.colors = levelconfig.colors;
     this.scrollSpeed = levelconfig.speed;
+    this.wind = levelconfig.wind;
+
     if (this.cannon)
       this.cannon.destroy();
     for (var i=0; i<this.balls.length; i++)
@@ -363,11 +365,13 @@
   { 
     if (this.playing && b)
     {
+      this.angle = Math.min(Math.max(20, this.angle), 160);
       this.fire = new Ball(this);
       this.fire.setColor(this.cannon.getColor());
       this.fire.setPosition(this.width/2, this.height-50);
       this.fire.setAngle(this.angle);
       this.fire.setSpeed(5);
+      this.fire.ax = this.wind;
       this.fire.show();
       this.balls.push(this.fire);
 
@@ -474,11 +478,11 @@
    var levelconfig;
 
    if (this.level == 1)
-     levelconfig = {rows:3, speed:0.5, colors:["red.png", "green.png"]};
+     levelconfig = {rows:3, speed:0.0, wind:0.02, colors:["red.png", "green.png"]};
    else if (this.level == 2)
-     levelconfig = {rows:4, speed:0.1, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
+     levelconfig = {rows:4, speed:0.0, wind:0, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
    else 
-     levelconfig = {rows:5, speed:0.1, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
+     levelconfig = {rows:5, speed:0.1, wind:0, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
 
    this.restart(levelconfig);
   }
```

## Diff 37 vs 36

 - [clean37/index.html](clean37/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean37/index.html)

```diff
--- ../clean36/index.html	2022-04-29 18:47:33.000000000 +0200
+++ ../clean37/index.html	2022-04-29 18:55:48.000000000 +0200
@@ -17,8 +17,10 @@
    <span style="--i:5">e</span>
    <span style="--i:6">r</span>
   </div>
+  <div id="level" style="visibility:hidden">Level 1</div>
 </div>
 <link rel="stylesheet" href="wave.css">
+<link rel="stylesheet" href="level.css">
 <script src="controls.js"></script>
 <script>
 class Ball
@@ -471,12 +473,12 @@
 
   onContinue()
   {
+   this.showLevel();
    document.querySelector("#loser").style.visibility = "hidden";
    document.querySelector("#winner").style.visibility = "hidden";
    this.playing = true;
 
    var levelconfig;
-
    if (this.level == 1)
      levelconfig = {rows:3, speed:0.0, wind:0.02, colors:["red.png", "green.png"]};
    else if (this.level == 2)
@@ -486,6 +488,19 @@
 
    this.restart(levelconfig);
   }
+
+  showLevel()
+  {
+    var level = document.querySelector("#level");
+    level.innerHTML = "Level " + this.level;
+    level.style.visibility = "visible";
+    level.className = "level";
+    setTimeout(() =>
+    {
+      level.style.visibility = "hidden";
+      level.className = "";
+    }, 3000);
+  }
 }
 
 var game = new GameController();
```

## Diff 38 vs 37

 - [clean38/index.html](clean38/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean38/index.html)

```diff
--- ../clean37/index.html	2022-04-29 18:55:48.000000000 +0200
+++ ../clean38/index.html	2022-05-04 08:48:36.000000000 +0200
@@ -478,13 +478,7 @@
    document.querySelector("#winner").style.visibility = "hidden";
    this.playing = true;
 
-   var levelconfig;
-   if (this.level == 1)
-     levelconfig = {rows:3, speed:0.0, wind:0.02, colors:["red.png", "green.png"]};
-   else if (this.level == 2)
-     levelconfig = {rows:4, speed:0.0, wind:0, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
-   else 
-     levelconfig = {rows:5, speed:0.1, wind:0, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
+   var levelconfig = this.getLevelConfig();
 
    this.restart(levelconfig);
   }
@@ -501,6 +495,18 @@
       level.className = "";
     }, 3000);
   }
+
+  getLevelConfig()
+  {
+    switch (this.level)
+    {
+      case 1: return {rows:3, speed:0.0, wind:0.02, colors:["red.png", "green.png"]};
+      case 2: return {rows:4, speed:0.0, wind:0, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
+      case 3: return {rows:5, speed:0.1, wind:0, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
+      default:
+        return {rows:5, speed:0.2, wind:0, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
+    }
+  }
 }
 
 var game = new GameController();
```

## Diff 39 vs 38

 - [clean39/index.html](clean39/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean39/index.html)

```diff
--- ../clean38/index.html	2022-05-04 08:48:36.000000000 +0200
+++ ../clean39/index.html	2022-05-04 09:54:26.000000000 +0200
@@ -158,6 +158,7 @@
 
     if (matching.length >= 3)
     {
+      this.game.sounds.playDrop();
       for (var i=0; i<matching.length; i++)
         matching[i].hide();
 
@@ -215,6 +216,7 @@
   {
     if (this.isFire() && !this.isFalling() && this.checkHit(balls))
     {
+      this.game.sounds.playHit();
       this.hit(balls);
       this.destroy();
       return;
@@ -225,14 +227,23 @@
     this.y = this.y + this.vy;
 
     if (this.x < 20)
+    {
       this.vx = Math.abs(this.vx);
+      if (this.isFire() && !this.isFalling())
+        this.game.sounds.playSpring();
+    }
     if (this.x > this.width-20)
+    {
       this.vx = -Math.abs(this.vx);
+      if (this.isFire() && !this.isFalling())
+        this.game.sounds.playSpring();
+    }
     if (this.y < this.game.top+20)
     {
       this.vy = Math.abs(this.vy);
       if (!this.isFalling() && this.isFire())
       {
+        this.game.sounds.playHit();
         this.hit(balls);
         this.destroy();
         return;
@@ -430,11 +441,51 @@
   }
 }
 
+class Sounds 
+{
+  constructor()
+  {
+    this.spring = new Audio("spring.mp3");
+    this.throwing = new Audio("throw.mp3");
+    this.win = new Audio("win.mp3");
+    this.lose = new Audio("lose.mp3");
+    this.hit = new Audio("hit.mp3");
+    this.drop = new Audio("drop.mp3");
+  }
+  playWin()
+  {
+    this.win.play();
+  }
+  playLose()
+  {
+    this.lose.play();
+  }
+  playThrow()
+  {
+    this.throwing.play();
+  }
+  playSpring()
+  {
+    this.spring.pause();
+    this.spring.currentTime = 0;
+    this.spring.play();
+  }
+  playHit()
+  {
+    this.hit.play();
+  }
+  playDrop()
+  {
+    this.drop.play();
+  }
+}
+
 class GameController extends Game
 {
   constructor()
   {
     super();
+    this.sounds = new Sounds();
     this.playing = true;
     this.level = 1;
     this.onContinue();
@@ -444,6 +495,7 @@
   {
    if (!this.playing)
      return;
+   this.sounds.playLose();
    this.playing = false;
    this.scrollSpeed = 0;
    var visible = this.balls.filter(ball => ball.element && ball.isVisible() && 
@@ -461,6 +513,7 @@
   {
    if (!this.playing)
      return;
+   this.sounds.playWin();
    this.playing = false;
    this.scrollSpeed = 0;
    this.level = this.level + 1;
@@ -500,9 +553,9 @@
   {
     switch (this.level)
     {
-      case 1: return {rows:3, speed:0.0, wind:0.02, colors:["red.png", "green.png"]};
+      case 1: return {rows:3, speed:0.0, wind:0, colors:["red.png", "green.png"]};
       case 2: return {rows:4, speed:0.0, wind:0, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
-      case 3: return {rows:5, speed:0.1, wind:0, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
+      case 3: return {rows:5, speed:0.1, wind:0.01, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
       default:
         return {rows:5, speed:0.2, wind:0, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
     }
```

## Diff 40 vs 39

 - [clean40/index.html](clean40/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean40/index.html)

```diff
--- ../clean39/index.html	2022-05-04 09:54:26.000000000 +0200
+++ ../clean40/index.html	2022-05-06 08:43:03.000000000 +0200
@@ -1,6 +1,6 @@
 <html>
 <div id="game" style="width:400px; height:600px; border:1px solid #d0d0d0; position:relative; background:url(background1.jpg); overflow:hidden;">
-<img id="bar" src="bar.png" style="position:absolute;">
+  <img id="bar" src="bar.png" style="position:absolute;">
   <div id="loser" class="wave" style="visibility:hidden">
    <span style="--i:1">L</span>
    <span style="--i:2">o</span>
@@ -18,9 +18,29 @@
    <span style="--i:6">r</span>
   </div>
   <div id="level" style="visibility:hidden">Level 1</div>
+  <div id="menu" class="menu" style="visibility:visible; z-index:100;">
+<!--    <div class="menu_white"></div>-->
+    <div class="menu_background"></div>
+    <div class="frozen">Frozen bubble</div>
+    <div style="padding-left:10px;">
+      <div class="chest_closed">1</div>
+      <div class="chest_closed">2</div>
+      <div class="chest_closed">3</div>
+      <div class="chest_open">4</div>
+      <div class="chest_open">5</div>
+      <div class="chest_closed">6</div>
+      <div class="chest_closed">7</div>
+      <div class="chest_closed">8</div>
+      <div class="chest_closed">9</div>
+      <div class="chest_closed">10</div>
+      <div class="chest_closed">11</div>
+      <div class="chest_closed">12</div>
+    </div>
+  </div>
 </div>
 <link rel="stylesheet" href="wave.css">
 <link rel="stylesheet" href="level.css">
+<link rel="stylesheet" href="menu.css">
 <script src="controls.js"></script>
 <script>
 class Ball
@@ -490,7 +510,6 @@
     this.level = 1;
     this.onContinue();
   }
-
   onLose()
   {
    if (!this.playing)
```

## Diff 41 vs 40

 - [clean41/index.html](clean41/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean41/index.html)

```diff
--- ../clean40/index.html	2022-05-06 08:43:03.000000000 +0200
+++ ../clean41/index.html	2022-05-04 19:03:41.000000000 +0200
@@ -18,16 +18,16 @@
    <span style="--i:6">r</span>
   </div>
   <div id="level" style="visibility:hidden">Level 1</div>
-  <div id="menu" class="menu" style="visibility:visible; z-index:100;">
-<!--    <div class="menu_white"></div>-->
+  <div id="menu" class="menu" style="visibility:hidden; z-index:100;">
+    <div class="menu_white"></div>
     <div class="menu_background"></div>
     <div class="frozen">Frozen bubble</div>
     <div style="padding-left:10px;">
       <div class="chest_closed">1</div>
       <div class="chest_closed">2</div>
       <div class="chest_closed">3</div>
-      <div class="chest_open">4</div>
-      <div class="chest_open">5</div>
+      <div class="chest_closed">4</div>
+      <div class="chest_closed">5</div>
       <div class="chest_closed">6</div>
       <div class="chest_closed">7</div>
       <div class="chest_closed">8</div>
@@ -319,7 +319,8 @@
 
     setInterval(() => 
     {
-      this.update()
+      if (this.engineRunning)
+        this.update()
     }, 10);
   }
 
@@ -330,6 +331,7 @@
     this.colors = levelconfig.colors;
     this.scrollSpeed = levelconfig.speed;
     this.wind = levelconfig.wind;
+    this.engineRunning = true;
 
     if (this.cannon)
       this.cannon.destroy();
@@ -396,6 +398,9 @@
   }
   onKeyFire(b)
   { 
+    if (!this.engineRunning)
+      return;
+
     if (this.playing && b)
     {
       this.angle = Math.min(Math.max(20, this.angle), 160);
@@ -427,6 +432,9 @@
   }
   onMouse(pt) 
   {
+    if (!this.engineRunning)
+      return;
+
     var vx = pt.x - this.cannon.x;
     var vy = pt.y - this.cannon.y;
     this.angle = Math.floor(Math.atan2(-vy, vx) * 180 / Math.PI);
@@ -508,7 +516,27 @@
     this.sounds = new Sounds();
     this.playing = true;
     this.level = 1;
-    this.onContinue();
+
+    this.unlockedLevels = [1];
+    this.showMenu();
+  }
+  showMenu()
+  {
+    this.engineRunning = false;
+    document.querySelector("#menu").style.visibility = "visible";
+//    document.querySelectorAll(".chest_open").forEach( elem => elem.className = "chest_closed" );
+    document.querySelectorAll(".chest_closed").forEach( elem => {
+      var l = parseInt(elem.innerHTML);
+      if (this.unlockedLevels.indexOf(l) != -1)
+        elem.className = "chest_open";
+    });
+
+    document.querySelectorAll(".chest_open").forEach( elem => elem.onclick = (e) => {
+      var level = parseInt(e.target.innerHTML);
+      console.log("Set level: " + level);
+      this.level = level;
+      this.onContinue();
+    });
   }
   onLose()
   {
@@ -524,7 +552,8 @@
    document.querySelector("#loser").style.visibility = "visible";
    setTimeout(()=>
    {
-     this.onContinue();
+     //this.onContinue();
+     this.showMenu();
    }, 5000);
   }
 
@@ -535,6 +564,8 @@
    this.sounds.playWin();
    this.playing = false;
    this.scrollSpeed = 0;
+   if (this.unlockedLevels.indexOf(this.level+1) == -1)
+     this.unlockedLevels.push(this.level+1);
    this.level = this.level + 1;
    document.querySelector("#winner").style.visibility = "visible";
    setTimeout(()=>
@@ -546,6 +577,7 @@
   onContinue()
   {
    this.showLevel();
+   document.querySelector("#menu").style.visibility = "hidden";
    document.querySelector("#loser").style.visibility = "hidden";
    document.querySelector("#winner").style.visibility = "hidden";
    this.playing = true;
@@ -572,11 +604,22 @@
   {
     switch (this.level)
     {
-      case 1: return {rows:3, speed:0.0, wind:0, colors:["red.png", "green.png"]};
-      case 2: return {rows:4, speed:0.0, wind:0, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
-      case 3: return {rows:5, speed:0.1, wind:0.01, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
+      case 1: return {speed: 0.00, rows: 5, wind:0, colors: ["red.png", "green.png", "blue.png"]};
+      case 2: return {speed: 0.00, rows: 5, wind:0.03, colors: ["red.png", "green.png", "blue.png"]};
+      case 3: return {speed: 0.01, rows: 6, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png"]};
+      case 4: return {speed: 0.04, rows: 3, wind:0, colors: ["bri050.png", "bri100.png", "bri150.png"]};
+
+      case 5: return {speed: 0.01, rows: 6, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png", "mod200.png"]};
+      case 6: return {speed: 0.01, rows: 5, wind:-0.05,  colors: ["red.png", "green.png", "blue.png", "bri150.png"]};
+      case 7: return {speed: 0.02, rows: 6, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png", "mod200.png", "mod075.png"]};
+      case 8: return {speed: 0.07, rows: 4, wind:0.03, timeout:0, colors: ["red.png", "green.png", "blue.png"]};
+
+      case 9: return {speed: 0.03, rows: 6, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png", "mod200.png", "mod075.png", "bri050.png"]};
+      case 10: return {speed: 0.06, rows: 3, wind:0.02, colors: ["bri050.png", "bri100.png", "bri150.png", "bri200.png"]};
+      case 11: return {speed: 0.05, rows: 6, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png", "mod200.png", "mod075.png"]};
+      case 12: return {speed: 0.08, rows: 5, wind:0.01, colors: ["red.png", "green.png", "blue.png", "mod150.png", "mod200.png", "mod075.png", "bri050.png"]};
       default:
-        return {rows:5, speed:0.2, wind:0, colors:["red.png", "green.png", "blue.png", "mod200.png"]};
+        return {speed: 0.08, rows: 7, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png", "mod200.png", "mod075.png", "bri050.png", "bri150.png"]};
     }
   }
 }
```

## Diff 42 vs 41

 - [clean42/index.html](clean42/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean42/index.html)

```diff
--- ../clean41/index.html	2022-05-04 19:03:41.000000000 +0200
+++ ../clean42/index.html	2022-05-04 19:08:59.000000000 +0200
@@ -516,10 +516,23 @@
     this.sounds = new Sounds();
     this.playing = true;
     this.level = 1;
-
-    this.unlockedLevels = [1];
+    this.loadUnlockedLevels();
+//    this.unlockedLevels = [1];
     this.showMenu();
   }
+  loadUnlockedLevels()
+  {
+    var persistent = localStorage.getItem("unlocked_levels");
+    if (persistent)
+      this.unlockedLevels = JSON.parse(persistent);
+    else
+      this.unlockedLevels = [1];
+  }
+  saveUnlockedLevels()
+  {
+    var persistent = JSON.stringify(this.unlockedLevels);
+    localStorage.setItem("unlocked_levels", persistent);
+  }
   showMenu()
   {
     this.engineRunning = false;
@@ -565,7 +578,10 @@
    this.playing = false;
    this.scrollSpeed = 0;
    if (this.unlockedLevels.indexOf(this.level+1) == -1)
+   {
      this.unlockedLevels.push(this.level+1);
+     this.saveUnlockedLevels();
+   }
    this.level = this.level + 1;
    document.querySelector("#winner").style.visibility = "visible";
    setTimeout(()=>
@@ -607,14 +623,14 @@
       case 1: return {speed: 0.00, rows: 5, wind:0, colors: ["red.png", "green.png", "blue.png"]};
       case 2: return {speed: 0.00, rows: 5, wind:0.03, colors: ["red.png", "green.png", "blue.png"]};
       case 3: return {speed: 0.01, rows: 6, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png"]};
-      case 4: return {speed: 0.04, rows: 3, wind:0, colors: ["bri050.png", "bri100.png", "bri150.png"]};
+      case 4: return {speed: 0.06, rows: 3, wind:0, colors: ["bri050.png", "bri100.png", "bri150.png"]};
 
-      case 5: return {speed: 0.01, rows: 6, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png", "mod200.png"]};
-      case 6: return {speed: 0.01, rows: 5, wind:-0.05,  colors: ["red.png", "green.png", "blue.png", "bri150.png"]};
-      case 7: return {speed: 0.02, rows: 6, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png", "mod200.png", "mod075.png"]};
+      case 5: return {speed: 0.02, rows: 6, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png", "mod200.png"]};
+      case 6: return {speed: 0.02, rows: 5, wind:-0.05,  colors: ["red.png", "green.png", "blue.png", "bri150.png"]};
+      case 7: return {speed: 0.04, rows: 6, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png", "mod200.png", "mod075.png"]};
       case 8: return {speed: 0.07, rows: 4, wind:0.03, timeout:0, colors: ["red.png", "green.png", "blue.png"]};
 
-      case 9: return {speed: 0.03, rows: 6, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png", "mod200.png", "mod075.png", "bri050.png"]};
+      case 9: return {speed: 0.05, rows: 6, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png", "mod200.png", "mod075.png", "bri050.png"]};
       case 10: return {speed: 0.06, rows: 3, wind:0.02, colors: ["bri050.png", "bri100.png", "bri150.png", "bri200.png"]};
       case 11: return {speed: 0.05, rows: 6, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png", "mod200.png", "mod075.png"]};
       case 12: return {speed: 0.08, rows: 5, wind:0.01, colors: ["red.png", "green.png", "blue.png", "mod150.png", "mod200.png", "mod075.png", "bri050.png"]};
```

## Diff 43 vs 42

 - [clean43/index.html](clean43/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean43/index.html)

```diff
--- ../clean42/index.html	2022-05-04 19:08:59.000000000 +0200
+++ ../clean43/index.html	2022-05-05 18:14:22.000000000 +0200
@@ -1,4 +1,8 @@
 <html>
+<head>
+<meta content="width=device-width" name="viewport"/>
+<meta name="viewport" content="width=device-width,initial-scale=0.9,minimum-scale=0.9,maximum-scale=3.9" />
+</head>
 <div id="game" style="width:400px; height:600px; border:1px solid #d0d0d0; position:relative; background:url(background1.jpg); overflow:hidden;">
   <img id="bar" src="bar.png" style="position:absolute;">
   <div id="loser" class="wave" style="visibility:hidden">
@@ -41,6 +45,7 @@
 <link rel="stylesheet" href="wave.css">
 <link rel="stylesheet" href="level.css">
 <link rel="stylesheet" href="menu.css">
+<link rel="stylesheet" href="phone.css">
 <script src="controls.js"></script>
 <script>
 class Ball
@@ -623,7 +628,7 @@
       case 1: return {speed: 0.00, rows: 5, wind:0, colors: ["red.png", "green.png", "blue.png"]};
       case 2: return {speed: 0.00, rows: 5, wind:0.03, colors: ["red.png", "green.png", "blue.png"]};
       case 3: return {speed: 0.01, rows: 6, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png"]};
-      case 4: return {speed: 0.06, rows: 3, wind:0, colors: ["bri050.png", "bri100.png", "bri150.png"]};
+      case 4: return {speed: 0.08, rows: 3, wind:0, colors: ["bri050.png", "bri100.png", "bri150.png"]};
 
       case 5: return {speed: 0.02, rows: 6, wind:0, colors: ["red.png", "green.png", "blue.png", "mod150.png", "mod200.png"]};
       case 6: return {speed: 0.02, rows: 5, wind:-0.05,  colors: ["red.png", "green.png", "blue.png", "bri150.png"]};
```

