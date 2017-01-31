#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use Getopt::Long;

## INPUT PARAMS ###############################################################

my ($daaList,$targetList,$hitList,$assemList,$samList,$outpath);
my ($flag_gethits,$flag_getreads,$flag_mapassem,$flag_doplot) = (0,0,0,0);

Getoptions("daa=s"=>\$daaList,
           "target=s"=>\$targetList,
           "assem=s"=>\$assemList,
           "hits=s"=>\$hitList,
           "out=s"=>\$outpath) or die ("$!");

## GLOBAL VARS ################################################################

my %daa_hash;
my %target_hash;
my %assem_hash;


## MAIN #######################################################################









## SUBROUTINES ################################################################

sub gethits {
    my ($out6file,$accfile) = @_;
    my %acc_hash;
    my @reads_arr;
    # Hash of Uniprot accessions to find in out6 file
    open(ACC, "<", $accfile) or die ("$!");
    while (<ACC>) {
        chomp;
        $acc_hash{$_} = 1;
    }
    close(ACC);
    # Search Diamond out6 output
    open(DIAM, "<", $out6file) or die ("$!");
    while (<DIAM>) {
        chomp;
        my $line = $_;
        my @splitline = split /\s+/, $line;
        my @accsplit = split /\|/, $splitline[1]; # Split Uniprot header field
        if (defined $acc_hash{$accsplit[1]}) {
            push @reads_arr, $splitline[0]; # Add read to output list
        }
    }
    close(DIAM);
    return(@reads_arr);
}