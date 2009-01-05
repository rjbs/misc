#!/usr/bin/perl

use strict;
use warnings;

use Text::CSV_XS;
use Data::Dumper;

my $decomma = Text::CSV_XS->new;
my $desemi  = Text::CSV_XS->new({sep_char => ';'});

my $roget_filename = ($ARGV[0] || './src/roget15a.txt');

my $types = qr/(Adj|Adv|Int|N|Phr|Pron|V)/;

open my $roget, '<', $roget_filename
	or die "couldn't open $roget_filename: $!";

my %section = bloom_entries(parse_file($roget));

for (
	sort { ($a->{major} <=> $b->{major}) || ($a->{minor} cmp $b->{minor}) }
	values %section
) {
	print "$_->{major}", $_->{minor}||'', ": $_->{name}";
	print " (", join(', ',@{$_->{comments}}), ")" if
		@{$_->{comments}};
	print "\n";

	for my $subsection (@{$_->{subsections}}) {
		print " * ($subsection->{type})\n";

		for my $group (@{$subsection->{groups}}) {
			print "  *\n";

			for (@{$group->{entries}}) {
				print "   * $_->{text}\n"
			}
		}
	}
}

### BEGIN FUNCTIONS

sub parse_file {
	my $previous_section;
	my %section;

	my $peeked_line;
	my ($in_newheader, $in_longcomment);

	while (my $line = ($peeked_line || <$roget>)) {
		undef $peeked_line;

		chomp $line;
		next unless $line;
		next if ($line =~ /^#/); # comment

		if ($line =~ /^<--/) { $in_longcomment = 1; }
		if ($line =~ /-->$/) { $in_longcomment = 0; next; }
		next if $in_longcomment;

		if ($line =~ /^%/) {
			$in_newheader = not $in_newheader;
			next;
		}
		next if $in_newheader;

		$line =~ s/^\s+//;

		until ($peeked_line) {
			$peeked_line = <$roget>;
			last unless defined $peeked_line;
			chomp $peeked_line;
			if ($peeked_line and $peeked_line !~ /^\s{4}/
				and $peeked_line !~ /^(?:#|%|<--)/)
			{
				$line .= " $peeked_line";
				undef $peeked_line;
				if ($line =~ /[^,]+,[^.]+\.\s{4}/) {
					($line, $peeked_line) = split /\s{4}/, $line, 2;
				}
			}
		}

		my ($sec, $title, $newline) =
			($line =~ /^#?(\d+[a-z]?). (.*?)(?:--(.*))?$/);
		$line = ($newline||'') if ($sec);

		if ($sec) {
			(my($comment_beginning), $title, my($comment_end)) =
				($title =~ /(?:\[(.+?)\.?\])?\s*([^.]+)\.?\s*(?:\[(.+?)\.?\])?/);
			$title =~ s/\s{2,}//g;
			$section{$sec} = {
				name        => $title,
				subsections => [ { text => $line||'' } ],
				comments    => [ grep { defined $_ } ($comment_beginning, $comment_end) ]
			};
			@{$section{$sec}}{qw[major minor]} = ($sec =~ /^(\d+)(.*)$/);
			die "$sec" unless $section{$sec}{major};
			$previous_section = $sec;
		} else {
			$section{$previous_section}{subsections} ||= [];
			push @{$section{$previous_section}{subsections}}, { text => $line };
		}
	}
	return %section;
}

sub bloom_entries {
	my %section = @_;

	for (values %section) {
		my $previous_subsection;
		for my $subsection (@{$_->{subsections}}) {
			$subsection->{text} =~ s/\.$//;
			$subsection->{text} =~ s/ {2,}/ /g;
			$subsection->{text} =~ s/(^\s+|\s+$)//;

			if (my ($type) = ($subsection->{text} =~ /^$types\./)) {
				$subsection->{text} =~ s/^$type\.//;
				$subsection->{type} = $type;
			} elsif ($previous_subsection) {
				$subsection->{type} = $previous_subsection->{type};
			} else {
				$subsection->{type} = 'UNKNOWN';
			}

			$desemi->parse($subsection->{text});
			$subsection->{groups} = [ map { { text => $_ } } $desemi->fields ];

			for my $group (@{$subsection->{groups}}) {
				$decomma->parse($group->{text});
				$group->{entries} = [ map { { text => $_, flags => [] } } $decomma->fields ];

				for (@{$group->{entries}}) {
					$_->{text}||= 'UNPARSED';
					if ($_->{text} =~ s/\[obs3\]//) {
						push @{$_->{flags}}, 'archaic? (1991)';
					}
					if ($_->{text} =~ s/|!//) {
						push @{$_->{flags}}, 'obsolete (1991)';
					}
					if ($_->{text} =~ s/|//) {
						push @{$_->{flags}}, 'obsolete (1911)';
					}
					$_->{text} =~ s/(^\s+|\s+$)//;
				}
			}
			$previous_subsection = $subsection;
		}
	}

	return %section;
}
