#!/usr/bin/perl

use warnings;
use strict;
use Fatal qw/open/;
use Text::Scan;

my $V   = qr/[aeiou]/;
my $VY  = qr/[aeiouy]/;
my $C   = qr/[bcdfghjklmnpqrstvwxyz]/;
my $CXY = qr/[bcdfghjklmnpqrstvwxz]/;
my $S   = qr/([sxz]|[cs]h)/;
my $S2  = qr/(ss|zz)/;
my $PRE = qr/(be|ex|in|mis|pre|pro|re)/;

binmode STDIN, "encoding(utf8)";
binmode STDOUT, "encoding(utf8)";

# my $file1 = "/data/yayamamo/hpo/MP_J_tsv.txt";
my $file1 = "/data/yayamamo/hpo/MP_eav0904_tsv.txt";

my %dictionary;

open(my $fh, "<:encoding(utf8)", $file1);
while(<$fh>){
    chomp;
    my ($id, $ja_label, $en_label) = split /\t/;
    next unless $en_label;
    $dictionary{$en_label} = $id;
}
close($fh);

my $dict = new Text::Scan;
#$dict->charclass(".:;,?");
$dict->boundary("/.? ");
$dict->ignore(".:;,?");
$dict->ignorecase();
$dict->squeezeblanks;
while(my ($k, $v) = each %dictionary){
    $dict->insert($k, $v);
    my $lem = join(" ", map{lemmatizeNN($_)} split " ", $k);
    if($k ne $lem){
	$dict->insert($k, $v);
    }
}

open($fh, "hpo.fingerprint");
while(<$fh>){
    chomp;
    next if index($_, "HPO_ID") == 0;
    my ($hpid, $label, undef) = split /\t/;
    my $rv = matchDict($hpid, $label, $label);
    my $trv;
    if($rv){
	if($rv->{type} eq "E"){
	    print ">", $rv->{value}, "\n";
	}else{
	    $trv = $rv;
	}
    }
    if(!$rv || $trv){
	my $lem = join(" ", map{lemmatizeNN($_)} split " ", $label);
	if($lem eq $label){
	    if($trv){
		print ">>", $trv->{value}, "\n";
	    }
	}else{
	    $rv = matchDict($hpid, $lem, $label);
	    if($rv){
		if($rv->{type} eq "E"){
		    print ">", $rv->{value}, "\n";
		}else{
		    if($trv){
			if($trv->{nofw} < $rv->{nofw}){
			    print ">>", $rv->{value}, "\n";
			}else{
			    print ">>", $trv->{value}, "\n";
			}
		    }else{
			print ">>", $rv->{value}, "\n";
		    }
		}
	    }elsif($trv){
		print ">>", $trv->{value}, "\n";
	    }
	}
    }
    unless($rv || $trv){
	print ">>>", join("\t", ($hpid, $label)), "\n";
    }
}
close($fh);

sub matchDict {
    my $hpid = shift;
    my $lem = shift;
    my $label = shift;
    my @result = $dict->multiscan($lem);
    (my $lb = $lem) =~ s,[/.? ], ,g;
    my $return_value;
    if ( @result ){
	my (%candidates, %positions, %translations);
	my $label_len = ($lb =~ tr/ / /);
	my $total_length = length($label);
	for ( @result ){
	    print join("\t", ($hpid, $label, @$_,
			      (($label eq $_->[0] || $lem eq $_->[0])?"o":"x"))), "\n";
	    my $nofw = ($_->[0] =~ tr/ / /);
	    $candidates{$_->[0]} = $nofw;
	    $positions{$_->[0]} = $_->[1];
	    $translations{$_->[0]} = $_->[2];
	}
	my %outputs;
	for (sort {$candidates{$b}<=>$candidates{$a}} keys %candidates){
	    if($candidates{$_} == $label_len){
		# print "N>", join("\t", ($hpid, $label, $translations{$lb})), "\n";
		$return_value = {
		    "type" => "E",
		    "nofw" => $label_len + 1,
		    "value" => join("\t", ($hpid, $label, $translations{$lb})),
		};
		last;
	    }else{
		my $atd = 99 - $candidates{$_};
		$outputs{$positions{$_}.".".$atd} = $_;
	    }
	}
	if(%outputs){
	    my @final;
	    my $total = 0;
	    for (sort {$a <=> $b} keys %outputs){
		next if $total > $_;
		$total = substr($_, 0, index($_, ".")) + length($outputs{$_});
		push @final, $outputs{$_}.":".$translations{$outputs{$_}};
		last if $total >= $total_length;
	    }
	    # print "N>>", join("\t", ($hpid, $label, join(" ", @final))), "\n";
	    $return_value = {
		"type" => "P",
		"nofw" => scalar @final,
		"value" => join("\t", ($hpid, $label, join("$;", @final))),
	    };
	}
    }
    return $return_value;
}

sub lemmatizeNN {
    # Obtained from Treex::Tool::EnglishMorpho::Lemmatizer
    # by Institute of Formal and Applied Linguistics, Charles University in Prague
    my $word = shift;
    return $word if $word =~ s/men$/man/;          #over 600 words (in BNC)
    return $word if $word =~ s/shoes$/shoe/;
    return $word if $word =~ s/wives$/wife/;
    return $word if $word =~ s/(${C}us)es$/$1/;    #buses bonuses

    return $word if $word =~ s/(${V}se)s$/$1/;
    return $word if $word =~ s/(.${CXY}z)es$/$1/;
    return $word if $word =~ s/(${VY}ze)s$/$1/;
    return $word if $word =~ s/($S2)es$/$1/;
    return $word if $word =~ s/(.${V}rse)s$/$1/;
    return $word if $word =~ s/onses$/onse/;
    return $word if $word =~ s/($S)es$/$1/;

    return $word if $word =~ s/(.$C)ies$/$1y/;     #ponies vs ties
    return $word if $word =~ s/(${CXY}o)es$/$1/;
    return $word if $word =~ s/s$//;
    return $word;
}

__END__
