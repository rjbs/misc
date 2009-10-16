#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use PDF::API2;
use XML::Simple;

my $pdf = PDF::API2->open('wg7.pdf');

my %info = $pdf->info;

warn Dumper(\%info);

my @fields = $pdf->infoMetaAttributes;

warn Dumper(\@fields);

my $xml = $pdf->xmpMetadata;
print "$xml\n";

my $ref = XMLin($xml);
use Data::Dumper;
warn Dumper($ref);
