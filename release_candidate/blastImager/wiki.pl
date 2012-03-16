#!/usr/bin/perl -w

use WWW::Wikipedia;
use strict;

my $wiki = WWW::Wikipedia->new(language => 'en');

## search 
my $result = $wiki->search($ARGV[0]);

if ($wiki->error()){
	print $wiki->error();
} else {
## if the entry has some text print it out
if ( $result->text() ) { 
    print $result->text();
}
}

