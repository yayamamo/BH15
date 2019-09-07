#!/usr/bin/perl

use warnings;
use strict;
use Fatal qw/open/;
use Getopt::Std;

binmode STDIN, ":encoding(utf8)";
binmode STDOUT, ":encoding(utf8)";

our(%opts);
getopt('s:', \%opts);

die unless($opts{"s"});

my $file1 = "/data/yayamamo/LSD/2014/03Eng-Jap_utf8.txt";
my $file2 = "/data/yayamamo/LSD/2014/16Desc_utf8.txt";
my $file3 = "/data/yayamamo/hpo/MP_eav0904_tsv.txt";
my $file4 = "/data/yayamamo/hpo/Medical-Dictionary.tsv";

my ($pattern1, $pattern2);
my $source;
if($opts{"s"} eq "LSD"){
    $source = "/data/yayamamo/hpo/LSD2HPO.txt";
    $pattern1 = qr/:[A-Z]\d+$/;
    $pattern2 = qr/:([A-Z]\d+)$/;
}elsif($opts{"s"} eq "MP"){
    $source = "/data/yayamamo/hpo/MP_eav0904_TO_HPO.txt";
    $pattern1 = qr/:MP:\d+$/;
    $pattern2 = qr/:(MP:\d+)$/;
}elsif($opts{"s"} eq "MD"){
    $source = "/data/yayamamo/hpo/MD2HPO.txt";
    $pattern1 = qr/:\d+$/;
    $pattern2 = qr/:(\d+)$/;
}

my %dictionary;

my $fh;

if($opts{"s"} eq "LSD"){
    open($fh, "<:encoding(utf8)", $file1);
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
}elsif($opts{"s"} eq "MP"){
    open($fh, "<:encoding(utf8)", $file3);
    while(<$fh>){
	chomp;
	my ($eid, $jlabel, $elabel) = split /\t/;
	push @{$dictionary{$eid}}, $jlabel;
    }
    close($fh);
}elsif($opts{"s"} eq "MD"){
    open($fh, "<:encoding(utf8)", $file4);
    while(<$fh>){
	chomp;
	my ($id, $jlabel, $ejflag, $elabel) = split /\t/;
	next if $id eq 'id';
	next if $ejflag eq 'true';
	push @{$dictionary{$id}}, $jlabel;
    }
    close($fh);
}

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
	my @ewordset = map {s/${pattern1}//;$_} split /$;/, $ecodewords;
	my @ecodeset = map {m,${pattern2},;$1} split /$;/, $ecodewords;
	print join("\t",
		   ($hpid, $label,
		    join("|", @ewordset),
		    join("|", map{ join(" OR ", @{$dictionary{$_}} )} grep {$dictionary{$_}} @ecodeset),
		   )), "\n";
    }elsif($opts{"u"} && /^>>>H/){ # Unmatch
	print substr($_, 3), "\n";
    }
}
close($fh);

__END__
