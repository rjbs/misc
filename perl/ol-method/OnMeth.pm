use strict;
use warnings;

package OnMeth;
use Test::More;

sub rigs {
  my %rig;

  $rig{_01_old_call} = sub {
    my ($obj, $method, $args) = @_;
    my $class = ref $obj;
    $class->invoke_method($obj, $method, $args);
  };

  $rig{_02_direct_eval} = sub {
    my ($obj, $method, $args) = @_;
    my $code = qq{\$obj->$method(\@\$args);};
    if (wantarray) {
      my @result;
      eval "\@result = $code; 1" or die;
      return @result;
    } else {
      my $result;
      eval "\$result = $code; 1" or die;
      return $result;
    }
  };

  $rig{_03_direct_by_name} = sub {
    my ($obj, $method, $args) = @_;
    $obj->$method(@$args);
  };

  return %rig;
}

sub test_with_rigs {
  my ($self, $code) = @_;

  my %rig = OnMeth->rigs;
  for my $rig_name (sort keys %rig) {
    diag "beginning to test with $rig_name";
    $code->($rig{ $rig_name });
  }
}

1;
