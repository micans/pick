#!/bin/bash

set -euo pipefail

cat <<EOT > multi-select.md
# Examples of selecting and changing multiple columns simultaneously

EOT

while IFS=# read command description; do
cat <<EOT
### $description
\`\`\`
> $command

EOT
  eval "$command" || true
cat <<EOT
\`\`\`


EOT
done << "EOI" 2>& 1 | expand >> multi-select.md
echo -e "a\\tb\\tc\\n3\\t4\\t5" | pick '.*'#Select all columns for output (normally achieved with -A)
echo -e "a\\tb\\tc\\n3\\t4\\t5" | pick '.*'::#Select all columns, apply the same computation (cannot be empty however)
echo -e "a\\tb\\tc\\n3\\t4\\t5" | pick '.*'::^foo#The -i in-place options is required to allow potential overwriting of existing columns
echo -e "a\\tb\\tc\\n3\\t4\\t5" | pick -i '.*'::^foo#Computation consisting of the constant value 'foo'
echo -e "a\\tb\\tc\\n3\\t4\\t5" | pick -i '.*'::__#Computation consisting of the column itself
echo -e "a\\tb\\tc\\n3\\t4\\t5" | pick -i '.*'::__:__#Computation consisting of the column duplicated
echo -e "a\\tb\\tc\\n3\\t4\\t5" | pick -i '.*'::__,sq#Computation consisting of the column squared
echo -e "a\\tb\\tc\\n3\\t4\\t5" | pick -A '.*'/x::__,sq#Create a new column name by adding 'x'; now -i is not needed, -A shows the original columns
echo -e "a\\tb\\tc\\n3\\t4\\t5" | pick  '.*'//x::__,sq#Using the double slash has the same effect, but columns are grouped pairwise
echo -e "a\\tb\\tc\\n3\\t4\\t5" | pick  '.*'//_pct::__:c^1,pct#This can be useful when expressing as a percentage, here relative to column c
echo -e "a\\tb\\tc\\n3\\t4\\t5" | pick -A '.*'/x::__,sq '.*'/y::__,sq,sq#Multiple computations are possible
echo -e "a\\tb\\tc\\n3\\t4\\t5" | pick -i '.*'::'.*',addall#A (not very useful) curiosity - the first column is a = (a=3)+(b=4)+(c=5)=12, then the second is b = (a=12)+(b=4)+(c=5)=21, the third is c = (a=12)+(b=21)+(c=5)
echo -e "a\\tb\\tc\\n3\\t4\\t5" | pick -Ai '.*'/x::'.*',addall#(continued) this behaviour disappears if the values are stored in a new name
EOI
