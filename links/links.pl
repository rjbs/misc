#!/usr/bin/perl

use strict;

use Netscape::Bookmarks;

my @forbidden = qw[rjbs];

my @tree;

my $links = Netscape::Bookmarks->new($ARGV[0]);

sub dump_category($) {
	my ($args) = @_;

	my $category = $args->{category};
	my $recurse = $args->{recurse};

	foreach my $cat ($category->categories) {

		if (grep { $cat->title eq $_ } @forbidden) { next; }
		
		push @tree, $cat->title;

		printf "<h%u>%s</h%u>\n",
			@tree + 2,
			join('.',@tree),
			@tree + 2
		;

		if ($cat->links) {
			printf "<dl class='h%u'>\n", @tree + 2;
			foreach my $link ($cat->links) {
				printf "<dt><a href='%s'>%s</a></dt>\n",
					$link->href,
					$link->title
				;

				if ($link->description) {
					printf "<dd>%s</dt>\n",
						$link->description
					;
				}
			}
			print "</dl>\n";
		}
			
		dump_category({ category => $cat, recurse => 1});

		pop @tree;

	}
}

sub print_header {

print "

<?xml version='1.0' encoding='UTF-8'?>
<!DOCTYPE html
	PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 
	'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'
> 
<html>

<head>
	<title>" , join(' :: ',('RJBS', 'Links', @tree)) , "</title>
	<link rel='stylesheet' type='text/css' href='http://www.manxome.org/style/manxome.css' /> 
	<style type='text/css'>
  		div#content h3 {
			color: #ffffff; background-color: #000000;
			padding-top: .25em; padding-bottom: .25em;
			padding-left: 1em;
			font-size: 125%;
		}
		dl.h3 { margin-left: 1em; }
  		div#content h4 {
			color: #ffffff; background-color: #666666;
			padding-top: .25em; padding-bottom: .25em;
			padding-left: 2em;
			font-size: 125%;
		}
		dl.h4 { margin-left: 2em; }
  		div#content h5 {
			color: #ffffff; background-color: #888888;
			padding-top: .25em; padding-bottom: .25em;
			padding-left: 3em;
			font-size: 125%;
		}
		dl.h5 { margin-left: 3em; }
  		div#content h6 {
			color: #ffffff; background-color: #aaaaaa;
			padding-top: .25em; padding-bottom: .25em;
			padding-left: 4em;
			font-size: 125%;
		}
		dl.h6 { margin-left: 4em; }
	</style>
</head>

<body>

<div id='header'>
	<h1>Ricardo Signes</h1>
	<h2>sites of interest</h2>
</div>

<div id='content'>
"

}

print_header;

dump_category({category => $links, recurse => 1});

print <<EOH
<!--#include virtual='/copy.html' -->

</body>

</html>
EOH
;

