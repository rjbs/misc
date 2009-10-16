package WWD;

=head1 NAME

WWD - White Wolf Dice

=cut

use base qw(Games::Die::Dice);

sub result_class { 'WWD::Result' }

package WWD::Result;
use base qw(Games::Die::Dice::Result);

sub successes {
	my ($self) = @_;
	my $successes = 0;
	for ($self->rolls) {
		$successes++ if $_ >= $self->{dice}{difficulty};
		$successes-- if $_ == 1;
	}
	return $successes;
}

sub total { (shift)->successes }

1;
