#!/bin/bash

# Usage: pipe SAM format to this script, give it the FASTA reference as argument.

set -euo pipefail

FASTA=${1?Need fasta, and optionally an indel count (above which matches are not reported)}

pick --sam/"$FASTA" ::,alnedit:3:1,aln_ref,aln_aln,aln_qry^^%09,joinall | pick -k ::^:'.*'^%0A,joinall

