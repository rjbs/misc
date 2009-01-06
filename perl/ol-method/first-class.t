use strict;
use warnings;
use Test::More 'no_plan';
use OnMeth;

{
  {
    package Class;

    sub new {
      my ($class, $arg) = @_;
      bless $arg => $class;
    }

    sub ping { die 'never gonna get called' }

    my %UNIVERSAL = (
      new  => sub { Instance->new({ __class__ => $_[0] }); },
      name => sub { $_[0]->{name} },
      base => sub { $_[0]->{base} },
      class_methods    => sub { $_[0]->{class_methods} },
      instance_methods => sub { $_[0]->{instance_methods} },
      derives_from     => sub {
        my ($self, $super) = @_;
        return unless (ref $self)->isa('Class');
        my $curr = $self;
        while ($curr) {
          return 1 if $curr == $super;
          $curr = $curr->{base};
        }
        return;
      },
    );

    sub invoke_method {
      my ($class, $object, $method, $args) = @_;
      my $curr = $object;
      my $code;

      while ($curr) {
        my $methods = $curr->{class_methods}; # cheat, do not recurse!
        $code = $methods->{$method}, last if exists $methods->{$method};
        $curr = $curr->{base};
      }

      die "no class method $method on $object->{name}"
        unless $code ||= $UNIVERSAL{$method};
      $code->($object, @$args);
    }
  }

  {
    package Instance;

    my %UNIVERSAL = (
      class => sub { $_[0]->{__class__} }, # shout out to my homies in python
      isa   => sub {
        # cheating to bootstrap -- rjbs, 2008-05-16
        my $class = $_[0]->{__class__};
        (ref $class)->invoke_method($class, derives_from => [ $_[1] ]);
      },
    );

    sub new {
      my ($class, $arg) = @_;
      bless $arg => $class;
    }

    sub plugh { die 'never gonna get plughed' }

    sub invoke_method {
      my ($class, $object, $method, $args) = @_;

      my $curr = $object->{__class__};
      my $code;

      while ($curr) {
        # Sadly, this has to be a hash deref until the tests pass once.
        my $methods = $curr->{instance_methods};

        $code = $methods->{$method}, last if exists $methods->{$method};
        $curr = $curr->{base};
      }

      unless ($code ||= $UNIVERSAL{$method}) {
        my $msg = sprintf "no instance method %s on %s(%s)",
          $method, ref($object), $object->{__class__}{name};
        warn $msg;
        die $msg;
      }

      $code->($object, @$args);
    }
  }
}

OnMeth->test_with_rigs(sub {
  my $call = shift;

  my $parent_class = Class->new({
    name             => 'ParentClass',
    class_methods    => { ping  => sub { 'pong' }, pong => sub { 'ping' } },
    instance_methods => { plugh => sub { 'fool' }, y2   => sub { 'y2'   } },
  });

  my $child_class = Class->new({
    name             => 'ChildClass',
    base             => $parent_class,
    class_methods    => { ping  => sub { 'reply' }, foo => sub { 'bar' } },
    instance_methods => { plugh => sub { 'xyzzy' }, foo => sub { 'fee' } },
  });

  is(ref $parent_class, 'Class', 'check ref of ParentClass');
  is(ref $child_class,  'Class', 'check ref of ChildClass');

  is($call->($parent_class, 'name'), 'ParentClass', 'name of ParentClass');
  is($call->($child_class,  'name'), 'ChildClass',  'name of ChildClass');

  is($call->($parent_class, 'ping'), 'pong',  'ping ParentClass');
  is($call->($child_class,  'ping'), 'reply', 'ping ChildClass');

  is($call->($parent_class, 'pong'), 'ping', 'pong ParentClass');
  is($call->($child_class,  'pong'), 'ping', 'pong ChildClass');

  eval { $call->($parent_class, 'foo') };
  like($@, qr/no class method/, 'no "foo" on ParentClass');
  is($call->($child_class,  'foo'), 'bar', 'foo on ChildClass');

  my $parent_instance = $call->($parent_class, 'new');
  my $child_instance  = $call->($child_class,  'new');

  is(ref $parent_instance, 'Instance', 'check ref of ParentInstance');
  is(ref $child_instance,  'Instance', 'check ref of ChildInstance');

  ok(
    $call->($parent_instance => 'class') == $parent_class,
    "parent instance's class is ParentClass",
  );

  eval { $call->($parent_instance, 'new'); };
  like($@, qr/no instance method/, 'there is no "new" instance method');

  is($call->($parent_instance, 'plugh'), 'fool',  'plugh on parent instance');
  is($call->($child_instance,  'plugh'), 'xyzzy', 'plugh on child instance');

  eval { $call->($parent_class, 'plugh'); };
  like($@, qr/no class method/, 'there is no class "plugh" on ParentClass');
  
  ok($call->($parent_instance, isa => [ $parent_class ]), 'PI isa PC');
  ok($call->($child_instance,  isa => [ $parent_class ]), 'CI isa PC');
});
