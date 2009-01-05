#!/usr/bin/perl

## by rjbs
## origin: unknown
## seems to look through files in a maildir and print any found IPs

use strict;

my $from="~/Maildir/.spam/cur";
my $to="~Maildir/.spam/ordb-processed/cut"; # why was this here?

my %ip;

my @files=glob("$from/*");

foreach my $file (@files) {
	open(MAIL, $file);
	while (my $inline=<MAIL>) {
		chomp $inline;
		if ($inline =~ /([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})/) {
		$ip{$1}=1;
			print "$1\n";
		}
	}
	close(MAIL);
}

print join("\n",sort keys %ip);
