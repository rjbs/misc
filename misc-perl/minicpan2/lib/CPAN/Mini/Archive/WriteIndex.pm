package CPAN::Mini::Archive::WriteIndex;

use Compress::Zlib qw(gzopen);
use File::Spec::Functions;

use warnings;
use strict;

=head1 NAME

CPAN::Mini::Archive::WriteIndex - write the indices for an archive

=head1 VERSION

version 0.01

 $Id: Archive.pm 4 2005-03-13 20:27:18Z rjbs $

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  use CPAN::Mini::Archive;
  use CPAN::Mini::Archive::WriteIndex;

  my $archive = CPAN::Mini::Archive->new(root => 'file:///mirrors/cpan/');
  CPAN::Mini::Archive::WriteIndex->write($archive, '/mirrors/cpan/');

=head1 DESCRIPTION

This module writes out the index files for a CPAN::Mini::Archive.

=head1 METHODS

=head2 write($archive, $basedir)

This method writes the index files for the given archive to their expected
locations under the given base directory.

=cut

sub write {
	my ($class, $archive, $base) = @_;

	$class->write_01packages($archive, $base);
	$class->write_02packages($archive, $base);
}

=head2 write_02packages($archive, $basedir)

=cut

sub write_02packages {
	my ($class, $archive, $base) = @_;

	my $filename = catfile($base,'modules/02packages.details.txt.gz');
	my $package_file = gzopen($filename, 'wb')
		or die "can't open $filename for writing";

	$package_file->gzwrite($class->__02packages_content($archive));
	$package_file->gzclose;
}

sub __02packages_content {
	my ($class, $archive) = @_;

	my @index;
	for my $dist ($archive->distributions) {
		push @index,
			map { $class->__02packages_line($_->package, $dist->prefix, $_->version) }
			$dist->contains;
	}

	my $size = @index;
	my $time = gmtime;

	my $output = <<"END_HEADER";
File:         02packages.details.txt
Description:  Package names found in directory \$CPAN/authors/id/
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:   CPAN::Mini
Line-Count:   $size
Last-Updated: $time GMT

END_HEADER

	$output .= join("\n", sort { lc $a cmp lc $b } @index);
	return "$output\n";
}

sub __02packages_line {
	my ($class, $module, $file, $version) = @_;
	# $module .= ' ' while(length($module)+length($version) < 38);
	$module .= ' ' x (38 - (length($module)+length($version)));
	return "$module $version  $file";
}

=head2 write_01mailrc($archive, $basedir)

=cut

sub write_01mailrc {
	my ($class, $archive, $base) = @_;

	my $filename = catfile($base,'authors/01mailrc.txt.gz');
	my $mailrc_file = gzopen($filename, 'wb')
		or die "can't open $filename for writing";

	$mailrc_file->gzwrite($class->__01mailrc_content($archive));
	$mailrc_file->gzclose;
}

sub __01mailrc_content {
	my ($class, $archive) = @_;
	my @output = map { $class->__01mailrc_line($_) } $archive->authors;
	return join("\n", @output);
}

sub __01mailrc_line {
	my ($class, $author) = @_;
	sprintf 'alias %-10s "%s <%s>"', map { $author->$_ } qw(pauseid name email);
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
