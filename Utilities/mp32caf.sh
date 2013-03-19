#!/bin/bash
for f in *.mp3; do
  echo "Processing $f file..."
  afconvert -f caff -d aac -c 1 -b 32768 "$f" "${f/mp3/caf}"
done
