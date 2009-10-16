use Rubric::User;
$rjbs = Rubric::User->retrieve('rjbs');
for my $entry ($rjbs->entries) {
	next unless $entry->body =~ /h4/;
	$body = $entry->body;
	$body =~ s/\s*(<h\d>(?:[^<]+)<\/h\d>)\s*/$1/g;
	$entry->body($body);
	$entry->update;
}
