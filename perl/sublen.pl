use File::Find;
use File::Spec;
use strict;

sub file_subs {
	open(my $program, "<", $_[0]) or die "can't open $_[0]: $!";
	my $sub  = $_[1];
	my $psub = {};

	while (<$program>) {
		if (/^sub (\w+)\W* {$/) {
			my $subname = $1;
			$psub->{$subname}++ while (<$program> !~ /^}$/);
		}
	}

	push @$sub, map { [ $_[0], $_, $psub->{$_} ] } keys %$psub;

	return $sub;
}

sub print_subs {
	my $subs = shift;
	my @sorted_subs = sort { $b->[2] <=> $a->[2] } @$subs;
	eval { require Text::Table };
	if ($@) { 
		printf "%-40s %-30s %5u\n", @$_ for @sorted_subs;
	} else {
		my $table = Text::Table->new(qw(filename subname lines));
			 $table->load(@sorted_subs);
		print $table;
	}
}

my $subs = [];
sub do_file {
	my $filename = File::Spec->canonpath($File::Find::name);
	return if $filename =~ /\bblib\b/
	       or $filename !~ /\.(?:pm|pl)\Z/;

	file_subs($filename, $subs);
}

find({ wanted => \&do_file, no_chdir => 1}, $ARGV[0] || ".");

print_subs($subs);
