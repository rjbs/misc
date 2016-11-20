use 5.14.1;
use Test::More;
sub reset_xy;

=pod

Snippets from L<perlsyn>:

   $a      $b        Type of Match Implied    Matching Code
   ======  =====     =====================    =============
   Any     undef     undefined                !defined $a

   Any     Object    invokes ~~ overloading on $object, or dies

   ⋮

   Object  Any       invokes ~~ overloading on $object, or falls back:

=cut

my $x = bless { x_key => 1 } => X::;
my $y = bless { y_key => 1 } => Y::;
my $n = bless { n_key => 1 } => N::; # no overload

reset_xy;

xy_are(0, 0);

$x ~~ undef;
xy_are(0, 0); # first case -- do not invoke overloading if rhs is undef

undef ~~ $x;
xy_are(1, 0); # second case -- do invoke overloading if rhs is object

reset_xy;
xy_are(0, 0);

# Here is one problem case:  perlsyn says that the first applicable row
# applies, so ($x ~~ $y) should match (Any, Object) and call overloading on $y.
# Instead, though, it matches (Object, Any) -- way down below -- and calls
# overloading on $x.
$x ~~ $y;
xy_are(0, 1);

# ...and the solution isn't just that objects get checked first!  If the lhs is
# an object, but one without overloading, then (Any, Object) *is* matched and
# we invoke only the rhs overloading.
reset_xy;
xy_are(0, 0);
$n ~~ $x;
xy_are(1, 0);

# So, (Object, Any) actually takes precedence to (Any, Object) if the lhs is
# overloaded.  Does that mean we can just move the (Object, Any) rule up toward
# the top?  To test, I picked a random rule from between (*,O) and (O,*) --
# (Any, Regexp).  It comes just before (Object, Any), so it should match
# against the stringification of the lhs.  It turns out that (Object, Any) will
# take precedence over (Any, Regexp) -- violating the docs -- if the object has
# ~~ overloading.  If it does not, we go normally down the overloading.
reset_xy;
xy_are(0, 0);
$x ~~ qr{HASH};
xy_are(0, 0, "after Object~~Regex");

ok( ($n ~~ qr{HASH}), '$obj~~qr{} matches against object stringification');

# Another rule found between (Any, Object) and (Object, Any) is (Any, Hash).
# It tests whether $rhs->{ $lhs } exists.  It works as expected.
ok( $n ~~ { $n => 1 }, '$obj ~~ { "$obj" => 1 }');

# As a side effect of this inquiry, I found that object without overloading
# still get smartmatched; their guts are not violated, because all matches
# below (Object, Any) are for simple equalities, but... well, whatever.  I
# guess this is what was intended.
reset_xy;
xy_are(0, 0);
my $refaddr = 0 + $n;
ok(  ($n ~~ $refaddr), "object found at given refaddr");
ok( !($n ~~ $refaddr + 1), "object not found at bogus refaddr");

done_testing;

## SUBROUTINES BELOW

my $x_called;
my $y_called;

sub reset_xy { $_ = 0 for ($x_called, $y_called) }
sub xy_are {
  my ($x_want, $y_want, $desc) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  $desc = defined $desc ? "want ($x_want, $y_want) - $desc"
                        : "want ($x_want, $y_want)";

  if ($x_want == $x_called and $y_want == $y_called) {
    pass($desc);
  } else {
    fail($desc);
    diag("want: ($x_want, $y_want)");
    diag("have: ($x_called, $y_called)");
  }
}

package X { use overload '~~' => sub { $x_called++; return 1 }, fallback => 1; }
package Y { use overload '~~' => sub { $y_called++; return 1 }, fallback => 1; }
package N { }
