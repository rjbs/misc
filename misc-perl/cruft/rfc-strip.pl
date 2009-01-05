#!/usr/bin/perl

## by rjbs
## origin: creation of the reference
## removes base URL of faqs.org from links in RFCs

$files=`echo rfc/*.html`;
@files=split(" ",$files);

foreach $file (@files) {
  if ($file =~ /(rfc\d{1,4}\.html)/) {
    open(INFILE,$file);
    open(OUTFILE,">newrfc/$1");
    
    while ($inline=<INFILE>) {
      $inline=~s/http:\/\/www\.faqs\.org\/rfcs\///g;
      print OUTFILE $inline;
    }

    close(INFILE);
    close(OUTFILE);
  } else {
    print "Skipping non-RFC file.\n";
  }
}
