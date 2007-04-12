#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use lib('../lib/','lib/');
use Module::CPANTS::Generator;
use Module::CPANTS::DB;

my %opts;
GetOptions(\%opts,qw(verbose));

my $file=shift(@ARGV);
exit "cannot read file" unless -e $file;

my $cpants=Module::CPANTS::Generator->new(\%opts);
$cpants->lint_file($file);

$cpants->analyse_dist($file);
Module::CPANTS::DB->link_dists_modules;

print "Kwalitee:\n";
$cpants->calc_kwalitee;
print "Detailed information is available in the sqlite3 DB file\n";


