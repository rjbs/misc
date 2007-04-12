#!/usr/bin/perl
use strict;
use warnings;
 
use lib('../lib/','lib/');
use GD::Graph;
use GD::Graph::bars;
use DateTime;
use Module::CPANTS::Generator;
use Module::CPANTS::DB;

my $outpath="/home/rjbs/cpants/";

my $cpants=Module::CPANTS::Generator->new;
my $now=DateTime->now->ymd;
my @bar_defaults=(
    bar_spacing     => 8,
    shadow_depth    => 4,
    shadowclr       => 'dred',
    transparent     => 0,
    show_values=>1,
);

foreach (
    {
        title=>'Kwalitee Distribution',
        sql=>'select kwalitee,count(kwalitee) as cnt from kwalitee group by kwalitee order by kwalitee',
        lablex=>'Kwalitee',
        labley=>'Distributions',
    },
    {
        title=>'Active PAUSE IDs',
        sql=>[
            'select "not active",count(*) from author where num_dists<1',
            'select "active",count(*) from author where num_dists>0',
            ],
        lablex=>'Status',
        labley=>'Authors',
    },
    {
        title=>'Dists per Author',
        sql=>'select num_dists,count(num_dists) as cnt from author where num_dists > 0 group by num_dists order by num_dists',
        lablex=>'Dists',
        labley=>'Authors',
        width=>800,
    },
    {
        title=>'Dists released per year',
        sql=>'select substr(released_date,-4,4) as year,count(substr(released_date,-4,4)) from dist group by year order by year',
        lablex=>'Year',
        labley=>'Dists',
    },
) {
    make_graph($_);
}

sub make_graph {
    my $DBH=Module::CPANTS::DB->db_Main;
    my $c=shift;

    my $title=$c->{title};
    my $filename=lc($title);
    $filename=~s/ /_/g;
    $filename=~s/\W//g;
    $filename.=".png";

    my (@x,@y);
    my $maxy=0;

    if (ref($c->{sql}) eq 'ARRAY') {
        foreach my $sql (@{$c->{sql}}) {
            my $sth=$DBH->prepare($sql);
            $sth->execute;
            while (my @r=$sth->fetchrow_array) {
                push(@x,shift(@r));
                my $y=shift(@r);
                push(@y,$y);
                $maxy=$y if $y>$maxy;
            }
            $maxy=int($maxy*1.05);
        }
    } else {
        my $sth=$DBH->prepare($c->{sql});
        $sth->execute;

        while (my @r=$sth->fetchrow_array) {
            push(@x,shift(@r));
            my $y=shift(@r);
            push(@y,$y);
            $maxy=$y if $y>$maxy;
        }
        $maxy=int($maxy*1.05);
    }

    my $graph=GD::Graph::bars->new($c->{width} || 400,400);

    $graph->set(
		x_label=>$c->{lablex},
		'y_label'=>$c->{labley},
		title=>$title." ($now)",
		'y_max_value'=>$maxy,
		@bar_defaults,
    );

    my $gd=$graph->plot([\@x,\@y]);
    return unless $gd;
    open(IMG, ">".$outpath.$filename) or die $!;
    binmode IMG;
    print IMG $gd->png;
    return;
}

