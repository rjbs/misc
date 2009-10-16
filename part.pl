

sub part(&@) {
  my ($code, @list) = @_;

  my @parts;

  for (@list) { push @{ $parts[ $code->($_) ] }, $_ }

  return @parts;
}

use Data::Dump::Streamer;
Dump(part { $_ > 10  ? 1 : 0 } qw(2 4 5 8 10 12 14 16 18) );
