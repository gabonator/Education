echo "# Diff" > ../diff.md
echo "" >> ../diff.md
echo "## Reference" >> ../diff.md
echo "" >> ../diff.md
echo "\`\`\`html" >> ../diff.md
cat ../clean00/index.html >> ../diff.md
echo "" >> ../diff.md
echo "\`\`\`" >> ../diff.md

for i in $(seq -f "%02g" 0 1 43)
do
  if [ "$old" == "" ];
  then
    echo 
  else
    echo "## Diff $i vs $old" >> ../diff.md
    echo "" >> ../diff.md
    echo " - [clean$i/index.html](clean$i/index.html) [live](https://rawgit.valky.eu/gabonator/Education/master/2022/Programming2/clean$i/index.html)" >> ../diff.md
    echo "" >> ../diff.md
    echo "\`\`\`diff" >> ../diff.md
    diff --unified --text  ../clean$old/index.html ../clean$i/index.html >> ../diff.md
    echo "\`\`\`" >> ../diff.md
    echo >> ../diff.md
  fi 	
  old=$i
done