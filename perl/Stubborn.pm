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

"Mule.";
