#!/bin/perl
use strict;
use warnings;
die "Just not gonna run if you're root.\n" if $> == 0;

my %dots = (
  'rjbs-dots'     => [ qw( .dir_colors .gitconfig .sqliterc .tmux.conf ) ],
  'rjbs-vim-dots' => [ qw( .vimrc .vim/colors/manxome.vim ) ],
);

my $template = 'https://raw.githubusercontent.com/rjbs/%s/master/%s';

chdir or die "can't chdir home: $!";

for my $repo (keys %dots) {
  for my $file (@{ $dots{ $repo } }) {
    my ($path) = $file =~ m{\A(.+)/[^/]+};
    if (length $path) {
      system("mkdir -p ~/$path\n") and die "couldn't create ~/$path: $!\n";
    }

    my $url = sprintf $template, $repo, $file;
    system("curl $url > $file\n") and die "something went getting $url\n";
  }
}

print "\n### Congratulations, you have installed the minimal rjbs config.\n";
