#!/bin/bash

# Usage: pipe SAM format to this script, give it the FASTA reference as argument.

set -euo pipefail

FASTA=${1?Need fasta}

# pick --sam/"$FASTA" ::^edit=,alnedit^%20flags=:2^%20patchi=,aln_aln^100,patchiness^%20maxi=:6^I,cgmax,catall:3:1,aln_ref,aln_aln,aln_qry^^%09,joinall | pick -k ::^:'.*'^%0A,joinall

pick --sam/"$FASTA" nedit:=,alnedit npatchi:=,aln_aln^100,patchiness insmax:=6^I,cgmax \
      qc:=^nedit=:nedit^%20npatchi=:npatchi^%20insmax=:insmax,catall \
      ::qc:3:1,aln_ref,aln_aln,aln_qry^^^%0A,joinall

