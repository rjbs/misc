#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

use lib('../lib/','lib/');



use Module::CPANTS::Generator;
use Module::CPANTS::DB;

my $cpants=Module::CPANTS::Generator->new;

my @indicators=$cpants->get_indicators;
print "Available Kwalitee: ".@indicators."\n";

