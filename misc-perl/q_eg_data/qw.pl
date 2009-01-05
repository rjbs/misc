use Querylet; # a subclass of Querylet

database: dbi:SQLite:dbname=wafers.db

query:
  SELECT wafer_id, material, diameter, failurecode
  FROM   grown_wafers
  WHERE  reactor_id = 105
    AND  product_type <> 'Calibration'

add column surface_area:
  $value = $row->{diameter} * 3.14;

add column cost:
  $value = $row->{surface_area} * 100 if $row->{material} eq 'GaAs';
  $value = $row->{surface_area} * 200 if $row->{material} eq 'InP';

munge column failurecode:
  $value = 10 if $value == 3; # 3's have been reclassified

munge all values:
  $value = '(null)' unless defined $value;

output format: html
