#!/bin/bash

# Usage: pipe SAM format to this script, give it the FASTA reference as argument.

set -euo pipefail

qry=${1?Need query}
FASTA=${2?Need ref}
foo=${3?Need sam-trail value}

# pick --sam/"$FASTA" ::^edit=,aln_nedit^%20flags=:2^%20patchi=,aln_aln^100,patchiness^%20maxi=:6^I,cgmax,catall:3:1,aln_ref,aln_aln,aln_qry^^%09,joinall | pick -k ::^:'.*'^%0A,joinall

pick -A --sam @@2/none/4 < $qry | ../pick --sam/"$FASTA" --sam-aln-context=$foo nedit:=,aln_nedit npatchi:=,aln_aln^100,patchiness insmax:=6^I,cgmax \
      qc:=^nedit=:nedit^%20npatchi=:npatchi^%20insmax=:insmax,catall \
      ::qc:3:1,aln_all^^^%0A,joinall

#     :=^51^150,sam_rbt \
#     ::qc:3:1,rbt_alnall^^^%0A,joinall
