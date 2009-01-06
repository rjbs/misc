use strict;
use warnings;
use OnMeth;
use Test::More 'no_plan';

{
  # Our test example will be a very, very simple classless/prototype calling
  # system. -- rjbs, 2008-05-16
  package CLR; # classless root

  use overload invoke_method => 'invoke_method';

  sub new {
    my ($class, %attrs) = @_;
    my $root = {
      new => sub {
        my ($parent, %attrs) = @_;
        bless { %attrs, parent => $parent } => $class;
      },
      get => sub {
        my ($self, $attr) = @_;
        my $curr = $self;
        while ($curr) {
          return $curr->{$attr} if exists $curr->{$attr};
          $curr = $curr->{parent};
        }
        return undef;
      },
      set => sub {
        my ($self, $attr, $value) = @_;
        return $self->{$attr} = $value;
      },
      %attrs,
      parent => undef,
    };

    bless $root => $class;
  }

  sub invoke_method {
    my ($class, $object, $method, $args) = @_;

    my $curr = $object;
    while ($curr) {
      return $curr->{$method}->($object, @$args) if exists $curr->{$method};
      $curr = $curr->{parent};
    }

    die "unknown method $method called on $class object";
  }
}

my $old_call = sub {
  my ($obj, $method, $args) = @_;
  CLR->invoke_method($obj, $method, $args);
};

my $new_call = sub {
  my ($obj, $method, $args) = @_;
  $obj->$method(@$args);
};

OnMeth->test_with_rigs(sub {
  my $call = shift;
  my $root_a  = CLR->new;
  my $child_a = $call->($root_a,  new => [ status => sub { 'OK!' } ]);
  my $child_b = $call->($child_a, new => [ status => sub { 'ok?' } ]);

  eval { $call->($root_a,  'status') };
  like($@, qr/\Aunknown method status called on CLR obj/, "no status on root");

  is(
    $call->($child_a, 'status'),
    'OK!',
    'child object answers status method',
  );

  is(
    $call->($child_b, 'status'),
    'ok?',
    'grandchild object answers status method, too',
  );

  $call->($child_a, set => [ generation => 2 ]);

  is(
    $call->($root_a, get => [ 'generation' ]),
    undef,
    'no generation value on root',
  );

  is(
    $call->($child_a, get => [ 'generation' ]),
    2,
    'we got a generation value from child',
  );

  is(
    $call->($child_a, get => [ 'generation' ]),
    2,
    '...which is inherited by the grandchild',
  );
});

__END__
# The way this code would really be written is:

my $root_a  = CLR->new;
my $child_a = $root_a->new(status => sub { 'OK!' });
my $child_b = $child_a->new(status => sub { 'ok?' });

eval { $root_a->status; };
like($@, qr/\Aunknown method status called on CLR obj/, "no status on root");

is(
  $child_a->status,
  'OK!',
  'child object answers status method',
);

is(
  $child_b->status,
  'ok?',
  'grandchild object answers status method, too',
);

$child_a->set(generation => 2);

is(
  $root_a->get('generation'),
  undef,
  'no generation value on root',
);

is(
  $child_a->get('generation'),
  2,
  'we got a generation value from child',
);

is(
  $child_a->get('generation'),
  2,
  '...which is inherited by the grandchild',
);
