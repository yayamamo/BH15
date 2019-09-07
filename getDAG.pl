#!/usr/bin/perl

use warnings;
use strict;
use Fatal qw/open/;
use RDF::Trine;
use Time::HiRes qw/sleep/;

# my $epurl = "http://localhost:18890/sparql";
my $epurl = "http://localhost:21200/HPO/query";

my $query_template = "SELECT ?s ?l {
  ?s a owl:Class ;
     rdfs:label ?l ;
     rdfs:subClassOf _uri_ .
}";

my $sp = new RDF::Trine::Store::SPARQL( $epurl );

my $root = "<http://purl.obolibrary.org/obo/HP_0000001>";
getChildren($root, 1);

sub getChildren {
    my $root = shift;
    my $depth = shift;
    (my $query = $query_template) =~ s/_uri_/$root/;
    my $it;
    eval{ $it = $sp->get_sparql( $query ); };
    if($@){
	warn "Something wrong: $!\n";
    }
    my @uris;
    while (my $row = $it->next) {
	my @vars = @$row{qw/s l/};
	print join("\t", ($depth, @vars)), "\n";
	push @uris, $vars[0];
    }
    for ( @uris ){
	print "+", $_, "\n";
	getChildren($_, $depth+1);
    }
    sleep 0.1;
}

__END__
