package Bryar::Document::RJBS;

use base qw(Bryar::Document);

use Text::WikiFormat;

sub content {
	Text::WikiFormat::format(
		shift->{content},
		{ paragraph   => [ "\n", "\n", '', ' ', 1 ]},
		{ implicit_links => 0 }
	)
};

sub keywords { shift->{keywords} }

sub new {
    my $class = shift;
    my %args = @_;
    my $self = bless {
        epoch =>  $args{epoch} ,
        content =>  $args{content} ,
        author =>  $args{author} ,
        category =>  $args{category} ,
        title =>  $args{title} ,
        id => $args{id},
        keywords => $args{keywords},
        comments => ($args{comments} || [])

    }, $class;
    return $self;
}

1;
