package CPAN::Mini::Archive;
use Carp;

use Parse::CPAN::Authors;

use Compress::Zlib;
use LWP::Simple qw(get mirror);
use Sort::Versions qw(versioncmp);
use URI;

use warnings;
use strict;

=head1 NAME

CPAN::Mini::Archive - an archive of perl distributions

=head1 VERSION

version 0.01

 $Id: Archive.pm 5 2005-03-14 03:17:03Z rjbs $

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  use CPAN::Mini::Archive;

=head1 DESCRIPTION

Quick summary of what the module does.

=head1 METHODS

=head2 new

=cut

sub new {
	my ($class, %arg) = @_;
	croak "no archive root given" unless $arg{root};
	my $self = bless { root => $arg{root} } => $class;

	$self->__indices;

	return $self;
}

sub __get_index {
	my ($self, $filename) = @_;
	my $uri  = URI->new_abs($filename, $self->{root});
	my $file = get($uri) or die "couldn't fetch $filename";
	Compress::Zlib::memGunzip(\$file);
}

sub __indices {
	my ($self) = @_;

	# 01mailrc
	my $mailrc = $self->__get_index("authors/01mailrc.txt.gz");
	$self->{_pc_authors} = CPAN::Mini::Archive::Authors->new($mailrc)
		or die "couldn't parse 01mailrc.txt.gz";

	# 02packages
	my $packages = $self->__get_index("modules/02packages.details.txt.gz");
	$self->{_pc_packages} = CPAN::Mini::Archive::Packages->new($packages)
		or die "couldn't parse 02packages.details.txt.gz";
}

sub authors { (shift)->{_pc_authors}->authors; }

sub packages { (shift)->{_pc_packages}->packages; }

sub distributions { (shift)->{_pc_packages}->distributions; }

sub latest_distributions { (shift)->{_pc_packages}->latest_distributions; }

sub delete_distribution { (shift)->{_pc_packages}->delete_distribution(@_) }

sub delete_package { (shift)->{_pc_packages}->delete_package(@_) }

package CPAN::Mini::Archive::Packages;
use base qw(Parse::CPAN::Packages);

sub delete_distribution {
	my ($self, $dist) = @_;
	$dist = $self->distribution($dist) unless ref $dist;
	$self->delete_package($_) for $dist->contains;
	delete $self->dists->{$dist->prefix};
}

sub delete_package {
	my ($self, $package) = @_;
	$package = $self->package($package) unless ref $package;
	delete $self->data->{$_->package};
}

package CPAN::Mini::Archive::Authors;
use base qw(Parse::CPAN::Authors);

package CPAN::Mini::Mirror;

# make $to look like $from
sub mirror {
	my ($class, $from, $to) = @_;

	# can't work; looks up dist by prefix instead of name
	# consider distribution-by-name providing @=all $=latest
	for my $dist ($from->latest_distributions) {
		if (my $existing = $to->{_pc_packages}->distribution($dist)) {
			if (versioncmp($existing->version , $dist->version) == -1) {
				$class->_delete_local($existing, $to);
				$class->_mirror_file($dist, $from, $to);
			} else {
				# index_file($existing);
			}
		} else {
			$class->_mirror_file($dist, $from, $to);
		}
	}
}

sub _delete_local {
	my ($class, $dist, $from_archive) = @_;
	my $file = $from_archive->{prefix} . "authors/id/" . $dist->prefix;
	$from_archive->delete_distribution($dist);
	print "D $file\n";
	unlink $file;
}

sub _mirror_file {
	my ($class, $dist, $from_archive, $to_archive) = @_;
	my $uri  = $from_archive->{root} . "authors/id/" . $dist->prefix;
	my $file =   $to_archive->{root} . "authors/id/" . $dist->prefix;
	print "M $uri\n";
	my $status = LWP::Simple::mirror($uri, $file);
	# $class->_index_file($dist);
}

=head1 AUTHOR

Ricardo Signes, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cpan-mini-archive@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT

Copyright 2005 Ricardo Signes, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
