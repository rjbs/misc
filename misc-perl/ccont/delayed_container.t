package Now_Later;

use base qw(Class::Container);

__PACKAGE__->valid_params(
  now => { isa => 'Now_Later::Now' }
);

__PACKAGE__->contained_objects(
  now   => 'Now_Later::Now',
  later => { class => 'Now_Later::Later', delayed => 1 }
);

package Now_Later::Now;
use base qw(Class::Container);

__PACKAGE__->valid_params();

package Now_Later::Later;
use base qw(Class::Container);

__PACKAGE__->valid_params();

package main;

use Test::More 'no_plan';

my $nl = Now_Later->new;

isa_ok($nl,        "Now_Later");
isa_ok($nl->{now}, "Now_Later::Now");

is($nl->container, undef, "parent object has no container");

isa_ok($nl->{now}->container, "Now_Later");

my $later = $nl->create_delayed_object('later');

isa_ok($later, "Now_Later::Later");
isa_ok($later->container, "Now_Later");

1;
