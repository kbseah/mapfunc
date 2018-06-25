#!/usr/bin/env perl

# From table of protein names and corresponding Uniprot accession numbers,
# count number of hits per protein name and report as table

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
#my $single;

GetOptions("daa=s"=>\$daaList,
           "target=s"=>\$targetList,
           "outdir=s"=>\$outdir,
           "outfile=s"=>\$outlog,
           "threads=i"=>\$threads,
           #"single"=>\$single,
           "full"=>\$getfull,
           "tblout6"=>\$is_out6) or die ("$!");

## GLOBAL VARS ################################################################

my $diamond_bin = "/usr/local/bin/diamond_v0.8.34";
my $seqtk_bin = "/home/kbseah/tools/seqtk/seqtk";

my %lib_daa_hash; # Hash of daa file paths, keyed by library names
my %target_stats_hash; # Hash of target_avg_lengths, keyed by target names

## MAIN #######################################################################

# Read table of daa file paths and hash by library name
print STDERR "Reading table of DAA file paths\n";
my $ref1 = hashTSV_KV($daaList);
%lib_daa_hash = %$ref1;

# Read table of protein names and corresponding Uniprot accessions and hash
# by the Uniprot accession
print STDERR "Reading table of targets and Uniprot accessions\n";
my $targethref = hashTSV($targetList,1,0);

# Open log file for writing
#open(LOG, ">>", $outlog) or die ("$!");
my $outpath = $outdir."/mapfunc_counthits.list";
$outpath = File::Spec->rel2abs ($outpath); # Use absolute path
if (! -f $outpath) { # Check if output file already exists
    open(my $fhout, ">", $outpath) or die ("$!");
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
        my $countshref = gethits($curr_out6,$targethref);
        # Report output
        foreach my $target (sort keys %$countshref) {
            my $len = scalar @{$countshref->{$target}};
            #$len = $len * 2 unless $single; # Multiply by two (paired-end reads) unless single-end reads
            print $fhout join "\t", ($lib,$target,$len);
            print $fhout "\n";
        }
        
        # Report full list of reads hitting each target per library, if requested
        if ($getfull) {
            my $outpathfull = "$outdir/$lib\_mapfunc_hit_reads.tsv";
            my $fhoutfull;
            $outpathfull = File::Spec->rel2abs($outpathfull);
            open($fhoutfull, ">", $outpathfull) or die ("$!") unless (-f $outpathfull);
            foreach my $target (sort keys %$countshref) {
                foreach my $hitread (@{$countshref->{$target}}) {
                    print $fhoutfull join "\t", ($lib, $target, $hitread);
                    print $fhoutfull "\n";
                }
            }
            close $fhoutfull;
        }
        
        # Remove Out6 formatted file
        system ("rm $curr_out6"); 
    }
    close ($fhout);
} else {
    print STDERR "File $outpath already exists, skipping \n";
}

#close(LOG);

## SUBROUTINES ################################################################

sub gethits {
    my ($out6file,$href) = @_;
    my %hash;
    # Search Diamond out6 output
    open(DIAM, "<", $out6file) or die ("$!");
    while (my $line = <DIAM>) {
        chomp $line;
        my @splitline = split /\s+/, $line;
        my @accsplit = split /\|/, $splitline[1]; # Split Uniprot header field
        if (defined $href->{$accsplit[1]}) {
            my $target = $href->{$accsplit[1]};
            push @{$hash{$target}}, $splitline[0];
            #print OUT "\n";
            #push @reads_arr, $splitline[0]; # Add read to output list
        }
    }
    close(DIAM);
    return (\%hash);
}


