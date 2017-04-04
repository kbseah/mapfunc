#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use File::Spec;
use Getopt::Long;

# Use local module
use FindBin;
use lib $FindBin::RealBin;
use Mapfunc;

## INPUT PARAMS ###############################################################

my ($daaList,$targetList);
my $outdir = "./output";
my $outlog = $outdir."/mapfunc_gethits_log";
my $threads = 8;
my $is_out6 = 0;
my $getfull;

GetOptions("daa=s"=>\$daaList,
           "target=s"=>\$targetList,
           "outdir=s"=>\$outdir,
           "outfile=s"=>\$outlog,
           "threads=i"=>\$threads,
           "tblout6"=>\$is_out6) or die ("$!");

## GLOBAL VARS ################################################################

my $diamond_bin = "/usr/local/bin/diamond_v0.8.34";
my $seqtk_bin = "/home/kbseah/tools/seqtk/seqtk";

my %lib_daa_hash; # Hash of daa file paths, keyed by library names
my %ref_target_hash; # Hash of lists of uniprot accessions, keyed by target name

## MAIN #######################################################################

# Read table of daa file paths and hash by library name
my $ref1 = hashTSV_KV($daaList);
%lib_daa_hash = %$ref1;

# Read table of target file paths and hash by target ref name
my $ref2 = hashTSV_KV($targetList);
%ref_target_hash = %$ref2;

# Open log file for writing
open(LOG, ">>", $outlog) or die ("$!");

foreach my $lib (sort {$a cmp $b} keys %lib_daa_hash) {
    my $curr_daa = $lib_daa_hash{$lib};
    # Check if file exists
    if (! -f $curr_daa) {
        print STDERR "Error: File not found: $curr_daa\n";
    }
    # Convert DAA file to OUT6 format unless file already exists
    my ($curr_file,$curr_dirs,$curr_suffix) = fileparse($curr_daa,".daa");
    my $curr_out6 = $curr_dirs.$curr_file.".out6";
    if (! -f $curr_out6) {
        print STDERR "Converting .daa to .out6 for file $curr_daa\n";
        my @diamond_view_params = ("view",
                                   "--daa $curr_daa",
                                   "--outfmt 6",
                                   "-p $threads",
                                   "--out $curr_out6",
                                   "--quiet");
        #my $diamond_cmd = join " ", ($diamond_bin, @diamond_view_params);
        #system("$diamond_cmd");
        doSystem(($diamond_bin, @diamond_view_params));
    } else {
        print STDERR "File $curr_out6 already exists, skipping conversion \n";
    }
    # Get hits matching targets
    foreach my $ref (sort {$a cmp $b} keys %ref_target_hash) {
        print STDERR "Retrieving hits to $ref in library $lib \n";
        # Name for output file
        my $curr_target = $ref_target_hash{$ref};
        my $outpath = $outdir."/mapfunc_".$lib."_".$ref.".list";
        my $outpathfull = $outpath.".full";
        $outpath = File::Spec->rel2abs ($outpath); # Use absolute path
        $outpathfull = File::Spec->rel2abs($outpathfull);
        # Check if output file already exists
        if (! -f $outpath) {
        # Parse the out6 file
            gethits($curr_out6,$curr_target,$outpath,"acc");
            # Record name of output file to log
            print LOG join "\t", ($lib,$ref,$outpath);
            print LOG "\n";
        } else {
            print STDERR "File $outpath already exists, skipping \n";
        }
        if (! -f $outpathfull && $getfull) {
            gethits ($curr_out6,$curr_target,$outpathfull,"full");
        } elsif (-f $outpathfull && $getfull) {
            print STDERR "FIle $outpathfull already exists, skipping \n";
        }
    }
    system ("rm $curr_out6"); # Remove Out6 formatted file
}

close(LOG);

## SUBROUTINES ################################################################

sub gethits {
    my ($out6file,$accfile,$out,$mode) = @_;
    my %acc_hash;
    #my @reads_arr;
    # Hash of Uniprot accessions to find in out6 file
    open(ACC, "<", $accfile) or die ("$!");
    while (<ACC>) {
        chomp;
        $acc_hash{$_} = 1;
    }
    close(ACC);
    # Search Diamond out6 output
    open(OUT, ">", $out) or die ("$!");
    open(DIAM, "<", $out6file) or die ("$!");
    while (<DIAM>) {
        chomp;
        my $line = $_;
        my @splitline = split /\s+/, $line;
        my @accsplit = split /\|/, $splitline[1]; # Split Uniprot header field
        if (defined $acc_hash{$accsplit[1]}) {
            if ($mode eq "acc") {
                print OUT $splitline[0];
            } elsif ($mode eq "full") {
                print OUT $line;
            }
            print OUT "\n";
            #push @reads_arr, $splitline[0]; # Add read to output list
        }
    }
    close(DIAM);
    close(OUT);
}


