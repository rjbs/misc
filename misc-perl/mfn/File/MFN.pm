package File::MFN;

use strict;

sub new {
	my $class = shift;
	my %opts = @_;

	my $self = {};
	$self->{seen}      = [];
	$self->{renamed}   = [];
	$self->{noclobber} = [];
	$self->{opts}      = \%opts;
	$self->{extensions}= [qw( txt doc )];

	bless($self, $class);
}

sub mogrify { 
	return $_;
}

sub wanted {
	my $self = shift;
	my %opts = @_;

	return sub {
		my $old = $File::Find::name;
		
		if ($opts{nodirs}) {
		return unless ( -f );
		} else {
		if ($opts{eonly}) {
			my $match_ext = 0;
			foreach my $ext (@{$self->{extensions}}) {
			$match_ext = 1 if ($old =~ /\.$ext$/i);
			}
			return unless $match_ext;
		}
		}

		# never touch .
		return if ($old eq ".");

		# don't touch anything starting with a dot unless told to
		unless ($opts{dotfiles}) {
			return if ($File::Find::dir =~ /\/\./ or /^\./);
		}

		push @{$self->{seen}}, $old;

		my $new = $self->mogrify($old);

		if ($old ne $new) {
		if (-e) {
			unless ($self->{opts}{clobber}) {
			push @{$self->{noclobber}}, $File::Find::name . ' ('.$new.')';
			return(1);
			}
		}
		if ((not $self->{opts}{interactive}) or ($self->{opts}{interactive}($new))) {
			push @{$self->{renamed}}, " " . $File::Find::name . "\n        " .  $File::Find::dir . "/" . $new;
			rename($old, $new) unless ($self->{opts}{debug});
		}
		print "$old -> $new\n" if $opts{verbose};
		} else {
		# old, new names are same
		# NOP
		}
	}
}

"23:47 <mdxi> what the hell is responsible for naming that in the first place?";
