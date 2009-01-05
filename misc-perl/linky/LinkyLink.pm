package LinkyLink;
use base qw(LinkyDBI);

__PACKAGE__->table('uris');

__PACKAGE__->columns(All => qw(id uri));

__PACKAGE__->has_a(uri => 'URI', deflate => 'as_string');

sub stringify_self { $_[0]->uri->as_string }

1;
