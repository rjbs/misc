use strict;
use warnings;
use Character;
use Template;

my $t = Template->new;

my $char = bless {} => 'Character';

$t->process(\*DATA, { char => $char }) || die Template->error();

__DATA__
                                CHARACTER RECORD
Name: [% char.name %]; [% char.age %]-year old [% char.gender %] [% char.race %]
[% FOREACH class = char.classes %][% class.1 %]-level [% class.0 %]
[% END -%]

Hit Points: [% char.hp %]

== Attributes ================================================================

[%- FOREACH attribute = [ "str", "dex", "con", "int", "wis", "cha" ] %]
[% attribute | format("%5s") %]: [% char.$attribute | format("%2u") %] - (modifier: [% char.modifier_for(char.$attribute) | format("%2d") %])
[%- END %]

== Skills ====================================================================
[%- FOREACH skill = char.skills %]
[%- FILTER format("%20s") %]
[% skill.0 %][% " (" _ skill.1 _ ")" IF skill.1.defined %]:
[% END %] [% skill.2 %][% "*" IF char.rule_notes("skill", skill.0).size %]
[%- END %]

== Notes =====================================================================
[%- FOREACH note = char.rule_notes %]
[% note.0 _ ":" | format("%20s") %] [% note.1 %]
[%- END %]
