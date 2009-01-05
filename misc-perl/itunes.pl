#!/usr/bin/perl

use strict;
use warnings;

use Mac::PropertyList;
use Storable ();

my $library_xml = "/Users/rjbs/Music/iTunes/iTunes Music Library.xml";
die "can't read library at $library_xml" unless -r $library_xml;

my $library = Mac::PropertyList::parse_plist_file($library_xml);

Storable::store($library, "library.stor");
