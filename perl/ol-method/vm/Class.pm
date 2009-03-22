use strict;
use warnings;
package Class;

my %STATIC = (
  new => sub {
    my ($pkg, $arg) = @_;
    my $class = bless $arg => $pkg;
  },
);

my %UNIVERSAL = (
  new  => sub {
    # XXX: Why does this panic and memory wrap? -- rjbs, 2009-03-21
    bless { __class__ => $_[0] } => 'Instance'; # $_[0]->instance_class
  },
  name => sub { $_[0]->{name} },
  base => sub { $_[0]->{base} },
  new_subclass     => sub {
    my ($class, $arg) = @_;
    my $pkg = ref $class;
    my $new = { %$arg, base => $class };
    bless $new => $pkg;
  },
  instance_class   => sub { 'Instance' },
  class_methods    => sub { $_[0]->{class_methods} },
  instance_methods => sub { $_[0]->{instance_methods} },
  derives_from     => sub {
    my ($self, $super) = @_;

    # Nothing wrong with this! -- rjbs, 2009-03-21
    return unless (ref $self)->UNIVERSAL::isa('Class');

    my $curr = $self;
    while ($curr) {
      return 1 if $curr == $super;
      $curr = $curr->{base};
    }
    return;
  },
);

use mmmm sub {
  my ($invocant, $method_name, $args) = @_;
  my $curr = $invocant;
  my $code;

  unless (ref $invocant) {
    die "no metaclass method $method_name on $invocant"
      unless $code = $STATIC{$method_name};

    return $code->($invocant, @$args);
  }

  while ($curr) {
    my $methods = $curr->{class_methods};
    $code = $methods->{$method_name}, last
      if exists $methods->{$method_name};
    $curr = $curr->{base};
  }

  Carp::confess("no class method $method_name on $invocant->{name}")
    unless $code ||= $UNIVERSAL{$method_name};

  $code->($invocant, @$args);
};
1;
