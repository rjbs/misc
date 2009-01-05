use strict;
use warnings;

package Object::Capsule;

sub encapsulate {
	my $object = shift;
	bless \$object => 'Object::Capsule';
}

use overload
	'${}'    => sub { $_[0] },
	'""'     => sub { "${$_[0]}" },
	'0+'     => sub { 0 + ${$_[0]} },
	nomethod => sub {
		my $expr = $_[2]
			? "\$_[1] $_[3] \${\$_[0]}"
			: "\${\$_[0]} $_[3] \$_[1]";
		print "# capsule overload eval-ing : $expr\n";
		my $result  = eval $expr;
		print "# capsule overload returning: ", $result, "\n";
		return $result;
	},
;

package Widget;
	sub new  { my $class = shift; bless { @_ } => $class }
	sub size { (shift)->{size} }

	use overload
		'""' => sub { "It's a widget!" },
		'0+' => sub { $_[0]->{size} },
		fallback => 1
	;
package main;

my $widget = new Widget size => 10;
my $capsule = Object::Capsule::encapsulate($widget);

my $result = $capsule eq "It's a widget!";
print "# result of comparison: ", ($result?'true':'false'), "\n";

print "\n";

print "# -- bytes of returned strings --\n";
print "# ", join(' ',map { ord($_) } split //, "$capsule"), "\n";
print "# ", join(' ',map { ord($_) } split //, "It's a widget!"), "\n";

print "\n--(Test::More stuff below this point)--\n";

use Test::More 'no_plan';

isa_ok($widget, 'Widget');
cmp_ok($widget, '==',                10, "widget numifies as intended");
cmp_ok($widget, 'eq',  "It's a widget!", "widget stringifies as intended");

print "\n";

isa_ok($capsule,  'Object::Capsule');
isa_ok($$capsule, 'Widget');
cmp_ok($capsule, '==',               10, "capsule cmp_ok == 10");
cmp_ok($capsule, 'eq', "It's a widget!", "capsule cmp_ok eq the string");
    ok($capsule == 10,               "capsule numifies as intended");
    ok($capsule eq "It's a widget!", "capsule stringifies as intended");

