var request = require("request");

setInterval(() =>
{
  request("https://dweet.io/dweet/for/creativepoint_ba1?counter=111&humidity=100&temperature=0", (r, e, b) =>
  {
    console.log(b);
  });
}, 1000);