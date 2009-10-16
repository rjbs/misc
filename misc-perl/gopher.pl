#!/usr/bin/perl

=head1 NAME

gopher - a gopher server (I'm sorry!)

=cut

use strict;
use IO::Socket;

my $crlf = "\015\012";

my ($bytes_out,$bytes_in) = (0,0);

my $socket = IO::Socket::INET->new(
	Proto => 'tcp', LocalPort => 70, Listen => 128, Reuse => 1
);

warn "waiting for incoming connections on port 70...\n";

my $directory = { content => [
	{ name => 'hello', desc => 'hello', content => 'Hello, 1993-era world!' },
	{
    name => 'wtf',   desc => "I don't get it.", content => [
      { name => 'wtf', desc => 'What is this?', content => 'Gopher!' },
      { name => 'why', desc => 'Why would you do this?', content => 'Cuz!' },
    ]
	}
]};

while (1) {
  next unless my $connection = $socket->accept;
  if (fork) {
  	$connection->close;
  	next;
  } else {
		$connection->autoflush(1);
		my $request = $connection->getline;

		$request =~ s/$crlf//g;

		my $item = get_item($request);
		unless ($item) {
			print $connection "ERROR: request leads nowhere!$crlf";
			print $connection ".$crlf";
		} else {
			print $connection format_item($item, $request);
		}
		
		$connection->close;
	}
}

sub get_item {
	my ($index, $dir) = @_;
	warn ">> $dir\n";
	$dir ||= $directory;
	my ($head, $tail) = split '/', $index, 2;
	return $dir unless $head;
	my $subdir;
	if (ref($dir->{content})||'' eq 'ARRAY') {
		$subdir = grep { $_->{name} eq $head } @{$dir->{content}};
	} elsif (ref($dir->{content})||'' eq 'HASH') {
		$subdir = $dir->{content}{$head};
	}
	if ($subdir) { return get_item($tail, $subdir) }
	return;
}

sub format_item {
	my ($item, $request) = @_;
	my $leader = "$request/" if $request;

	if (ref $item->{content} eq 'ARRAY') {
		my $output;
		foreach (@{$item->{content}}) {
			$output .= ((ref $_->{content}) eq 'ARRAY' ? 1 : 0);
			$output .= "$_->{desc}\t$leader$_->{name}\tknave\t70$crlf";
		}
		return $output;
	} else {
		return $item->{content};
	}
}

$socket->close;
