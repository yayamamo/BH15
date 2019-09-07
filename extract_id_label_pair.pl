#!/usr/bin/env perl

use warnings;
use strict;
use Fatal qw/open/;
use open 'utf8';
use RDF::Trine;
use RDF::Trine::Parser;

sub parse {
  my $_ = $_[0]->subject;
  if(/HP_\d+/ && index($_[0]->predicate, "#label") > 0){
    (my $hpoid = $&) =~ s/_/:/;
    print join("\t", ($hpoid, $_[0]->object->value)), "\n";
  } 
}

if(@ARGV != 1){
  die "Specify an ntriple file.\n";
}
open(my $fh, $ARGV[0]);
my $base_uri = "file:///"; 
my $parser = RDF::Trine::Parser->new( 'rdfxml' );
$parser->parse_file ( $base_uri, $fh, \&parse );
close($fh);

__END__
