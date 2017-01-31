#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use File::Spec;

# Use local module
use FindBin;
use lib $FindBin::RealBin;
use Mapfunc;

my ($mappedList,$readsfList,$readsrList);
my $outdir = "./output";

GetOptions("hitslog=s"=>\$mappedList,
           "readsf=s"=>\$readsfList,
           "readsr=s"=>\$readsrList,
           "outdir=s"=>\$outdir) or die ("$!");

## GLOBAL VARS ################################################################

my %lib_fwd_hash; # Hash of forward reads, keyed by library name
my %lib_rev_hash; # Hash of reverse reads, keyed by library name
my %lib_ref_file_hash; # Hash of lists, key1 library name, key2 reference name 
my $seqtk_bin = "/home/kbseah/tools/seqtk/seqtk";
my $gzip_bin = "/bin/gzip";

## MAIN #######################################################################

# Read table of Fastq file names and hash by library name
my $ref1 = hashTSV_KV($readsfList);
%lib_fwd_hash = %$ref1;
my $ref2 = hashTSV_KV($readsrList);
%lib_rev_hash = %$ref2;

# Read table of lists of reads to extract
my $ref3 = hashTSV_KKV ($mappedList);
%lib_ref_file_hash = %$ref3;

foreach my $lib (sort {$a cmp $b} keys %lib_ref_file_hash) {
    foreach my $ref (sort {$a cmp $b} keys %{$lib_ref_file_hash{$lib}}) {
        print STDERR "Getting reads for library $lib and reference $ref\n";
        my $listpath = $lib_ref_file_hash{$lib}{$ref};
        my ($listfile,$listdirs,$listsuffix) = fileparse($listpath,".list");
        # Make names for output Fastq files
        my $outfwd = $listdirs.$listfile.".R1.fq.gz";
        my $outrev = $listdirs.$listfile.".R2.fq.gz";
        # Extract reads with seqtk unless files already exist
        if (! -f $outfwd) {
            my @seqtk_fwd_params = ("subseq",
                                    $lib_fwd_hash{$lib},
                                    $listpath,
                                    "| $gzip_bin >",
                                    $outfwd);
            print STDERR "Forward reads... \n";
            doSystem(($seqtk_bin, @seqtk_fwd_params));
        } else {
            print STDERR "File $outfwd already exists! Skipping \n";
        }
        if (! -f $outrev) {
            my @seqtk_rev_params = ("subseq",
                                    $lib_rev_hash{$lib},
                                    $listpath,
                                    "| $gzip_bin >",
                                    $outrev);
            print STDERR "Reverse reads... \n";
            doSystem(($seqtk_bin, @seqtk_rev_params));
        } else {
            print STDERR "File $outrev already exists! Skipping \n";
        }
    }
}
