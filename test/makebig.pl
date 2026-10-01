#!/usr/bin/perl

# Generate a deterministic 100-row, 20-column table (big.txt) for pick tests.
# A simple LCG is used so output does not depend on perl's rand implementation.
# Usage: perl makebig.pl > big.txt

use strict;
use warnings;

my $seed = 12345;
sub rnd { $seed = ($seed * 1103515245 + 12345) % 2147483648; return $seed / 2147483648; }
sub rint { my ($lo, $hi) = @_; return $lo + int(rnd() * ($hi - $lo + 1)); }

my @words = qw(alpha bravo charlie delta echo foxtrot golf hotel india juliet kilo lima mike
               november oscar papa quebec romeo sierra tango uniform victor whiskey xray yankee zulu);
my @grp = qw(A B C D E);
my @dnachars = qw(A C G T);

print join("\t", qw(id grp n1 n2 n3 n4 n5 n6 n7 n8 f1 f2 f3 f4 s1 s2 dna flag tag x)), "\n";

for my $i (1..100) {
   my @row = (sprintf("r%03d", $i), $grp[rint(0, 4)]);
   push @row, rint(-50, 50) for 1..2;
   push @row, rint(0, 3);                       # n3: many zeros, used as denominator
   push @row, rint(0, 1000) for 1..5;
   push @row, sprintf("%.4f", rnd()) for 1..2;
   push @row, sprintf("%.4f", rnd() * 200 - 100) for 1..2;
   push @row, $words[rint(0, $#words)], $words[rint(0, $#words)] . rint(0, 99);
   push @row, join "", map { $dnachars[rint(0, 3)] } 1..rint(1, 20);
   push @row, rint(0, 15);
   push @row, ($i % 7 == 0 ? "keep" : "drop");
   push @row, rint(1, 9);
   print join("\t", @row), "\n";
}
