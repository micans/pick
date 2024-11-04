#!/bin/bash

# Usage: pipe SAM format to this script, give it the FASTA reference as argument.

set -euo pipefail

FASTA=${1?I need fasta as first argument and SAM format on STDIN}

pick --sam/"$FASTA" --sam-aln-context=0   \
      nedit:=,aln_nedit                   \
      npatchi:=,aln_aln^40,patchiness     \
      insmax:=6^I,cgmax                   \
      qc:=^nedit=:nedit^%20npatchi=:npatchi^%20insmax=:insmax,catall \
                                          \
      nedit ::qc:3:1,aln_all_pack^%01^%09,joinall | sort -nr | pick -k 2- | tr '\1\t' '\n'


# The approach below avoids packing with aln_all_pack and unpacking with tr as above.
# However it is lossy, as sorting means we may loose
# query sequences if the primary sam hit sorts below non-primary hits.

#    pick --sam -A0 nedit::,aln_nedit     \
#  | sort -nr                    \
#  | cut -f 2-                   \
#  | pick --sam/$FASTA        \
#        nedit:=,aln_nedit                   \
#        npatchi:=,aln_aln^100,patchiness    \
#        insmax:=6^I,cgmax                   \
#        qc:=^nedit=:nedit^%20npatchi=:npatchi^%20insmax=:insmax,catall \
#                                            \
#        ::qc:3:1,aln_all^^^%0A,joinall



