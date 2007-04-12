#!/usr/bin/perl -w
use strict;
use lib('../lib/','lib/');
use Algorithm::Dependency;
use Module::CPANTS::DB;

my $src=MySrc->new;
my $dep=Algorithm::Dependency->new(source=>$src);

my $prereq=$dep->depends('Gtk2-Ex-VolumeButton');
print join(',',@$prereq);


package MySrc;

use strict;
use base 'Algorithm::Dependency::Source';


sub new {
	my $class = shift;
	# Get the basic source object
	my $self = $class->SUPER::new or return undef;
	
    # Add our arguments
	$self->{DBH} = Module::CPANTS::DB->db_Main;

	$self;
}

use Data::Dumper;

sub _load_item_list {
	my $self = shift;

	# Load the contents of the file
    my $DBH=$self->{DBH};
    my $sth=$DBH->prepare("select dist.dist_without_version,requires from prereq,dist where dist.id=prereq.dist order by dist.dist_without_version");
    $sth->execute;

    my $thisdist='';
    my %prereq;
    while(my ($dist,$req)=$sth->fetchrow_array) {
        if ($thisdist ne $dist) {
            $thisdist=$dist;
            $prereq{$thisdist}=[];
        }
        push(@{$prereq{$thisdist}},$req);
    }
	# Parse and build the item list
	my @Items = ();
	foreach ( my($dist,$prereq)=each %prereq) {
		# Create the new item
		my $Item = Algorithm::Dependency::Item->new( $dist,@$prereq ) or return undef;
		push @Items, $Item;
        print Dumper $Item;
	    last;
    }

	\@Items;
}

1;








