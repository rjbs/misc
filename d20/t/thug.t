use Test::More 'no_plan';

BEGIN { use_ok( 'Games::d20::Character' ); }

my $char = Games::d20::Character->from_file("t/chars/thug.yml");

isa_ok($char, 'Games::d20::Character');

is($char->name,   "Thug Thuggerton");
is($char->race,   "Human");
is($char->gender, "male");
is($char->age,    19);
is($char->alignment,  "Chaotic Evil");
