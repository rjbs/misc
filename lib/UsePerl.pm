#!/usr/bin/perl -w -T

package UsePerl;

use strict;
use HTML::TreeBuilder;
use Slash::Client::Journal;
use Text::Markdown;
 
my $host        = 'use.perl.org';

my $journal = Slash::Client::Journal->new({
  host => 'use.perl.org',
  uid  => 4671,
  pass => 'password',
});

sub add_entry { shift;
  my ($arg) = @_;
	my ($title, $content, $uri) = @$arg{qw(title body uri)};
  my $posttype = 1; # default: plain old text
  if ($arg->{tags}||'' =~ /\@markup:md/) {
    $content = "[$title]($uri)\n\n$content" if $uri;
    $content =~ s/!\[/\[inline image:/g;
    $content = Text::Markdown::markdown($content, { tab_width => 2 });
    $content =~ s|<pre><code>|<ecode>|g;
    $content =~ s|</code></pre>|</ecode>|g;

    my $tb = HTML::TreeBuilder->new;
    $tb->implicit_tags(0);

    my $root = $tb->parse($content);
    $tb->eof;

    my (@ecodes) = $root->look_down(_tag => 'ecode');

    for my $ecode (@ecodes) {
      # We're basically guaranteed that ecode has no HTML contents.
      my $string = join '', $ecode->content_list;

      $ecode->delete_content;
      $ecode->push_content(HTML::Element->new('~literal', text => $string));
    }

    $content = $root->as_XML;

    $posttype = 2; # html
  } else {
    $content = "$uri\n\n$content" if $uri;
  }
	my $j = {
    subject  => $title,
    body     => $content,
    posttype => $posttype,
  };

	my $new_id  = $journal->add_entry($j);
  
  die "didn't get a new journal entry id, got "
    . (defined $new_id ? $new_id : 'undef') unless $new_id;
}

1;
