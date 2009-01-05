#!/usr/bin/perl

## by rjbs
## origin: when learning how to tie
## Stubborn scalars must have their value set twice before it sticks

package Stubborn;

sub TIESCALAR {
	my $class = shift;

	bless { cur => 0, last => 0 }, $class;
}

sub FETCH {
	my ($self) = @_;

	return $self->{cur};
}

sub STORE {
	my ($self, $value) = @_;

	if ($self->{last} == $value) {
		$self->{cur} = $value;
		return $value;
	} else {
		$self->{last} = $value;
		return $value;
	}
}

sub DESTROY {
}

package Stubborn::Object;

sub new {
	my $class = shift;

	tie $self, "Stubborn";

	bless \$self, $class;
}

sub ordinal {
	my $self = shift;

	return "${$self}th";
}

package main;

my $mule = Stubborn::Object->new;

print "Initial Value: $$mule\n";

print "set to 1\n";
$$mule = 1;
print "New Value: $$mule\n";

print "set to 1\n";
$$mule = 1;
print "New Value: $$mule\n";

print "\n", $mule->ordinal, "\n";
