#!/bin/bash

set -euo pipefail

FASTA=ref3.fa

pick=../pick

if true; then
for tag in mm vs; do
   for i in 0 1 2 3 4 5 6 7 8 9; do
      oput="$tag.foo.0$i"'0.txt'
      cat qry3$tag.sam \
         | ${pick} -qqq --sam/"$FASTA" --sam-aln-mrk --sam-aln-context=$((i*10)) @@2/none/4 \
             ::,aln_aln,len           \
             ::,aln_qlt,len           \
             ::,aln_qry,len           \
             ::,aln_ref,len           \
             ::,aln_rlr,len           \
             ::,aln_matched_cgr,len   \
             ::,aln_trail3p_cgr,len   \
             ::,aln_trail5p_cgr,len   \
             ::,qry_len           \
             ::,qry_matched,len       \
             ::,qry_matched_N     \
             ::,qry_posx          \
             ::,qry_posy          \
             ::,qry_trail3p,len       \
             ::,qry_trail3p_N     \
             ::,qry_trail5p,len       \
             ::,qry_trail5p_N     \
             ::,ref_len           \
             ::,ref_matched,len       \
             ::,ref_matched_N     \
             ::,ref_posx          \
             ::,ref_posy          \
             ::,ref_trail3p,len       \
             ::,ref_trail3p_N     \
             ::,ref_trail3p_V     \
             ::,ref_trail5p,len       \
             ::,ref_trail5p_N     \
             ::,ref_trail5p_V     \
            > $tag.foo.0$i''0.txt
      md5=$(md5sum < $oput | cut -f 1 -d ' ')
      echo -e "$tag\t$i\t$md5"
   done
done | tee test4.md5.new
fi

if ! diff test4.md5.ref test4.md5.new; then
   echo "Difference in output detected"
else
   echo "Alignments part counts unchanged, test 4 OK"
fi

