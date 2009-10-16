
use YAML;
use LinkyLink;
use LinkyUser;

my $links = YAML::LoadFile('delicious.yml');
my $rjbs = LinkyUser->retrieve('rjbs');

foreach (@$links) {
	my $uri = LinkyLink->find_or_create({uri => $_->{href}});
	my $link = $rjbs->add_to_links({
		uri => $uri,
		title => $_->{description},
		description => $_->{extended}
	});
	$link->add_to_tags({tag => $_}) for @{$_->{tags}};
}

$rjbs->update;
