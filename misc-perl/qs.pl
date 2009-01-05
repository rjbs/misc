
=head1 NAME

qs - quicksort in Perl (thanks waltman)

=cut

use strict;

sub qsort { 
	return @_ unless @_ > 1;
	my @bins = ([], [ $_[int rand @_] ], []);
	push @{$bins[ ($_ <=> $bins[1][0]) + 1 ]}, $_ for (@_);
	qsort(@{$bins[0]}), @{$bins[1]}, qsort(@{$bins[2]});
}

print join(' ', qsort(qw! 1 29 102 102 1 12 102938 109283 1092 1 !));
print "\n";
