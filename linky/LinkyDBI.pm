package LinkyDBI;
use base qw(Class::DBI);
use Class::DBI::AbstractSearch;

__PACKAGE__->connection('dbi:SQLite:dbname=linky.db',undef,undef);

1;
