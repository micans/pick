#!/bin/bash

# Use this to inspect self-matches in a database of sequences, showing
# alignments ordered by edit-distance, most similar first.

# Usage: pipe SAM format to this script, give it the FASTA reference as argument.
# The optional second argument is to ignore matches with big insertions and
# deletions.  I've used this occasionally with vsearch output because it (1)
# can produce short matches (2) uses indels rather than soft clipping in the
# CIGAR string. The second argument to this script is a bit peculiar to that
# very specific case; one may want to ignore it or adapt to filter matches in
# some other way, depending on the requirements.

set -euo pipefail

FASTA=${1?Need fasta, and optionally an indel count (above which matches are not reported)}
indel=${2-}

AT_indel=

if [[ ! -z "$indel" ]]; then
  AT_indel="@ninsdel/le/$indel"
fi

pick --sam/"$FASTA" ninsdel:=6^ID,cgsum "$AT_indel" ::,alnedit:1:3,aln_ref,aln_aln,aln_qry^^%09,joinall | sort -n | pick -k ::^:'.*'^%0A,joinall

