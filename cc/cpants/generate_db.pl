#!/usr/bin/perl
use strict;
use warnings;
use DBI;
use File::Copy;

use lib('../lib/','lib/');

use Module::CPANTS::Generator;

my $cpants=Module::CPANTS::Generator->new;

my $schema=$cpants->get_schema;
my $indices=$schema->{'index'};
delete $schema->{'index'};

my $db_file=$cpants->db_file;

if (-e $db_file) {
    move('cpants.db','cpants_previous.db');
    #print "\nCPANTS DB file already exists:\n\t$db_file\nIf the DB schema changed, please run the appropriate DB altering scripts.\n\n";
    #exit;
}

my $DBH=DBI->connect("dbi:SQLite:dbname=$db_file");
while (my($table,$columns)=each%$schema) {
    print "create $table\n";
    $DBH->do("create table $table (\n".join(",\n",@$columns).")\n");
}

foreach (@$indices) {
    $DBH->do($_);
}

