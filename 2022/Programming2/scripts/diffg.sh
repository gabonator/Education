echo "# Diff" > diff.md

for i in $(seq -f "%02g" 0 1 43)
do
  if [ "$old" == "" ];
  then
    echo 
  else
    echo "## Diff $i vs $old" >> diff.md
    echo "" >> diff.md
    echo "\`\`\`diff" >> diff.md
    diff ../clean$i/index.html ../clean$old/index.html >> diff.md
    echo "\`\`\`" >> diff.md
    echo >> diff.md
  fi 	
  old=$i
  #diff ../clean
done