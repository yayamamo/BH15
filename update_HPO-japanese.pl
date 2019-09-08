#!/usr/bin/env perl

use warnings;
use strict;
use Fatal qw/open/;
use open 'utf8';

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";

my $hpo = "hpo.txt";
my $lsd = "HPO2LSD_ja.txt";
my $md = "HPO2MD_ja.txt";
my $mp = "HPO2MP_ja.txt";
my $gt = "hpo_2019-09-07_gt_normalized.txt";
my (%expert, %_lsd, %_md, %_mp, %_gt);

# HPO ID / English term / Japanese term (expert) / Japanese term (Life Science Dictionary) / Japanese term (Mammalian Phenotype Japanese) / Japanese term (Google Translate) / Japanese term (Medical Dictionary)

sub feed {
  my $fh = shift;
  my $dictionary = shift;
  while(<$fh>){
    chomp;
    my ($id, undef, $string1, $string2) = split /\t/;
    $dictionary->{$id} = ($string2 // $string1);
  }
}

my $header = <>;
while(<>){
  chomp;
  my @vals = split /\t/;
  $expert{$vals[0]} = $vals[2];
}

open(my $fh, "<:utf8", $gt);
while(<$fh>){
  chomp;
  my ($id, $string) = split /\t/;
  $_gt{$id} = $string;
}
close($fh);

open($fh, "<:utf8", $lsd);
feed($fh, \%_lsd);
close($fh);

open($fh, "<:utf8", $md);
feed($fh, \%_md);
close($fh);

open($fh, "<:utf8", $mp);
feed($fh, \%_mp);
close($fh);

print join("\t", ("HPO ID", "English term", "Japanese term (expert)", "Japanese term (Life Science Dictionary)", "Japanese term (Mammalian Phenotype Japanese)", "Japanese term (Google Translate)", "Japanese term (Medical Dictionary)")), "\n";

open($fh, $hpo);
while(<$fh>){
  chomp;
  my ($id, $string) = split /\t/;
  print join("\t", ($id, $string, ($expert{$id}//""), ($_lsd{$id}//""), ($_mp{$id}//""), ($_gt{$id}//""), ($_md{$id}//""))), "\n";
}
close($fh);


__END__
