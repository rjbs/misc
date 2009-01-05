#!/usr/bin/perl

use Test::More (no_plan);

use File::MFN::Media;

my $mfn = File::MFN::Media->new;

my %tests = (
	'01 someRandomCrap.foo'     => '01-some_random_crap.foo',
	'test_file.txt'             => 'test_file.txt',
	'testFile.txt'              => 'test_file.txt',
	'_..And Justice For All'    => 'and_justice_for_all',
	'Closer to God (Remix).MP3' => 'closer_to_god-remix.mp3'
);

while (my ($test,$want) = each %tests) {
	is($mfn->mogrify($test),$want,$test);
}
