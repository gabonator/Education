for i in $(seq -f "%03g" 0 5 200)
do
  convert -modulate 100,100,$i gulicka.png hue$i.png
done

for i in $(seq -f "%03g" 0 20 200)
do
  convert -modulate $i,0,100 gulicka.png sat$i.png
done
