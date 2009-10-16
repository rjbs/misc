package Test::Fathom;

=head1 NAME

Test::Fathom - is your code comprehensible enough?

=cut

use Test::More;
use B::Fathom;
use List::Util qw(sum);

sub import { shift; plan @_ }

sub fathom_avg_cmp {
	my $package = shift;
	$f = B::Fathom->new;

	eval "require $package" or die $@;
	@scores =
		map { $f->score($_) }
		map { *{$package."::$_"}{CODE} || () } keys %{$package."::"};

	my $avg = sum(@scores) / @scores;

	cmp_ok($avg, $_[0], $_[1], $_[2])
}

1;
