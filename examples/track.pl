#!/usr/bin/env perl

use strict;
use warnings;
use lib qw(../lib lib);
use WWW::Purolator::TrackingInfo;

@ARGV or die "Usage: perl $0 PIN_to_track\n";

my $t = WWW::Purolator::TrackingInfo->new;

$t->track(shift) # AJT1395052
    or die $t->error;

use Data::Dumper;
print Dumper $t->info;