#!/usr/bin/perl
use Querylet;

database: dbi:SQLite:dbname=drinks.db

query:
	SELECT name
	FROM drinks
	JOIN ingredients ON drinks.drink_id = ingredients.drink_id
	WHERE liquor = '[% required %]'
	ORDER BY name, liquor

munge query:
	required => ($ARGV[0] || die "no required liquor supplied")

add column loud_name:
	$value = uc($row->{name});
	$value =~ tr/ /_/;

delete column name

add column random_abv:
	$value = int(100*rand());

output format: html
