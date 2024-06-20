#!/usr/bin/perl -n

use warnings;
use strict;

chomp;
my ($time, $descr) = split "\t";

$time =~ /0*(\d+)m0*(\d+)\.0*(\d+)/ || die "Cannot match $time";

my ($min, $sec, $mls) = ($1, $2, $3);

my $duration = 1000 * $sec + $mls;

my @bricks = split '-', '▏-▎-▍-▌-▋-▊-▉-█';

sub makebar {
   my $N = shift;
   my $remainder = $N % 8;
   my $n8 = ($N - $remainder) / 8;
   my $bar = $bricks[-1] x $n8;
   $bar .= $bricks[$remainder-1] if $remainder;
   return ($bar, $n8 + ($remainder ? 1 : 0));
}

my $N = int($duration/3);
my ($bar, $barlen) = makebar($N);

printf "%s%s %10d %s\n", $bar, ' ' x (100 - $barlen),  $duration,  $descr;


