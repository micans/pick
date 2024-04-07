#!/bin/bash

set -euo pipefail

../utils/makedna.pl < set1.ref.in  > set1.ref.fa
for i in {1..10}; do
   cat set1.qry.in | while read x y; do
      echo -e "$x-read$i\t{$y}"       | ../utils/makedna.pl 0.04 0.04 0.04 5
      echo -e "$x-read$i""rc\t{<$y>}" | ../utils/makedna.pl 0.04 0.04 0.04 5
   done;
done > set1.qry.fa

