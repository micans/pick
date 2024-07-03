#!/bin/bash

set -euo pipefail

echo -e "GBW1\tSEA1 G1 B1 W1 SEA2\nGBW2rc\t<SEA3 G2 B2 W2 SEA4>" | ../utils/makedna.pl > ref2.fa

for i in {1..40}; do
  { echo -e "readGBW1-$i\tfoo bar zut {G1 B1 W1} doo wah tik";
    echo -e "readGBW2-$i\tfoo bar zut {G2 B2 W2} doo wah tik";
    echo -e "readGBW1-$i-rc\tfoo bar zut {<G1 B1 W1>} doo wah tik";
    echo -e "readGBW2-$i-rc\tfoo bar zut {<G2 B2 W2>} doo wah tik";
    echo -e "readGBW1x-$i\tSEA3 {G1 B1 W1} SEA4";
    echo -e "readGBW2x-$i\tSEA1 {G2 B2 W2} SEA2";
  } | ../utils/makedna.pl 0.03 0.03 0.03 5
done > qry2.fa

