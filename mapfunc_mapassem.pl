#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use Getopt::Long;

# Use local module
use FindBin;
use lib $FindBin::RealBin;
use Mapfunc;

my ($assemList,$mappedList);

my $outdir = "./output";
my $threads = 8;

GetOptions ("assems=s"=>\$assemList,
            "hitslog=s"=>\$mappedList,
            "threads=i"=>\$threads,
            "outdir=s"=>\$outdir) or die ("$!");

## GLOBAL VARS ################################################################

my %lib_assem_hash;
my %lib_ref_target_hash;
my $bbmap_bin = "/usr/local/bbmap/bbmap.sh";

## MAIN #######################################################################
my $ref1 = hashTSV_KV ($assemList);
%lib_assem_hash = %$ref1;

my $ref2 = hashTSV_KKV ($mappedList);
%lib_ref_target_hash = %$ref2;

foreach my $lib (sort {$a cmp $b} keys %lib_ref_target_hash) {
    foreach my $ref (sort {$a cmp $b} keys %{$lib_ref_target_hash{$lib}}) {
        my $listpath = $lib_ref_target_hash{$lib}{$ref};
        my ($listfile,$listdirs,$listsuffix) = fileparse($listpath,".list");
        # Get Fastq file names
        my $fwd = $listdirs.$listfile.".R1.fq.gz";
        my $rev = $listdirs.$listfile.".R2.fq.gz";
        if (! -f $fwd || ! -f $rev) {
            print STDERR ("Cannot find read files $fwd and $rev \n");
        }
        # Get current assembly name
        my $currassem = $lib_assem_hash{$lib};
        # make SAM output file name
        my $outsam = $listdirs.$listfile."_v_assem1.sam";
        my $outscafstats = $listdirs.$listfile."_v_assem1.scafstats";
        # Perform mapping, if file does not already exist
        if (! -f $outsam && ! -f $outscafstats) {
            my @bbmap_params = ("nodisk=t",
                                "ref=$currassem",
                                "in=$fwd",
                                "in2=$rev",
                                "fast=t",
                                "threads=$threads",
                                #"out=$outsam",
                                "scafstats=$outscafstats");
            doSystem(("tsp -N 8", $bbmap_bin, @bbmap_params));
        } else {
            print STDERR "File $outsam or $outscafstats already exists \n";
        }
    }
}

