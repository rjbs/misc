use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CPAN::Mini::Archive',
    AUTHOR              => 'Ricardo Signes <rjbs@cpan.org>',
    VERSION_FROM        => 'lib/CPAN/Mini/Archive.pm',
    ABSTRACT_FROM       => 'lib/CPAN/Mini/Archive.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Carp'           => 0,
        'Compress::Zlib' => 0,
        'Cwd'            => 0,
        'LWP::Simple'    => 0,
        'Test::More'     => 0,
        'URI'            => 0,
        'Parse::CPAN::Authors'  => 2.24,
        'Parse::CPAN::Packages' => 2.24,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CPAN-Mini-Archive-* cover_db' },
);
