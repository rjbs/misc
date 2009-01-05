#!/usr/bin/perl

use strict;
use warnings;

use DBI;

unlink('linky.db');

my $dbh = DBI->connect('dbi:SQLite:dbname=linky.db',undef,undef);

my $schema;
{
	open my $schema_fh, '<', 'schema.sql';
	local $/ = '*';
	$dbh->do($_) for <$schema_fh>;
}

