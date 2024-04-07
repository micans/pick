#!/usr/bin/perl

use warnings;
use strict;

my %map = (' ', qw(G e C t T a A o CT i CA n AA s C r TA h AT d AG l GG u GA c TG m GC f TT y AC w GT g CT p CA b AA v CC k TC x TA q AT j AG z CG));
$map{'<'} = '<';
$map{'>'} = '>';

my %predef = ();

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

