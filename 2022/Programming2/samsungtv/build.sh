archive=frozenbubble_0003
name="Frozen bubble"
ip=192.168.1.228

(
  cd source
  rm ../widgets/$archive.zip
  zip ../widgets/$archive.zip *
)

size=$(wc -c < widgets/$archive.zip)

cat > widgetlist.xml <<- EOM
<?xml version="1.0" encoding="UTF-8"?>
<rsp stat="ok">
<list>
   <widget id="$archive">
       <title>$name</title>
       <compression size="${size## }" type="zip"/>
       <description></description>
       <download>http://$ip/widgets/$archive.zip</download>
   </widget>
</list>
</rsp>
EOM

http-server . -p 80