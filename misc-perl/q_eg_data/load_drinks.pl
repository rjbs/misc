#!/usr/bin/perl
use strict;
use warnings;

use DBI;

unlink "drinks.db" if $ARGV[0] eq 'clean';

my $dbh = DBI->connect("dbi:SQLite:dbname=drinks.db");

$dbh->do(<<""
CREATE TABLE drinks (
	drink_id INTEGER PRIMARY KEY,
	name NOT NULL
)

);

$dbh->do(<<""
CREATE TABLE ingredients (
	drink_id,
	liquor,
	PRIMARY KEY ( drink_id, liquor )
)

);

my $drink_sth = $dbh->prepare("
	INSERT INTO drinks (drink_id, name)
	VALUES (NULL, ?)
");

my $stuff_sth = $dbh->prepare("
	INSERT INTO ingredients (drink_id, liquor)
	VALUES (?, ?)
");

while (<DATA>) { 
	my ($drink, $contents) = ($_ =~ /^([ a-z]+):\s+(.+)\s*$/ms)
		or next;
	my @contents = split /\s+/, $contents;
	
	print "$drink - ", join(', ',@contents), "\n";

	$drink_sth->execute($drink);
	my $drink_id = $dbh->last_insert_id(undef, undef, undef, undef);
	$stuff_sth->execute($drink_id, $_) for @contents;
}

print $DBI::ERRSTR if $DBI::ERRSTR;
print "\n\n";

__DATA__
black russian: kalhua vodka
bourbon sour: bourbon sour
gin and tonic: gin tonic
grasshopper: cream kalhua creme_de_menthe
manhattan: whiskey vermouth
martini: gin vermouth
scotch and soda: scotch tonic
white russian: kalhua vodka cream
