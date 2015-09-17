#!/usr/bin/perl

use warnings;
use strict;
use Fatal qw/open/;

binmode STDIN, ":encoding(utf8)";
binmode STDOUT, ":encoding(utf8)";

my $file1 = "/data/yayamamo/LSD/2014/03Eng-Jap_utf8.txt";
my $file2 = "/data/yayamamo/LSD/2014/16Desc_utf8.txt";
my $source = "/data/yayamamo/hpo/LSD2HPO.txt";

my %dictionary;

open(my $fh, "<:encoding(utf8)", $file1);
while(<$fh>){
    chomp;
    my ($eid, $elabel, undef, $jlabel, undef, $jcode) = split /\t/;
    push @{$dictionary{$eid}}, $jlabel;
}
close($fh);
open($fh, "<:encoding(utf8)", $file2);
while(<$fh>){
    chomp;
    my ($eid, $jlabel, $elabel) = split /\t/;
    push @{$dictionary{$eid}}, $jlabel;
}
close($fh);

open($fh, "<:encoding(utf8)", $source);
while(<$fh>){
    chomp;
    next if index($_, ">") != 0;
    if(/^>H/){ # Exact match
	my ($hpid, $label, $ecode) = split /\t/;
	$hpid = substr($hpid, 1);
	print join("\t", ($hpid, $label, join(" OR ", @{$dictionary{$ecode}} ))), "\n";
    }elsif(/^>>H/){ # Partial match
	my ($hpid, $label, $ecodewords) = split /\t/;
	$hpid = substr($hpid, 2);
	my @ewordset = map {s/:[A-Z]\d+$//;$_} split /$;/, $ecodewords;
	my @ecodeset = map {m,:([A-Z]\d+)$,;$1} split /$;/, $ecodewords;
	print join("\t",
		   ($hpid, $label,
		    join("|", @ewordset),
		    join("|", map{ join(" OR ", @{$dictionary{$_}} )} grep {$dictionary{$_}} @ecodeset),
		   )), "\n";
    }elsif(/^>>>H/){ # Unmatch
	print substr($_, 3), "\n";
    }
}
close($fh);

__END__
