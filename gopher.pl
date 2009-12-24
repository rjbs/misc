#!/usr/bin/perl
# gopher - a gopher server (I'm sorry!)
use strict;
use warnings;
use IO::Socket;

my $port = 70;
my $crlf = "\015\012";

my $socket = IO::Socket::INET->new(
  Proto     => 'tcp',
  LocalPort => $port,
  Listen    => 128,
  Reuse     => 1
);

warn "waiting for incoming connections on port $port...\n";

while (1) {
  next unless my $connection = $socket->accept;
  if (fork) {
    $connection->close;
    next;
  } else {
    $connection->autoflush(1);
    my $request = $connection->getline;

    $request =~ s/$crlf//g;
    print STDERR "REQUEST: $request\n";

    if ($request eq '' or $request eq '/') {
      $connection->print("1Directory Listing\t/\tlocalhost\t70$crlf");
      $connection->print("0README.TXT\tREADME.TXT\tlocalhost\t70$crlf");
      $connection->print("0README.TxT\tREADME.TxT\tlocalhost\t70$crlf");
      $connection->print(".$crlf");
    }
    
    $connection->close;
  }
}

$socket->close;
