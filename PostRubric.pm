#!/usr/bin/perl -w

package PostRubric;

use LWP::UserAgent;

sub add_entry { shift;
	my $entry = shift;

	my $agent = LWP::UserAgent->new;

	my $result = $agent->post("http://rjbs.manxome.org/rubric/post/", {
		uri   => $entry->{uri},
		title => $entry->{title},
		tags  => $entry->{tags},
		body  => $entry->{body},
		description => $entry->{subtitle},
		submit   => 'save',
		user     => 'rjbs',
		password => '45tr1d',
	});

  # die "can't post: $result" unless $result->is_success;
}

1;
