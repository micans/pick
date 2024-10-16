#!/bin/bash

set -euo pipefail

FASTA=ref3.fa

if true; then
for tag in mm vs; do
   for i in 0 1 2 3 4 5 6 7 8 9; do
      oput="$tag.out.0$i"'0.txt'
      cat qry3$tag.sam \
         | ../pick -qqq --sam/"$FASTA" --sam-aln-context=$((i*10)) @@2/none/4 \
               qparts:=^QP,rowno^$i,qry_trail5p_N,qry_matched_N,qry_trail3p_N^%09,joinall \
               rparts:=^RP,rowno^$i,ref_trail5p_N,ref_matched_N,ref_trail3p_N^%09,joinall \
               mod_cigar:=6 \
               input_cigar:=^input_cigar,_spuv \
            ::input_cigar:mod_cigar:qparts:rparts,aln_all^^%0A,joinall > $tag.out.0$i''0.txt
      md5=$(md5sum < $oput | cut -f 1 -d ' ')
      echo -e "$tag\t$i\t$md5"
   done
done | tee test3.md5.new
fi

if ! diff test3.md5.ref test3.md5.new; then
   echo "Difference in output detected"
else
   echo "Alignments part counts unchanged, test OK"
fi

for tag in vs mm; do
   for part in QP QR; do
      echo -n "$tag $part tests failed: "
      grep "^$part" $tag.out*.txt | sort -nk 2 | pick -k 2 ::2:4:5:6^-,joinall | datamash -g 2 first 1 count 1 | pick -ck @3/=10 || true
   done
done


for tag in vs mm; do
   echo -n "For $tag test { nm:i field } == { pick equivalent } failed: "
   cat qry3$tag.sam | ../pick -qqq --sam/ref3.fa @@2/none/4 e1:=,aln_nedit e2:=,aln_aln,len,aln_aln^%7C,nchar,sub ::e1:e2,sub | pick -ck @1/=0
done

