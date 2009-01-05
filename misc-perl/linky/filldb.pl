use LinkyLink;
use LinkyUser;

my @links = (
	'http://www.cnn.com/',
	'http://www.cnn.com',
	'http://rjbs.manxome.org/bryar/bryar.cgi'
);

for (@links) {
	my $uri = URI->new($_);
	my $link = LinkyLink->find_or_create({
		uri => $uri->canonical
	});
	print $link->id, " - ", $link->uri, "\n";
}

LinkyUser->create({ username => 'rjbs' });
LinkyUser->create({ username => 'mdxi' });
LinkyUser->create({ username => 'jcap' });

LinkyUserLink->create({
	uri => 1,
	username => 'rjbs',
	title => 'CNN'
})->add_to_tags({tag => 'news'})->update;

for my $user (LinkyUser->retrieve_all) {
	$user->add_to_links({uri => 2});
}
