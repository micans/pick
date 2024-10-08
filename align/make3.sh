#!/bin/bash

set -euo pipefail

echo -e "GBW1\tSEA1 G1 B1 W1 SEA2\nGBW2rc\t<SEA3 G2 B2 W2 SEA4>" | ../utils/makedna.pl > ref3.fa

for i in {1..40}; do
  { echo -e "readGBW1-$i\tfoo bar zut {G1 B1 W1} doo wah tik";
    echo -e "readGBW2-$i\tfoo bar zut {G2 B2 W2} doo wah tik";
    echo -e "readGBW1-$i-rc\tfoo bar zut {<G1 B1 W1>} doo wah tik";
    echo -e "readGBW2-$i-rc\tfoo bar zut {<G2 B2 W2>} doo wah tik";
    echo -e "readGBW1x-$i\tSEA3 {G1 B1 W1} SEA4";
    echo -e "readGBW2x-$i\tSEA1 {G2 B2 W2} SEA2";
    echo -e "readGBW1z-$i\tfoo bar zut SEA1 {G1 B1 W1} SEA2 doo wah tik";
    echo -e "readGBW2z-$i\tfoo bar zut SEA3 {G2 B2 W2} SEA4 doo wah tik";
  } | ../utils/makedna.pl 0.03 0.03 0.03 5
done > qry3.fa

# vsearch --usearch_global qry3.fa  --db ref3.fa --strand both --samheader --id 0.7 --samout >(samtools view -h > qry3v.sam)

