package LinkyUserLink;
use base qw(LinkyDBI);

__PACKAGE__->table('useruris');

__PACKAGE__->columns(All => qw(id uri username title description));

__PACKAGE__->has_a(uri      => 'LinkyLink');
__PACKAGE__->has_a(username => 'LinkyUser');

__PACKAGE__->has_many(tags  => [LinkyUserLinkTag=>tag]);

__PACKAGE__->add_trigger(before_create => \&title_default);
__PACKAGE__->add_trigger(before_update => \&title_default);

sub title_default {
	my $self = shift;
	$self->title($self->{title} || 'default');
}

sub by_tag {
	my ($self, $arg) = @_;
	my %wheres;
	if ($arg->{user}) { $wheres{username} = $arg->{user} }
	if ($arg->{tags}) {
		$_ = $self->db_Main->quote($_) for @{$arg->{tags}};
		my $ids = 
			join ' AND ',
			map { "id IN (SELECT useruri FROM useruritags WHERE tag=$_)" }
			@{$arg->{tags}};
		$wheres{''} = \$ids;
	}
	$self->search_where(\%wheres);
}

1;
