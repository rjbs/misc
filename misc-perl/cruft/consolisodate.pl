#!/usr/bin/perl

# by rjbs
# origin: 2003-06 when converting epic logs to irssi naming convention
# takes a number of files with iso8601 datetimes as their names and
# aggregates them, in proper order, into by-date files

@files = <*-*>;

%entries;
foreach $f (@files) { 
	$f =~ /^(.+)T(.+)$/;
	$date = $1; $time = $2;
	push @{$entries{$date}}, $time;
	print "--> ${date}T${time}\n";
}

foreach $d (sort keys %entries) {
	print "--> $d\n";
	open OPF, ">$d";
	foreach $t (sort @{$entries{$d}}) {
		print "----> ${d}T${f}\n";
		open FL, "${d}T$t";
		while (<FL>) { print OPF $_; }
		close FL;
	}
	close OPF;
}
