use warnings;

use Crypt::OpenSSL::RSA;

my $username = 'rjbs';
my $servername = 'spectral.shadowcat.co.uk';

my $private_file = "/home/$username/.irssi/oper-keys/$servername";

-f $private_file
  or die("Unable to find key at '$private_file'");

-s $private_file
  or die("Keyfile '$private_file' has no size, skipping.");

my $challenge = $ARGV[0];

$challenge =~ s/^[^:]+://;

open my $private_fh, '<', $private_file
  or return bail("Couldn't open keyfile '$private_file': $!");

my $private_string = do {
  local $/;
  <$private_fh>;
};

my $private_key = Crypt::OpenSSL::RSA->new_private_key($private_string);

$private_key->check_key()
  or return bail("Invalid RSA private key.");

$private_key->use_pkcs1_padding;

my $binary_challenge = pack("H*", $challenge);

my $binary_response = $private_key->decrypt($binary_challenge);

print("challenge +" . unpack("H*", $binary_response), "\n");
