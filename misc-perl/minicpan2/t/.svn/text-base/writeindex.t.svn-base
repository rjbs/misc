use Test::More 'no_plan';

BEGIN { use_ok('CPAN::Mini::Archive'); }
BEGIN { use_ok('CPAN::Mini::Archive::WriteIndex'); }

use Cwd;
use URI;

my $root = URI->new("file://" . cwd . "/cpan/");

my $archive = CPAN::Mini::Archive->new(root => $root);

isa_ok($archive, "CPAN::Mini::Archive");

$packages = CPAN::Mini::Archive::WriteIndex->__02packages_content($archive);
$mailrc   = CPAN::Mini::Archive::WriteIndex->__01mailrc_content($archive);

ok($packages, "got non-empty packages index");
ok($mailrc,   "got non-empty mailrc index");
