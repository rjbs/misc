package LinkyUser;
use base qw(LinkyDBI);

__PACKAGE__->table('users');

__PACKAGE__->columns(All => qw(username));

__PACKAGE__->has_many(links => 'LinkyUserLink' );

1;
