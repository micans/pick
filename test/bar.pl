#!/usr/bin/perl -n

use warnings;
use strict;

chomp;
my ($time, $descr) = split "\t";

$time =~ /0*(\d+)m0*(\d+)\.0*(\d+)/ || die "Cannot match $time";

my ($min, $sec, $mls) = ($1, $2, $3);

my $bar = '-' x ((1000 * $sec + $mls) / 20);

printf "%-100s %s\n", $bar, $descr;


