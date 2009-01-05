#!/usr/bin/perl

=head1 NAME

Games::Goban::Image - prints board diagrams for Games::Goban boards

=head1 SYNOPSIS

  use Games::Goban;
  use Games::Goban::Image;

  $board = Games::Goban->new( size => 19 );

  print $board->as_text;

  open IMAGE, ">board.png";
  binmode IMAGE; # for Win32 people, mostly
  print IMAGE $board->as_png;
  close IMAGE;

=head1 DESCRIPTION

=cut

package Games::Goban;

use strict;

use GD;

=item png($size)

This method returns a PNG image of the board, I<$size> pixles on an edge.  I
have found that standard (19x19) boards smaller than 130 pixels are illegible,
and boards smaller than 225 pixels have poorly-defined star points.

=cut

sub png {
	my ($self,$size) = @_;

	my (%board, %star, %stone);

	$board{min}=int($size * .01);
	$board{max}=int($size * .99);

	$board{grid}->{min}=$board{min} + (($board{max}-$board{min}) / (2 * $self->{lines}));
	$board{grid}->{max}=$board{max} - (($board{max}-$board{min}) / (2 * $self->{lines}));
	$board{grid}->{space}=($board{grid}->{max}-$board{grid}->{min})/($self->{lines}-1);

	$board{img}=GD::Image->new($size,$size);

	$board{color}->{black}=$board{img}->colorAllocate(0,0,0);
	$board{color}->{brown}=$board{img}->colorAllocate(128,128,0);

	$board{img}->filledRectangle($board{min},$board{min},$board{max},$board{max},$board{color}->{brown});

	for (my $i=0; $i<$self->{lines}; $i++) {
		$board{img}->line(
			$board{grid}->{min},$board{grid}->{min}+($i*$board{grid}->{space}),
			$board{grid}->{max},$board{grid}->{min}+($i*$board{grid}->{space}),
			$board{color}->{black}
		);
	}
	for (my $i=0; $i<$self->{lines}; $i++) {
		$board{img}->line(
			$board{grid}->{min}+($i*$board{grid}->{space}),$board{grid}->{min},
			$board{grid}->{min}+($i*$board{grid}->{space}),$board{grid}->{max},
			$board{color}->{black}
		);
	}

# create image of black stone

	$stone{b}{dia}=int($board{grid}->{space} * .9);
	$stone{b}{img}=GD::Image->new($stone{b}{dia},$stone{b}{dia});
	$stone{b}{color}->{trans}=$stone{b}{img}->colorAllocate(1,1,1);
	$stone{b}{color}->{black}=$stone{b}{img}->colorAllocate(1,1,1);
	$stone{b}{img}->arc(
		$stone{b}{dia}/2,
		$stone{b}{dia}/2,
		$stone{b}{dia},
		$stone{b}{dia},
		0,
		360,
		$stone{b}{color}->{black}
	);
	$stone{b}{img}->fill(
		$stone{b}{dia}/2,
		$stone{b}{dia}/2,
		$stone{b}{color}->{black}
	);
	$stone{b}{img}->transparent($stone{b}{color}->{trans});

# create image of white stone

	$stone{w}{dia}=int($board{grid}->{space} * .9);
	$stone{w}{img}=GD::Image->new($stone{w}{dia},$stone{w}{dia});
	$stone{w}{color}->{trans}=$stone{w}{img}->colorAllocate(1,1,1);
	$stone{w}{color}->{black}=$stone{w}{img}->colorAllocate(0,0,0);
	$stone{w}{color}->{white}=$stone{w}{img}->colorAllocate(255,255,255);
	$stone{w}{img}->arc(
		$stone{w}{dia}/2,
		$stone{w}{dia}/2,
		$stone{w}{dia},
		$stone{w}{dia},
		0,
		360,
		$stone{w}{color}->{black}
	);
	$stone{w}{img}->fill(
		$stone{w}{dia}/2,
		$stone{w}{dia}/2,
		$stone{w}{color}->{white}
	);
	$stone{w}{img}->transparent($stone{w}{color}->{trans});

# create image of star point

	$star{dia}=int($size/75)+1;
	$star{img}=GD::Image->new($star{dia},$star{dia});
	$star{color}->{trans}=$star{img}->colorAllocate(1,1,1);
	$star{color}->{black}=$star{img}->colorAllocate(0,0,0);
	$star{img}->arc(
		$star{dia}/2,
		$star{dia}/2,
		$star{dia},
		$star{dia},
		0,
		360,
		$star{color}->{black}
	);
	$star{img}->fill(
		$star{dia}/2,
		$star{dia}/2,
		$star{color}->{black}
	);
	$star{img}->transparent($star{color}->{trans});

# place star points

	foreach my $starpoint (@{_stars($self->{lines})}) {
		$board{img}->copy(
			$star{img},
			$board{grid}->{min}+(($starpoint->[0]-1) * $board{grid}->{space})-($star{dia}/2),
			$board{grid}->{min}+(($starpoint->[1]-1) * $board{grid}->{space})-($star{dia}/2),
			0,
			0,
			$star{dia},
			$star{dia}
		);
	}
	
# stone-placing sub
	
	sub png_place_stone {
		my ($color, $x, $y) = @_;

		$board{img}->copy(
			$stone{$color}{img},
			$board{grid}->{min}+(($x-1) * $board{grid}->{space})-($stone{$color}{dia}/2),
			$board{grid}->{min}+(($y-1) * $board{grid}->{space})-($stone{$color}{dia}/2),
			0,
			0,
			$stone{$color}{dia},
			$stone{$color}{dia}
		);
	}

# place a white and black stone

	png_place_stone(BLACK,5,5);
	png_place_stone(BLACK,5,6);
	png_place_stone(WHITE,6,5);
	png_place_stone(WHITE,$self->{lines},$self->{lines});

# return image

	return $board{img}->png;

}

"Butterflies.";
