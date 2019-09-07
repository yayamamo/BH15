#!/usr/bin/perl

use warnings;
use strict;
use Fatal qw/open/;
use Web::Scraper;
use URI;
use Encode;
use Time::HiRes qw/sleep/;

binmode STDIN, ":encoding(utf8)";
binmode STDOUT, ":encoding(utf8)";

my $def = scraper {
    process 'div#content', "content" => scraper {
	process "h2", "part" => 'TEXT';

	process "div[class]", "divs[]" => 'TEXT';
	process "div[class]", "classes[]" => '@class';

	# process "div.words", "words[]" => 'TEXT';
	# process "div.define_desc", "definitions[]" => 'TEXT';
	# process "div.comment_desc", "comments[]" => 'TEXT';

	process "div.photo>img", "photos[]" => '@src';
      };
  };

my $baseuri = "http://plaza.umin.ac.jp/p-genet/atlas/";
my @pageids =
    qw/03-1 03-2 03-3 03-4 04-1 04-2 05-1 05-2 06-1 06-2 06-3 07-1 07-2 07-3 07-4 08-1 08-2 08-3 08-4 08-5 08-6/;
my %stops = map{$_ => 1} qw/define comment figure_title figure_desc synonim/;

for ( @pageids ){
    my $uri = $baseuri. $_. ".html";
    my $res = $def->scrape( URI->new( $uri ) );

    my $def = $res->{content};
    print "T\t", $def->{part}, "\n";
    for (my $idx = 0; $idx < @{$def->{divs}}; $idx++){
	my $a = $def->{classes}->[$idx];
	my $v = "";
	next if $stops{$a};
	if($a eq "photo"){
	    $v = shift @{$def->{photos}};
	}else{
	    $v = $def->{divs}->[$idx];
	}
	print join("\t", ($a, $v)), "\n";
    }

    # for (my $idx = 0; $idx < @{$def->{words}}; $idx++){
    # 	print "W:", $def->{words}->[$idx], "\n";
    # 	print "D:", $def->{definitions}->[$idx]//"", "\n";
    # 	print "C:", $def->{comments}->[$idx]//"", "\n";
    # 	print "I:", $def->{photos}->[$idx]//"", "\n";
    # }

    sleep 0.8;
}

__END__
