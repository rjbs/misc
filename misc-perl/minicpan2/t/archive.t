use Test::More 'no_plan';

BEGIN { use_ok('CPAN::Mini::Archive'); }

use Cwd;
use URI;

my $root = URI->new("file://" . cwd . "/fpan/");

my $archive = CPAN::Mini::Archive->new(root => $root);

isa_ok($archive, "CPAN::Mini::Archive");

is($archive->authors,       20, "there! are! twenty! authors!");
is($archive->packages,      43, "archive contains 43 packages");
is($archive->distributions, 26, "archive contains 26 distributions");

is($archive->latest_distributions, 24, "two of those dists are out of date");

ok(
	my $xf = $archive->{_pc_packages}->distribution("A/AT/ATRION/Transformers-1.00.tar.gz"),
	"there's a Transformers distribution"
);

is($xf->contains, 4, "four packages is Transformers");

ok($archive->delete_distribution($xf), "delete Transformers dist");

is($archive->authors,       20, "there! are! twenty! authors!");
is($archive->packages,      39, "archive contains 39 packages");
is($archive->distributions, 25, "archive contains 25 distributions");
