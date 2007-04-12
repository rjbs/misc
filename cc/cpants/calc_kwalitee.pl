#!/usr/bin/perl
use strict;
use warnings;
use DBI;

use lib('../lib/','lib/');

use Module::CPANTS::Generator;

use Module::CPANTS::DB;

my $cpants=Module::CPANTS::Generator->new;
my $dbh=Module::CPANTS::DB->db_Main;


Module::CPANTS::DB->link_dists_modules;
$cpants->calc_kwalitee;
Module::CPANTS::Generator::Authors->fill_authors($cpants);

# AUTHOR: num_dists, average
{
    my $sth=$dbh->prepare("select count(*) as num_dists,avg(kwalitee.kwalitee) as average,dist.author as id from dist,kwalitee where dist.kwalitee=kwalitee.id group by author");
    $sth->execute;
    while (my @r=$sth->fetchrow_array) {
        $dbh->do("update author set num_dists=?,average_kwalitee=? where id=?",undef,@r);
    }
    $sth->finish;
    $dbh->do("update author set num_dists=0 where num_dists is null");
}

# RANKS
foreach my $query ("select average_kwalitee,id from author where num_dists>=5 order by average_kwalitee desc",
"select average_kwalitee,id from author where num_dists<5 AND num_dists>0 order by average_kwalitee desc")
    {
    my $sth=$dbh->prepare($query);
    $sth->execute;
    my $pos=0;my $cnt=0;my $k=0;
    my @done;
    while (my ($avg,$id)=$sth->fetchrow_array) {
        $cnt++;
        if ($k!=$avg) {
            $k=$avg;
            $pos=$cnt;
        }
        push(@done,[$pos,$id]);
    }
    foreach (@done) {
        $dbh->do("update author set rank=? where id=?",undef,@$_);
    }
}

# PREVIOUS KWALITEE
{
    my $old=DBI->connect("dbi:SQLite:dbname=".$cpants->prev_db_file);
    my $sth=$old->prepare("select average_kwalitee,pauseid from author");
    my $update=$dbh->prepare("update author set prev_av_kw=? where pauseid=?");
    $sth->execute;
    while (my @r=$sth->fetchrow_array) {
        $update->execute(@r);
    }
}


__END__
# recursive prereqs NOT WORKING

