var N = 10;
var bx = 1050+600;
var by = 1450;
var r0 = 900;
var r1 = 1800;

var points = [];
for (var i=0; i<=N; i++)
{
  var angle = Math.PI*2 * i / N;
  if (i%2==0)
    r = r0;
  else
    r = r1;

  var x = Math.sin(angle) * r + bx;
  var y = -Math.cos(angle) * r + by;
  points.push([Math.floor(x), Math.floor(y)]);
}

var command = "WIRE " + points.map(pt => "(" + pt.join(" ") + ")").join(" ");
console.log(command);

var r2 = 1300
var r3 = r1*1950/1800
var r4 = r0*1950/1800

var hints = [];
for (var i=0; i<=N; i++)
{
  var angle = Math.PI*2 * i / N;

  if (i%2==1)
  { 
    // LED
    var x = Math.sin(angle) * r2 + bx;
    var y = -Math.cos(angle) * r2 + by;
    hints.push([Math.floor(x), Math.floor(y)]);

    // outer document
//    var x = Math.sin(angle) * r3 + bx;
//    var y = -Math.cos(angle) * r3 + by;
//    hints.push([Math.floor(x), Math.floor(y)]);
  } else {
    // inner document
//    var x = Math.sin(angle) * r4 + bx;
//    var y = -Math.cos(angle) * r4 + by;
//    hints.push([Math.floor(x), Math.floor(y)]);
  }
}

console.log(hints.map(p => "CIRCLE ("+(p[0]-5) + " " + (p[1]-5)+") ("+(p[0]+5) + " " + (p[1]+5)+")").join("; "))