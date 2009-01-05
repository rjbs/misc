use LinkyUser;
use LinkyUserLink;

my $uname = shift;
my @users = $uname ? LinkyUser->retrieve($uname) : LinkyUser->retrieve_all;
my $tags  = [@ARGV] if @ARGV;

for my $user (@users) {
	print "user: ", $user->username, "\n";
	#for ($user->links) {
	my %search = ( user => $user );
	$search{tags} = $tags if $tags;
	for (LinkyUserLink->by_tag(\%search)) {
		print " ", $_->title, ": ", $_->uri->uri;
		print "("; print join(',',$_->tags); print ")";
		print "\n";
	}
}
