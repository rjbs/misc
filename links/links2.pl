#!/usr/bin/perl

## links D2 [2002-07-05]
## 	usage: links <bookmarks.html> <output_dir>

use strict;

use Netscape::Bookmarks;

use vars qw[
	$bookmarks
	@forbidden
	$footer
	$footerfile
	$header
	$headerfile
	$outputdir
	$root
	@tree
];

$bookmarks = $ARGV[0];

@forbidden = qw[rjbs];

$headerfile = './skel/header';

$footerfile = './skel/footer';

$outputdir = $ARGV[1];

sub dump_category($) {
	my ($args) = @_;

	my $category = $args->{category};

		if ($category->links) {
			printf "<dl class='h%u'>\n", @tree + 2;
			foreach my $link ($category->links) {
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
		}
		print "</dl>\n";

	foreach my $cat ($category->categories) {

		if (grep { $cat->title eq $_ } @forbidden) { next; }

		push @tree, $cat->title;
		
		printf "<h%u id='%s'>%s</h%u>\n",
			@tree + 2,
			join('.',@tree[1 .. ($#tree)]),
			join('.',@tree),
			@tree + 2
		;

		if ($cat->description) {
			print "<blockquote>\n\t", $cat->description, "\n</blockquote>";
		}

		dump_category({ category => $cat });

		pop @tree;

	}

}

unless ($bookmarks) {
	print "links: usage: links <bookmarks.html> <output_dir>\n";
	exit 1;
}

until (-d $outputdir && -x _ && -w _) {
	unless (mkdir $outputdir) {
		print "links: output directory couldn't be found or created\n";
		exit 2;
	} else {
		print "<!> output directory created\n";
	}
}

unless ($root = Netscape::Bookmarks->new($bookmarks)) {
	print "links: couldn't open bookmarks file\n";
	exit 4;
}

open HF, $headerfile;
while (<HF>) { $header .= $_; }

open FF, $footerfile;
while (<FF>) { $footer .= $_; }

open my $fh, ">$outputdir/index.shtml";

select $fh;

{ my $header = $header; $header =~ s/TITLE/RJBS :: Links/; print $header; }

foreach my $cat ($root->categories) {

	if (grep { $cat->title eq $_ } @forbidden) { next; }

	print "<h3><a href='" . $cat->title . "'>" . $cat->title . "</a></h3>\n";
	print "<p>\n\t", $cat->description, "\n</p>\n";

	push @tree, $cat->title;
		
		open my $fx, (">$outputdir/" . $cat->title . ".shtml");
		select $fx;
		my $header = $header;
		$header =~ s/TITLE/join(' :: ',('RJBS', 'Links', @tree))/e;
		print $header;

		printf "<h%u>%s</h%u>\n",
			@tree + 2,
			join('.',@tree),
			@tree + 2
		;

		dump_category({ category => $cat });
		print $footer;
		close $fx;
	
	pop @tree;

	select $fh;
	
}

select $fh;

print $footer;

close $fh;
