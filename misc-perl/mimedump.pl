use MIME::Parser;

### Create parser, and set some parsing options:
my $parser = new MIME::Parser;
$parser->output_under("$ENV{HOME}/");

### Parse input:
$entity = $parser->parse(\*STDIN) or die "parse failed\n";

### Take a look at the top-level entity (and any parts it has):
#$entity->print_body(\*STDOUT);

$bh = $entity->bodyhandle;

$bh->print(\*STDOUT);
