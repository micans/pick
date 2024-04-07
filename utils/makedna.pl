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
   $seq =~ s/\<([ACGT]+)\>/rc($1)/ge;
   $seq =~ s/\{([ACGT]+)\}/muck($1)/ge;
   print ">$name\n$seq\n";
}


__DATA__
FOX	the quick brown fox jumps over a lazy dog
FAX	the quick brown foxes jump over lazy dogs

NYMPH	waltz, bad nymph, for quick jigs vex
NIMPH	waltzing nymphs for sick fig mex

GLIB	glib jocks quiz nymph to vex dwarf
GLOB	glad jacks swizz hymn to text swarms

SPHINX	sphinx of black quartz, judge my vow
SPHYNX	wondrous sphinxes of blasted quarry, fudge now my cake

ZEBRA	how quickly daft jumping zebras vex
ZEBRO	quick raft jumping zebra excels

WIZARD	the five boxing wizards jump quickly
WAZARD	see the fine box ink gizzards fill

JACKDAW	jackdaws love my big sphinx of quartz
JECKDAW	hacksaws loath a big binge of quarry material

BOX	pack my box with five dozen liquor jugs
BAX	pick my lox with four dozen liuqor rugs

SEA1	All streams flow into the sea, yet the sea is never full
SEA2	To the place the streams come from, there they return again.
SEA3	All things are wearisome, more than one can say.
SEA4	The eye never has enough of seeing, nor the ear its fill of hearing.
SEA	All streams flow into the sea, yet the sea is never full. To the place the streams come from, there they return again. All things are wearisome, more than one can say. The eye never has enough of seeing, nor the ear its fill of hearing.

