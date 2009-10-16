use Data::Dumper;
use Data::FormValidator;

package Data::FormValidator::Results;

sub problems {
  my ($self, $field) = @_;
  if ($self->{problems}) {
    return $self->{problems}{$field} if $field;
    return $self->{problems}
  }
  for ($self->missing) { $self->{problems}{$_}{missing} = undef }
  for my $field ($self->invalid) {
    if (my @constraints = grep { defined $_ } @{$self->invalid($field)}) {
      $self->{problems}{$field}{$_} = undef for @constraints;
    } else {
      $self->{problems}{$field}{invalid} = undef;
    }
  }
  return $self->problems($field);
}

package main;

sub validate_prefs {
  my ($self, $prefs) = @_;

  my $profile = {
    required     => [qw(password)],
    optional     => [qw(password_1 password_2 email)],
    constraints  => {
      email => 'email',
      password_1 => {
        name       => 'mismatch',
        params     => [qw(password_1 password_2)],
        constraint => sub { $_[0] eq $_[1] },
      }
    },
    dependency_groups => { new_password => [qw(password_1 password_2)] }
  };
  
  my $results = Data::FormValidator->check($prefs, $profile);
}

my $prefs = {
  password   => '123',
  password_1 => 'newpasswod',
  password_2 => 'newpassword',
  email      => 'bob@bobco.com',
};

my $results = main->validate_prefs($prefs);

print Dumper($results->msgs);
print Dumper($results->problems('password_1'))
