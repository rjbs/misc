#!/usr/bin/perl

=head1 NAME

tree.pl - print a directory tree

=cut

## by rjbs
## origin: written for phun
## recurses through a directory tree and prints it with indentation

sub recursedir {
	my ($dir, $tab) = @_;

	if (-d $dir) {
		my @dir = glob("$dir/*");
		foreach my $d (@dir) {
			$d =~ /([^\/]+)$/;
			my $fname = $1;
			print "  " x $tab, $fname, "\n" if -d $d;
			if (-d $d) {
				recursedir("$d",$tab+1);
			}
		}
	} else {
		print "error\n";
	}
}

print ".\n";
recursedir('.',1);
