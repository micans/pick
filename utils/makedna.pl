#!/usr/bin/perl

use warnings;
use strict;

my %map = (' ', qw(G e C t T a A o CT i CA n AA s C r TA h AT d AG l GG u GA c TG m GC f TT y AC w GT g CT p CA b AA v CC k TC x TA q AT j AG z CG));
$map{'<'} = '<';
$map{'>'} = '>';
$map{'{'} = '{';
$map{'}'} = '}';

my %predef = ();
my ($rc, $ri, $rd, $indelmaxsize) = (0, 0, 0, 0);  #  rate of change, insert, deletion

if (@ARGV == 4) {
  ($rc, $ri, $rd, $indelmaxsize) = @ARGV;
  @ARGV = ();
}
elsif (@ARGV) {
  die "Use as pipe, optional give <base change rate> <insertion rate> <deletion rate> <indelmaxsize> as command line arguments";
}

while (<DATA>) {
   chomp;
   next unless /\S/;
   my ($name, $code) = split "\t";
   $predef{$name} = $code;

}

sub rc {
   my $dna = shift;
   $dna =~ tr /ACGT/TGCA/;
   return reverse($dna);
}

sub rb {
   return qw( A C G T )[int(rand(4))];
}

sub muck {                               # just affect some change. no model here.
  my $seq = shift;
  my $new = "";
  for (my $i=0; $i<length($seq); $i++) {
    if (rand(1) < $rc) {                 # change a base
      $new .= rb();
    }
    my $do_ins = rand(1) < $ri;
    my $do_del = rand(1) < $rd;
    my $ni = 1 + int($indelmaxsize * rand(1)*rand(1));
    my $nd = 1 + int($indelmaxsize * rand(1)*rand(1));
    if (!$do_ins && !$do_del) {
      $new .= substr($seq, $i, 1);
    }
    else {
      if ($do_ins) {
        $new .= substr($seq, $i, 1);
        $new .= rb() for 1..$ni;
      }
      if ($do_del) {
        $i += $nd;
      }
    }
  }
  return $new;
}

while (<>) {
   chomp;
   my ($name, $code) = split "\t";
   next unless defined($code);
   while ($code =~ /(\w+)/g) {
      my $w = $1;
      my $y = $predef{$w};
      if (defined($y)) {
         substr($code, pos($code)-length($w), length($w)) = $y;
         pos($code) += length($y) - length($w);
      }
   }
   my $seq = '';
   while ($code =~ /./g) {
      my $bp = $map{lc $&};
      $seq .= $bp if defined($bp);
   }
   while ($seq =~ s/\<([ACGT]+)\>/rc($1)/ge) {
      pos($seq) = 0;
   }
   $seq =~ s/\{([ACGT]+)\}/muck($1)/ge;
   print ">$name\n$seq\n";
}


__DATA__
F1	the quick brown fox jumps over a lazy dog
F2	the quick brown foxes jump over lazy dogs

N1	waltz, bad nymph, for quick jigs vex
N2	waltzing nymphs for sick fig mex

G1	glib jocks quiz nymph to vex dwarf
G2	glad jacks swizz hymn to text swarms

S1	sphinx of black quartz, judge my vow
S2	wondrous sphinxes of blasted quarry, fudge now my cake

Z1	how quickly daft jumping zebras vex
Z2	quick raft jumping zebra excels

W1	the five boxing wizards jump quickly
W2	see the fine box ink gizzards fill

J1	jackdaws love my big sphinx of quartz
J2	hacksaws loath a big binge of quarry material

B1	pack my box with five dozen liquor jugs
B2	pick my lox with four dozen liuqor rugs

SEA1	All streams flow into the sea, yet the sea is never full
SEA2	To the place the streams come from, there they return again.
SEA3	All things are wearisome, more than one can say.
SEA4	The eye never has enough of seeing, nor the ear its fill of hearing.
SEA	All streams flow into the sea, yet the sea is never full. To the place the streams come from, there they return again. All things are wearisome, more than one can say. The eye never has enough of seeing, nor the ear its fill of hearing.

