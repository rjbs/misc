#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use lib('../lib/','lib/');
use Module::CPANTS::Generator;
use Module::CPANTS::DB;

my %opts;
GetOptions(\%opts,qw(limit:i force test:s verbose));

my $cpants=Module::CPANTS::Generator->new(\%opts);

#Module::CPANTS::Generator::Authors->fill_authors($cpants);

$cpants->analyse_cpan;


