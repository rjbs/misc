#!/usr/bin/perl 

use strict;
use DBI;
use Term::ReadKey;
use Term::ReadLine;

use vars qw[$dbh $term $input @cmd $version];

$version = 'BookShelf D1 [2002-07-17]';

my $dbh=DBI->connect(
	'dbi:Pg:dbname=library;host=cheshire.manxome.org',
	'samael',
	'z3phYr'
) or die $DBI::ERRSTR;

print "<<>> $version\n";

$term=Term::ReadLine->new('booksh');

my $done = 0;

sub list_creators {
	my $arg3 = lc(shift);
	
	my $sth=$dbh->prepare("
		SELECT c.creatorid, c.lname, c.fname, c.mname, c.suffix
		FROM creators c
		" . ($arg3 ?  "WHERE lower(lname) LIKE '$arg3%'" : undef) . "
		ORDER BY c.lname, c.fname, c.mname
	");

	$sth->execute();

	printf "  %4s  | %s\n", 'cid', 'name';
	print  ('------+', ('-' x 72), "\n");

	my $i=0;
	while (my $creator=$sth->fetchrow_hashref()) {
		$i++;
		## all we need to display in the summary is vid, lc number, and title
		printf " (%04s) | %s\n",
			$creator->{creatorid},
			"$creator->{lname}, $creator->{fname} $creator->{mname} $creator->{suffix}";
		## cheezy half-assed pager; replace this with 'less' or something, later
		if ($i==23) { 
			ReadMode('cbreak');
			print "...more...";
			if (ReadKey(0) eq 'q') { print "\n"; ReadMode('normal'); last; }
			ReadMode('normal'); 
			print "\n";
			$i=0; 
		}
	}
}

## display a list of all stored books
sub list_books {
	my $arg3 = lc(shift);
	
	my $sth=$dbh->prepare("
		SELECT lcnumber, title, volumeid
		FROM books
		" . ($arg3 ?  "WHERE lower(title) LIKE '$arg3%'" : undef) . "
		ORDER BY lcnumber, title
	");
	$sth->execute;

	my $i=0;
	while (my $row=$sth->fetchrow_hashref) {
		$i++;
		## all we need to display in the summary is vid, lc number, and title
		printf "(%04u) %15s | %-50s\n",
			$row->{volumeid},
			$row->{lcnumber},
			substr($row->{title},0,55);
		## cheezy half-assed pager; replace this with 'less' or something, later
		if ($i==23) { 
			ReadMode('cbreak');
			print "...more...";
			if (ReadKey(0) eq 'q') { print "\n"; ReadMode('normal'); last; }
			ReadMode('normal'); 
			print "\n";
			$i=0; 
		}
	}
}

sub view_book {
	my $v = shift;

	my $volume;

	if (ref $v eq 'HASH') { 
		$volume = $v; 
	} elsif (!($volume = get_book($v))) {
		print "<X> invalid volume id\n"; return; 
	}

	printf "\n (%04u) | %s\n", $volume->{volumeid}, $volume->{title};
	print '========+', ('=' x 70), "\n";
	printf " %-10s: %s\n", 'LC Number', ($volume->{lcnumber} || '[--]');
	printf " %-10s: %s\n", 'Publisher', ($volume->{pub} || '[--]');
	printf " %-10s: %s\n", 'Published', ($volume->{pubdate} || '[--]');
	printf " %-10s: %s\n", 'Pages', ($volume->{pages} || '[--]');
	printf " %-10s: %s\n", 'ISBN', ($volume->{isbn} || '[--]');
	printf " %-10s: %s\n", 'Location', ($volume->{loc} || '[--]');

	print "\n  Creators\n";
	print '  ', ('-' x 75), "\n";

	foreach my $type (keys %{$volume->{creators}}) {
		foreach my $creator (values %{$volume->{creators}{$type}}) {
			printf "   (%04u) [%-15s] %s\n",
				$creator->{creatorid},
				"$creator->{type}",
				"$creator->{lname}, $creator->{fname} $creator->{mname} $creator->{suffix}";
		}
	}
	foreach my $type (keys %{$volume->{_creators}}) {
		foreach my $creator (values %{$volume->{_creators}{$type}}) {
			printf "  %s(%04u) [%-15s] %s\n",
				($creator->{_action} || ' '),
				$creator->{creatorid},
				"$creator->{type}",
				"$creator->{lname}, $creator->{fname} $creator->{mname} $creator->{suffix}";
		}
	}

	print (('=' x 79), "\n\n");

}

sub edit_book {
	my $vid = shift;

	my $book;

	if ($vid) {
		$book = get_book($vid);
	} else {
		$book = new_book();
	}

	unless ($book) { print "<X> invalid volumd\n"; return; }

	my $done = 0;

	while ($done == 0) {
		my $prompt = 'booksh::edit(' . ($book->{volumeid} || 'new') . ')> ';
		$input=$term->readline($prompt);
	
		if ($input eq 'done') { $done = 1; }
		elsif ($input =~ '^list creators( ([a-zA-Z]+))?') { list_creators($2); }
		elsif ($input =~ /^set ([a-z]+)\s*( to |=)\s*(.+)$/) {
			my $attr = $1; my $value = $3;
			if (grep /^$attr$/, qw[title lcnumber pubdate pages haveread isbn locid pubid]) {
				$book->{$attr} = (($value =~ /^null$/i) ? undef : $value);
			} else {
				print "<X> invalid attribute\n";
			}
		} elsif ($input =~ /^add creator ([aet]):(\d+)$/) {
			my $type = $1; my $cid = $2;

			my %types = (a => 0, e => 1, t => 2);	

			unless (defined $types{$type}) { next; }

			my @types = qw[author editor translator];

			my $creator;
			
			unless ($creator=get_creator($cid)) {
				print "<X> invalid creator\n"; next;
			}

			$creator->{typeid} = $types{$type};
			$creator->{type} = $types[$types{$type}];

			if ($book->{creators}{$creator->{type}}{$cid}) {
				if ($book->{_creators}{$creator->{type}}{$cid}) {
					if ($book->{_creators}{$creator->{type}}{$cid}{_action} eq '-') {
						delete $book->{_creators}{$creator->{type}}{$cid};
						print "<!> no longer marked for deletion\n";
					}
				} else {
					print "<X> already listed\n";
				}
			} elsif ($book->{_creators}{$creator->{type}}{$cid}) {
				if ($book->{_creators}{$creator->{type}}{$cid}{_action} eq '-') {
					$book->{_creators}{$creator->{type}}{$cid}{_action} = '+';
					print "<!> toggled\n";
				} else {
					print "<X> already pending\n";
				}
			} else {
				$book->{_creators}{$creator->{type}}{$cid} = { %$creator, _action => '+' };
				print "<!> added\n";
			}
		} elsif ($input =~ /^rem creator ([aet]):(\d+)$/) {

			my $type = $1; my $cid = $2;

			my %types = (a => 0, e => 1, t => 2);	

			unless (defined $types{$type}) { next; }

			my @types = qw[author editor translator];

			my $creator=get_creator($cid);

			$DB::single=1;

			$creator->{typeid} = $types{$type};
			$creator->{type} = $types[$types{$type}];

			if ($book->{creators}{$creator->{type}}{$cid}) {
				if ($book->{_creators}{$creator->{type}}{$cid}) {
					if ($book->{_creators}{$creator->{type}}{$cid}{_action} eq '-') {
						print "<X> already removing\n";
						next;
					} 
				} else {
					$creator->{_action} = '-';
					$book->{_creators}{$creator->{type}}{$cid} = $creator;
					print "<!> marked for deletion\n";
				}
			} elsif ($book->{_creators}{$creator->{type}}{$cid}) {
				if ($book->{_creators}{$creator->{type}}{$cid}{_action} eq '+') {
					print "<!> no longer marked for addition\n";
					delete $book->{_creators}{$creator->{type}}{$cid};
				}
			} else {
				print "<X> not a listed creator\n";
				next;
			}
		}
		elsif ($input eq 'view') { view_book($book); }
		elsif ($input eq 'write') { $book=write_book($book); print "<!> book written\n"; }
		else { print "<X> unknown command\n"; }
	
	}

}

sub get_creator {
	my $cid = shift;

	if ($cid !~ /^\d+$/) { return undef; }

	my %creator;
	
	my $result = $dbh->selectall_arrayref("
		SELECT creatorid, lname, fname, mname, suffix
		FROM creators c
		WHERE creatorid=$cid
	");
	
	if ($result->[0]) {
		@creator{qw[creatorid lname fname mname suffix]} = @{$result->[0]};
	} else {
		return undef; 
	}

	return \%creator;

}

sub get_book {
	my $vid = shift;

	if ($vid !~ /^\d+$/) { return undef; }

	my %book;

	@book{qw[volumeid title lcnumber pubdate pages haveread isbn loc locid pub pubid]} = @{($dbh->selectall_arrayref("
		SELECT volumeid, title, lcnumber, pubdate, pages, haveread, isbn, l.brief AS loc, 
			b.location AS locid, p.name AS pub, b.publisher AS pubid
		FROM books b
		LEFT JOIN locations l ON b.location=l.locationid
		LEFT JOIN publishers p ON b.publisher=p.publisherid
		WHERE volumeid=$vid
	"))->[0]};

	unless ($book{volumeid}) { return undef; }

	my $creators = $dbh->selectall_arrayref("
		SELECT c.creatorid, c.lname, c.fname, c.mname, c.suffix, ct.name AS type, ct.typeid
		FROM bookcreators bc 
		JOIN creators c ON bc.creatorid=c.creatorid 
		JOIN creatortypes ct ON bc.typeid=ct.typeid 
		WHERE bc.volumeid=$vid
		ORDER BY ct.name, c.lname, c.fname
	");

	if ($creators->[0]) {
		$book{creators} = {};

		foreach my $creator (@$creators) {
			my %creator;
			@creator{qw[creatorid lname fname mname suffix type typeid]} = @$creator;

			$book{creators}->{$creator{type}} ||= {};

			$book{creators}->{$creator{type}}{$creator{creatorid}} = \%creator;
		}
	}

	return \%book;

}

sub new_book {
	my %book;

	$book{locid} = 1;
	$book{loc} = 'stacks';

	return \%book;
}

sub new_creator {
	my %creator;
	
	return \%creator;
}

sub write_creator {
	my $creator = shift;
	
	if ($creator->{creatorid}) {
	## if the volumeid is defined, we UPDATE
	#!!# there needs to be some kind of validating code	
		my $query;
		
		$query .= "UPDATE creator SET ";
	
		$query .= "lname=" . ($creator->{lname} ? "'$creator->{lname}'" : 'NULL') . ", ";
		$query .= "fname=" . ($creator->{fname} ? "'$creator->{fname}'" : 'NULL') . ", ";
		$query .= "mname=" . ($creator->{mname} ? "'$creator->{mname}'" : 'NULL') . ", ";
		$query .= "suffix=" . ($creator->{suffix} ? "'$creator->{suffix}'" : 'NULL') . " ";

		$query .= " WHERE creatorid=$creator->{creatorid}";

		$dbh->do($query);

	} else {
	## if the volumeid is undef, we INSERT -- or, we will, once I code that

		my $query;
		
		$query .= "
			INSERT INTO creators
			(lname, fname, mname, suffix) VALUES ";
		
		$query .= "(";

		$query .= ($creator->{lname} ? "'$creator->{lname}'" : 'NULL') . ", ";
		$query .= ($creator->{fname} ? "'$creator->{fname}'" : 'NULL') . ", ";
		$query .= ($creator->{mname} ? "'$creator->{mname}'" : 'NULL') . ", ";
		$query .= ($creator->{suffix} ? "'$creator->{suffix}'" : 'NULL') . " ";
		
		$query .= ")";

		$query .= "; SELECT currval('creatorid_seq')";

		my $insert = $dbh->selectall_arrayref($query);
		
		if ($insert->[0][0]) {
			$creator->{creatorid} = $insert->[0][0];
			print "<!> inserted as creator $insert->[0][0]\n";
		} else {
			print "<X> insert failed";
			return;
		}
	}

	return get_creator($creator->{creatorid});
	
}

sub write_book {
	my $book = shift;
	
	if ($book->{volumeid}) {
	## if the volumeid is defined, we UPDATE
	#!!# there needs to be some kind of validating code	
		my $query;
		
		$query .= "UPDATE books SET "
			. "title = " . $dbh->quote($book->{title}) . ", "
			. "lcnumber = " . $dbh->quote($book->{lcnumber}) . ", "
			. "pubdate = " . $dbh->quote($book->{pubdate}) . ", "
			. "pages = " . $dbh->quote($book->{pages}) . ", "
			. "haveread = " . $dbh->quote($book->{haveread}) . ", "
			. "isbn = " . $dbh->quote($book->{isbn}) . ", "
			. "location = " . $dbh->quote($book->{locid}) . ", "
			. "publisher = " . $dbh->quote($book->{pubid})
			. " WHERE volumeid=" . $dbh->quote($book->{volumeid});

		$dbh->do($query);


	} else {
	## if the volumeid is undef, we INSERT -- or, we will, once I code that

		my $query;
		
		$query .= "
			INSERT INTO books
			(title, lcnumber, pubdate, pages, haveread, isbn, location, publisher) VALUES ";
		
		$query .= "("
			. $dbh->quote($book->{title}) . ", "
			. $dbh->quote($book->{lcnumber}) . ", "
			. $dbh->quote($book->{pubdate}) . ", "
			. $dbh->quote($book->{pages}) . ", "
			. $dbh->quote($book->{haveread}) . ", "
			. $dbh->quote($book->{isbn}) . ", "
			. $dbh->quote($book->{locid}) . ", "
			. $dbh->quote($book->{pubid});
		$query .= ")";

		$query .= "; SELECT currval('volumeid_seq')";

		print $query, "\n";
		my $insert = $dbh->selectall_arrayref($query);
		
		if ($insert->[0][0]) {
			$book->{volumeid} = $insert->[0][0];
			print "<!> inserted as volume $insert->[0][0]\n";
		} else {
			print "<X> insert failed";
			return;
		}
	}

	foreach my $type (keys %{$book->{_creators}}) {
		foreach my $creator (values %{$book->{_creators}{$type}}) {
			if ($creator->{_action} eq '+') {
				print "<!> adding $creator->{type}: $creator->{creatorid}!\n";
				$dbh->do("
					INSERT INTO bookcreators (volumeid, creatorid, typeid)
					VALUES ($book->{volumeid}, $creator->{creatorid}, $creator->{typeid})
				") or print "<X> error! $DBI::ERRSTR\n";
			} elsif ($creator->{_action} eq '-') {
				print "rem $creator->{type}: $creator->{creatorid}!\n";
				$dbh->do("
					DELETE FROM bookcreators 
					WHERE volumeid=$book->{volumeid}
						AND creatorid=$creator->{creatorid}
						AND typeid=$creator->{typeid}
				") or print "<X> error! $DBI::ERRSTR\n";
			} else { 
				print "<X> unknown action\n";
			}
		}
	}

	return get_book($book->{volumeid});
	
}

## this hash defines acceptable verbs and switches activity to the correct one
my %handler = (
	## quit the program
	quit	=> sub { $done = 1; },

	## edit things -- requires a noun and an id
	edit	=> sub {
		my $noun = shift;
		my $id = shift;
		if ($noun eq 'book') {	
			edit_book($id);
		} else {
			print "<!> you can't edit that\n";
		}
	},

	## list things -- requries a noun and possibly extra args
	list	=> sub {
		my $noun = shift;
		my $arg3 = shift;
		if ($noun eq 'books') {
			list_books($arg3);
		} elsif ($noun eq 'creators') {
			list_creators($arg3);
		} else {
			print "<!> you can't list that\n";
		}
	},
	
	new		=> sub {
		my $noun = shift;
		my $arg3 = shift;
		if ($noun eq 'book') {
			edit_book();
		} elsif ($noun eq 'creator') {
			my %cname;
			@cname{qw[lname fname mname suffix]} = split(/, ?/, $arg3);
			write_creator(\%cname);
		} else {
			print "<!> you can't create that\n";
		}
	},

	## view things in detail -- get a few lines of summary
	view	=> sub {
		my $noun = shift;
		if ($noun eq 'book') {
			view_book(@_);
		} else {
			print "<!> you can't view that\n";
		}
	},

	## see current version info
	version	=> sub { print "<<>> $version\n     by Ricardo Signes\n"; }
);

while ($done == 0) {
	$input=$term->readline('booksh> ');

	@cmd = split(/\s+/,$input,3);

	my ($verb, $noun, $arg3) = @cmd;

	if (ref $handler{$verb} eq 'CODE') {
		$handler{$verb}->($noun, $arg3);
	} elsif ($verb) {
		print "<!> unknown command\n";
	}

}

close OUTFILE;
$dbh->disconnect;
