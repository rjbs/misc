package Bryar::DataSource::RJBS;

use Time::Local;
use Bryar::Document::RJBS;

sub search { 
	my ($self, $config, %params) = @_;
	my @documents = $self->all_documents($config);

	return $self->make_document("$config->{entrydir}/$params{id}")
		if ($params{id});

	@documents =
		grep { $_->epoch >= $params{since} } 
		@documents if $params{since};

	@documents =
		grep { $_->epoch <= $params{before} } 
		@documents if $params{before};
	
	@documents =
		grep { $_->{content}  =~ /$params{content}/i
		       or $_->{title} =~ /$params{content}/i }
		@documents if $params{content};

	return @documents[0 .. $params{limit} - 1] if $params{limit};
	return @documents;
}

sub all_documents {
	my ($self,$config) = @_;
	my $entrydir = $config->{entrydir};

	sort { $b->epoch <=> $a->epoch }
	map { $self->make_document($_) }
	grep !/^\./,
	<$entrydir/*>;
}

sub make_document {
	my ($self, $file) = @_;
	return unless $file;
	open(my($in), $file) or return;
	
	my %document;
	
	($document{id}) = $file =~ /([^\/]+)$/;

	while (<$in>) {
	  last unless /:/;
	  $document{title} = $1 if /^title:\s+(.+)/;
	  $document{posted} = $1 if /^posted:\s+(.+)/;
	  $document{category} = $1 if /^category:\s+(.+)/;
	  $document{keywords} = $1 if /^keywords:\s+(.+)/;
	}
	
	local $/;
	$document{content} = <$in>;
	close $in;

	if ($document{posted}) {
		my @time = $document{posted} =~ /^(\d{4})-(\d\d)-(\d\d)(?: (\d\d):(\d\d))?/;
		$document{epoch} =
			timelocal(0,$time[4],$time[3],$time[2],$time[1]-1,$time[0]-1900);
	} else {
		$document{epoch} = (stat $file)[9];
	}
	
	$document{author}   = 'rjbs';
	$document{title}    ||= '(untitled)';
	$document{category} ||= '';
	$document{keywords} ||= '';
	
 	return Bryar::Document::RJBS->new( %document );
}

1;
