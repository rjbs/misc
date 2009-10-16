package LinkyUserLinkTag;
use base qw(LinkyDBI);

__PACKAGE__->table('useruritags');

__PACKAGE__->columns(Primary => qw(useruri tag));

__PACKAGE__->has_a(useruri => 'LinkyUserLink');

1;
