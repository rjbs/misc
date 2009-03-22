use strict;
use warnings;
use Test::More 'no_plan';

require Class;
require Instance;

my $parent_class = Class->new({
  name             => 'ParentClass',
  class_methods    => { ping  => sub { 'pong' }, pong => sub { 'ping' } },
  instance_methods => { plugh => sub { 'fool' }, y2   => sub { 'y2'   } },
});

my $child_class = $parent_class->new_subclass({
  name             => 'ChildClass',
  class_methods    => { ping  => sub { 'reply' }, foo => sub { 'bar' } },
  instance_methods => { plugh => sub { 'xyzzy' }, foo => sub { 'fee' } },
});

is(ref $parent_class, 'Class', 'check ref of ParentClass');
is(ref $child_class,  'Class', 'check ref of ChildClass');

is($parent_class->name, 'ParentClass', 'name of ParentClass');
is($child_class->name,  'ChildClass',  'name of ChildClass');

is($parent_class->ping, 'pong',  'ping ParentClass');
is($child_class->ping,  'reply', 'ping ChildClass');

is($parent_class->pong, 'ping', 'pong ParentClass');
is($child_class->pong,  'ping', 'pong ChildClass');

eval { $parent_class->foo };
like($@, qr/no class method/, 'no "foo" on ParentClass');
is($child_class->foo, 'bar', 'foo on ChildClass');

is($parent_class->instance_class, 'Instance', 'ParentClass i_c is Instance');
is($child_class->instance_class,  'Instance', 'ChildClass i_c is Instance');

my $parent_instance = $parent_class->new;
is(ref $parent_instance, 'Instance', 'check ref of ParentInstance');

my $child_instance  = $child_class->new;
is(ref $child_instance,  'Instance', 'check ref of ChildInstance');

ok(
  $parent_instance->class == $parent_class,
  "parent instance's class is ParentClass",
);

eval { $parent_instance->new };
like($@, qr/no instance method/, 'there is no "new" instance method');

is($parent_instance->plugh, 'fool',  'plugh on parent instance');
is($child_instance->plugh,  'xyzzy', 'plugh on child instance');

eval { $parent_class->plugh };
like($@, qr/no class method/, 'there is no class "plugh" on ParentClass');

ok($parent_instance->isa($parent_class), 'PI isa PC');
ok($child_instance->isa($parent_class), 'CI isa PC');
