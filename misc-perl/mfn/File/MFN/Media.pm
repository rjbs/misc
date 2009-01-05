package File::MFN::Media;

use base File::MFN;

use strict;


sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	$self->{extensions} =
		[qw(mp2 mp3 ogg mpg mpeg mov avi wmv mp4 qt gif jpg jpeg png)];
	
	bless $self, $class;
}

sub mogrify {
	my $self = shift;
	   $_    = shift;
	 
	s/^\.\///;                 # drop leading ./
	
	s/^[\{\[\(\-_]+//;         # drop leading {[(-_
	s/([a-z])([A-Z])/$1\_$2/g; # Insert '_' between caseSeparated words
	s/^(\d+)/$1-/;             # Add a hyphen after initial numbers
	s/[\{\[\(\)\]\}]/-/g;      # change remaining {[()]} to '-'
	s/\s+/_/g;                 # change whitespace to '_'
	s/\&/_and_/g;              # change '&' to "_and_"
	s/[^\w\-\.]//g;            # drop if not word, '-', '.'
	s/_+-+/-/g;                # collapse _- sequences
	s/-+_+/-/g;                # collapse -_ sequences
	s/(\-|\_|\.)+/$1/g;        # collapse -_.
	s/(\-|\_|\.)$//;           # remove trailing -_. (rare)
	s/[_\-]+(\.[^\.]+)$/$1/;   # drop trailing -_ before extension

	if (/\.\w+?$/) {           # collapse
		my $ext = $&;             # repeat
		s/$ext$ext$/$ext/;     # extensions
	}

	$_ = lc;           # slam lowercase

	return $_;
}

'23:44 <@rjbs> _..And Justice For All --mfn--> .and_justice_for_all';
