#!/usr/bin/perl
use strict;
use warnings;

use DBI;

if ($ARGV[0] eq 'clean') { unlink $_ for <wafers.db*> }

my $dbh = DBI->connect("dbi:SQLite:dbname=wafers.db",undef,undef,{AutoCommit => 0});

$dbh->do("PRAGMA default_synchronous = OFF");

$dbh->do(<<""
CREATE TABLE grown_wafers (
	wafer_id INTEGER PRIMARY KEY,
	reactor_id NOT NULL,
	material NOT NULL,
	diameter NOT NULL,
	product_type,
	failurecode
)

);

$dbh->commit;

$dbh->do(<<""
CREATE TABLE reactors (
	reactor_id NOT NULL
)

);

$dbh->commit;

$dbh->do(<<""
CREATE TABLE failurecodes (
	failurecode NOT NULL,
	brief NOT NULL
)

);

$dbh->commit;

my $reactor_sth = $dbh->prepare("
	INSERT INTO reactors (reactor_id)
	VALUES (?)
");

$reactor_sth->execute($_) for (101 .. 105);

$dbh->commit;

my $fc_sth = $dbh->prepare("
	INSERT INTO failurecodes (failurecode, brief)
	VALUES (?, ?)
");

$fc_sth->execute($_, rand()) for (1 .. 10);

$dbh->commit;

my $wafer_sth = $dbh->prepare("
	INSERT INTO grown_wafers
		(wafer_id, reactor_id, material, diameter, product_type, failurecode)
	VALUES
		(    NULL,          ?,        ?,        ?,            ?,           ?)
");

for my $r (101 .. 105) {
for my $m (qw(GaAs InP GaN Si PB&J)) {
for my $d (2, 3, 4, 6) {
for my $t (qw(Production Calibration)) {
for my $f (1 .. 10) {
	printf "loading: %10s %10s %10s %10s\n", $r, $m, $d, $t, $f;
	$wafer_sth->execute($r, $m, $d, $t, $f);
}}}}}

$dbh->commit;

print $DBI::ERRSTR if $DBI::ERRSTR;
print "\n\n";
