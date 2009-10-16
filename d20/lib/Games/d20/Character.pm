package Games::d20::Character;

use warnings;
use strict;

use base qw(Class::Accessor);
use YAML qw(LoadFile);

=head1 NAME

Games::d20::Character - a d20-system character class (no pun intended)

=head1 VERSION

version 0.01

 $Id$

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This class represents a character record for a d20 system game such as D&D or
Call of Cthulhu.

=head1 DESCRIPTION

(this space intentionally left blank)

=head1 METHODS

=head2 C<< $class->from_file($filename) >>

=cut

sub from_file {
  my ($self, $filename) = @_;
  my $record = LoadFile($filename);
  bless $record => $self;
}

__PACKAGE__->mk_accessors( qw(name age race gender alignment hp) );
__PACKAGE__->mk_ro_accessors( qw(classes attributes skills) );

sub attribute {
  my ($self, $attribute) = (shift, shift);

  my ($attr) = grep { lc $self->attributes->[$_]{attribute} eq lc $attribute }
                    (0 .. $#{$self->attributes});

  @_ ? defined $attr
       ? defined $_[0]
         ? $self->attributes->[$attr]{value} = $_[0]
         : do { splice @{$self->attributes}, $attr, 1; return undef; }
       : defined $_[0]
         ? do { push @{$self->attributes},
                     { attribute => $attribute, value => $_[0] };
                return $_[0] }
         : return undef
     : defined $attr
       ? return $self->attributes->[$attr]{value}
       : return undef;
}

sub attr_modifier {
  my ($self, $attribute) = @_;
  my $value = $self->attribute($attribute);
  return unless defined $value;
  return -5 + int($value / 2);
}

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-games-d20-character@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-d20-Character>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT

Copyright 2005 Ricardo SIGNES, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
