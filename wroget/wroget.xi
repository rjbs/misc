#!/usr/bin/perl

# $Id: wroget.xi 157 2004-08-18 05:22:55Z mdxi $

use DBI;
use CGI qw(param);
use strict;

my $rev = '$Rev: 157 $';
$rev =~ s/[\$\:]//g;

my $driver = "dbi:Pg:dbname=wroget";
my $dbh = DBI->connect($driver, '', '');
my $sth = 0;

dictheader();
if (param('sec')) {
    detail(param('sec'));
} elsif (param('word')) {
    lookup(param('word'),param('type'));
} else {
    print "wroget: simple search</title></head><body><h1>wroget: simple search</h1>\n";
}
form();

#-----------------------------------------------------

sub lookup {
    my $i = 0;
    my $word = shift;
    my $type = shift;
    my $sword = lc($word);

    if ($type == 3) {
	$sword = '%'.$sword;
    } elsif ($type == 2) {
	$sword = '%'.$sword.'%';
    } else {
	$sword .= '%';
    }

    $sword = $dbh->quote($sword);

    my $statement = "SELECT idx,idx.sec,name FROM idx JOIN sections ON idx.sec = sections.sec WHERE idx LIKE $sword ORDER BY idx,name";
    $sth = $dbh->prepare($statement);
    my $rows = $sth->execute || die "$statement\n";

#    if ($rows == 1) {
#	detail();
#    }

    print "wroget: ",$word,"</title>\n</head>\n<body>\n";
    print "<h1>wroget: search for '",$word,"'</h1>\n\n";
    if($rows eq "0E0") {
	print "<p>There were no matches for '$word'.</p>\n";	
	return;
    }
    print "<p>The index entries on the left matched your query. Choose the headword on the right which is closest to your desired meaning.</p>\n";
    print "<table class='summary'><tr><th>Index Entry</th><th>Section</th></tr>\n";
    
    while (my $q = $sth->fetchrow_arrayref) {
	my $class = "a";
	$class = "b" if (($i % 2) == 0);
	$i++;

	$q->[2] =~ s/\s+{.+}$//; 

	print "<tr><td class='$class'>"
	    ,ucfirst($q->[0])
	    ,"</td><td class='$class'><a href='wroget.xi?sec="
	    ,$q->[1]
	    ,"'>"
	    ,$q->[2]
	    ,"</a></td></tr>";
    }
    print "</table>\n<div>$rows matches.</div>";
}


sub detail {
    my $sec = shift;
    my $ssec = $dbh->quote($sec);

    my ($id,$sec,$name) = $dbh->selectrow_array("SELECT * FROM sections WHERE sec=$ssec");

    print "wroget: ",$name,"</title>\n</head>\n<body>\n";
    print "<h1>wroget: ",$name,"</h1>\n\n";

    print "<div class='def'>\n"; 
    # pointer to entry before pre-secondary
    my $tempid = $id - 2;
    my ($id2,$sec2,$name2) = $dbh->selectrow_array("SELECT * FROM sections WHERE id = $tempid") if ($tempid > 0);
    print "<h4>$sec2. $name2 (<a href='wroget.xi?sec=$sec2'>VV</a>)</h4>\n";
    # pre-secondary entry
    $tempid = $id - 1;
    if ($tempid > 0) {
	($id2,$sec2,$name2) = $dbh->selectrow_array("SELECT * FROM sections WHERE id = $tempid");
	print "<h3>$sec2. $name2 (<a href='wroget.xi?sec=$sec2'>V</a>)</h3>\n";
	print "<table class='wroget' style='font-size:small;'>\n";
	my $ssec2 = $dbh->quote($sec2);
	paint_sec($ssec2);
    }
    # primary (requested) section
    print "<div id='targetsec'><h2 style='text-align:left;border:0;background-color:transparent;'>$sec. $name</h2>\n";
    print "<table class='wroget'>\n";
    paint_sec($ssec);
    print "</div>\n";
    # post-secondary entry
    $tempid = $id + 1;
    if ($tempid < 1044) {
	($id2,$sec2,$name2) = $dbh->selectrow_array("SELECT * FROM sections WHERE id = $tempid");
	print "<h3>$sec2. $name2 (<a href='wroget.xi?sec=$sec2'>^</a>)</h3>\n";
	print "<table class='wroget' style='font-size:small;'>\n";
	my $ssec2 = $dbh->quote($sec2);
	paint_sec($ssec2);
    }
    # pointer to entry before pre-secondary
    $tempid = $id + 2;
    ($id2,$sec2,$name2) = $dbh->selectrow_array("SELECT * FROM sections WHERE id = $tempid") if ($tempid < 1044);
    print "<h4>$sec2. $name2 (<a href='wroget.xi?sec=$sec2'>^^</a>)</h4>\n";
    print "<div>LEGEND [ *:Slang | &dagger;:Obsolete (1911) | &Dagger;:Obsolete | &loz;:Archaic ]</div>\n";
    print "</div>\n";
}

sub paint_sec {
    my $sec = shift;
    my $statement = "SELECT * FROM subsections WHERE sec = $sec";
    $sth = $dbh->prepare($statement);
    my $rows = $sth->execute || die "$statement\n";

    if ($rows eq "0E0") {
	print "Whuh? Can't find that section!";
	return;
    }
	
    while (my $q = $sth->fetchrow_arrayref) {
	my $class = "b";
	$class = "a" if (($q->[1] % 2) == 0);

	$q->[2] =~ s/\|\!/&Dagger;/g;
	$q->[2] =~ s/\|/&dagger;/g;
	$q->[2] =~ s|\[obs3\]|&loz;|g;
	$q->[2] =~ s/&c.//g;
	$q->[2] =~ s|(\d+[a-z]?)|<a href='wroget.xi?sec=$1'>$1</a>|g;

	print "<tr><th style='text-align:left'>"
	    ,$q->[0],".",$q->[1]
	    ,"</th><td class='$class'>"
	    ,$q->[2]
	    ,"</td></tr>\n";
    }

    print "</table>\n";
}

#-----------------------------------------------------

sub dictheader {
    print <<HEADER;
HTTP/1.1 200 OK
Connection: close
Content-Type: text/html; charset=UTF-8

<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
    "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
<link href="/master.css" rel="stylesheet"/>
  <link href="/dict.css" rel="stylesheet"/>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
<title>
HEADER
}

sub form {
    print "<div><form action='wroget.xi' method='post'>";
    print "<input type='text' name='word' size='40'/>";
    print " <input type='radio' name='type' value='1' checked='1'/> Starts With";
    print " <input type='radio' name='type' value='2'/> Contains";
    print " <input type='radio' name='type' value='3'/> Ends With";
    print " <input type='submit' value='Lookup'/>";
    print "</form></div>";
    print "<div class='ver'>wroget $rev &mdash; Valid XHTML1.1/CSS2</div>";
    print "</body>";
    print "</html>";
}
