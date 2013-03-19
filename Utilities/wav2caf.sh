#!/bin/bash
for f in *.wav; do
  echo "Processing $f file..."
  afconvert -f caff -d aac -c 1 -b 32768 "$f" "${f/wav/caf}"
done
