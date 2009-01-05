#!/usr/bin/perl

# import PG Roget's 1911 data and index into PSQL db

use DBI;

$driver = "dbi:SQLite:dbname=roget.db";
$dbh    = DBI->connect( $driver, '', '', { AutoCommit => 0 } );

$arg = shift;

if ( $arg eq "-t" ) {
    open( ROGET, "src/roget15a.txt" );
    while (<ROGET>) {
        next if m/^\s*\n\s*$/;    # blank line
        next if m/^#/;            # comments
        next if m/^\s*<--/;       # other comments
        if (/^%/) {
            $_ = <ROGET>;         # section header chunks
            until (/^\%/) {
                $_ = <ROGET>;
            }
            next;
        }

        chomp;

        if (/^\s{5}#\d+/) {

            # new concept
            dump_entry() if $rflag;
            $i = 1;

            m/#(\d+[a-z]?)/;
            $num = $1;
            m/#\d+[a-z]?.?\s*([^\-]+)/;
            $con = $1;
            m/\-\-\s?(.*)$/;
            $rel = $1;

            $con =~ s/^\s+//;
            $con =~ s/\s+$//;
            $con =~ s/\.//g;
            if ( $con =~ m/^\[/ ) {
                $con =~ s/(\[.*\])(.*)/$2 $1/;
                $con =~ s/^\s+//;
                $con =~ s/\s+$//;
            }
            $num       = $dbh->quote($num);
            $con       = $dbh->quote($con);
            $statement = "INSERT INTO sections (sec, name) VALUES ($num,$con)";
            $sth       = $dbh->prepare($statement);
            $sth->execute or die "FAWK: $statement\n";
        }
        elsif (/^\s+/) {

            # new sub-concept
            dump_entry() if $rflag;
            dump_entry() if $short;
            $i++;
            $short = 1;
            s/^\s+//;
            s/\s+$//;
            $rel = $_;
        }
        else {

            #continued concept or subconcept
            $short = 0;
            $rflag = 1;
            s/\s+$//;
            $rel .= " " . $_;
        }
    }
}
elsif ( $arg eq "-i" ) {
    open( IDX, "src/index.txt" );
    while (<IDX>) {
        next if m/^\s*\n\s*$/;       # blank line
        next if m/^\s+[A-Z]\s*$/;    # Alpha header lines
        next if m/^#/;               # comments

        if (/^\S/) {

            # headword
            chomp;
            s/\s+$//;
            $head = $_;
        }
        else {

            # idx continue
            s/^\s+//;

            #m/^(\w+)\s+\d/;
            #$sec = $1;
            m/([\d\.]+)/;
            $num = $1;
            dump_idx();
        }
    }
}
else {
    print "Need a file arg\n";
}

$dbh->commit;

sub dump_idx {
    if ( $num =~ /\./ ) {
        $ext = 'a' if ( $num =~ /1$/ );
        $ext = 'b' if ( $num =~ /2$/ );
        $num =~ m/^(\d+)/;
        $num = $1 . $ext;
    }
    $head      = lc($head);
    $dhead     = $dbh->quote($head);
    $num       = $dbh->quote($num);
    $statement = "INSERT INTO idx VALUES ($dhead,$num)";
    $sth       = $dbh->prepare($statement);
    $sth->execute or die "FAWK: $statement\n";
    if ( $head =~ /(\w\.){2,}/ ) {
        $head =~ s/\.//g;
        $dhead     = $dbh->quote($head);
        $statement = "INSERT INTO idx VALUES ($dhead,$num)";
        $sth       = $dbh->prepare($statement);
        $sth->execute or die "FAWK: $statement\n";
    }
}

sub dump_entry {
    $rel       = $dbh->quote($rel);
    $statement = "INSERT INTO subsections VALUES ($num,$i,$rel)";
    $sth       = $dbh->prepare($statement);
    print "\033[s";
    print "Inserting $num.$i";
    print "\033[r";
    $sth->execute or die "FAWK: $statement\n";
    undef $rflag;
    undef $rel;
}
