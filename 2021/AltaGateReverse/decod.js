var src = process.argv[2];
var dst = process.argv[2] + ".txt";
var fs = require("fs");
data = fs.readFileSync(src).toString();
tab = fs.readFileSync("tables.txt").toString();

var t = tab.split("\n").join(" ").split("  ").join(" ").split(" ");
t = t.map(x=>parseInt("0x"+x))
t = t.map(x=>String.fromCharCode(x))

var ofs = 0x0ebbd720 - 0x0ebb7320 - 0x6400;
var seq = [0x6400, 0x7b00, 0x8700, 0x9300, 0xaa00, 0xb600, 0xc200, 0x7500, 0x8100, 
  0x8d00, 0x9900, 0xb000, 0xbc00];

var buf = [];
var lines = data.split("\n");
var base = 0;
for (var i=0; i<lines.length; i++)
{
  line = lines[i];
  var aux = "";
  for (var j=0; j<line.length; j++)
  {
    var inp = line.charCodeAt(j);
    var out = t[inp + ofs + seq[base % seq.length]];
    if ("ezEZ".indexOf(out) != -1)
     base++;
    aux += out;
  }
  base++;
  buf.push(aux);
}

fs.writeFileSync(dst, buf.join("\n"))
