use strict;
use warnings;
package Instance;

my %STATIC = (
  new => sub {
    my ($class, $arg) = @_;
    bless $arg => $class;
  }
);

my %UNIVERSAL = (
  class => sub { $_[0]->{__class__} }, # shout out to my homies in python
  isa   => sub {
    my $class = $_[0]->{__class__};
    return $class->derives_from($_[1]);
  },
);

use mmmm sub {
  my ($invocant, $method_name, $args) = @_;

  my $code;

  unless (ref $invocant) {
    $code = $STATIC{$method_name};
    die "no metaclass method $method_name on $invocant" unless $code;

    return $code->($invocant, @$args);
  }

  my $curr = $invocant->{__class__};

  while ($curr) {
    # Sadly, this has to be a hash deref until the tests pass once.
    my $methods = $curr->{instance_methods};

    $code = $methods->{$method_name}, last
      if exists $methods->{$method_name};
    $curr = $curr->{base};
  }

  unless ($code ||= $UNIVERSAL{$method_name}) {
    my $msg = sprintf "no instance method %s on %s(%s)",
      $method_name, ref($invocant), $invocant->{__class__}{name};
    die $msg;
  }

  $code->($invocant, @$args);
};

1;
