package Module::Picker;
use strict;
use warnings;

sub pick_packages {
  my ($self, $packages, $test) = @_;

  my @packages =
    grep { $_->version ne 'undef' }
    map  { @{ $_->packages } }
    grep { $test->($_) }
    $packages->latest_distributions;
}

1;
