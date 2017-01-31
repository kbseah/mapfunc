#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use Getopt::Long;

# Use local module
use FindBin;
use lib $FindBin::RealBin;
use Mapfunc;

my ($mappedList,$covstatsList,$ssuList,$sptab);

my $outtab = "mapfunc_mapped.tab";
my $outdir = "./output";
my $plotdir = "./plots";
my $singlereads;
my $doplot;
my $dotable;

GetOptions ("covstats=s"=>\$covstatsList,
            "ssu=s"=>\$ssuList,
            "hitslog=s"=>\$mappedList,
            "species=s"=>\$sptab, # Table of library (col1) and species (col2) names
            "outtab=s"=>\$outtab,
            "outdir=s"=>\$outdir,
            "plotdir=s"=>\$plotdir,
            "single"=>\$singlereads,
            "plot"=>\$doplot,
            "table"=>\$dotable) or die ("$!");

## GLOBAL VARS ################################################################

my %lib_cov_hash;
my %lib_ssu_hash;
my %lib_ref_target_hash;
my %lib_ref_mapped_count_hash;
my %lib_sp_hash;

my $Rscript_bin = "/usr/bin/Rscript";
my $plotscript = $FindBin::RealBin."/gbt_map_plot.R";
if (! -f $plotscript && $doplot) {
    print STDERR "Plotting script gbt_map_plot.R not found\n";
    exit;
}

# Read tables of filenames
my $ref1 = hashTSV_KV ($covstatsList);
%lib_cov_hash = %$ref1;
my $ref2 = hashTSV_KV ($ssuList);
%lib_ssu_hash = %$ref2;
my $ref3 = hashTSV_KKV ($mappedList);
%lib_ref_target_hash = %$ref3;

# Read table of species names
if (-f $sptab) {
    my $ref4 = hashTSV_KV($sptab);
    %lib_sp_hash = %$ref4;
} else {
    print STDERR "Species names not given, defaulting to NA\n";
}

# Open output table file for writing
if ($dotable) {
    my $noheader = 1 if -f $outtab; # If appending to existing file, skip header
    open(TAB, ">>", $outtab) or die ("$!");
    # Header line
    print TAB join "\t", ("Library","Species","Target","Total","Mapped","Unmapped") unless $noheader;
    print TAB "\n" unless $noheader;
}

foreach my $lib (sort {$a cmp $b} keys %lib_ref_target_hash) {
    my $cov = $lib_cov_hash{$lib};
    my $ssu = $lib_ssu_hash{$lib};
    foreach my $ref (sort {$a cmp $b} keys %{$lib_ref_target_hash{$lib}}) {
        # Get paths to files
        my $listpath = $lib_ref_target_hash{$lib}{$ref};
        my ($listfile,$listdirs,$listsuffix) = fileparse($listpath,".list");
        my $scafstatspath = $listdirs.$listfile."_v_assem1.scafstats";
        # Check that scafstats file exists
        if (! -f $scafstatspath) {
            print STDERR "Scafstats file $scafstatspath not found!\n";
        } else {
            if ($dotable) { # Output counts to table
                my ($total, $mapped, $unmapped) = (0, 0);
                # Multiply total reads by two if paired-end
                if ($singlereads) {
                    $total = wc($listpath);
                } else {
                    $total = wc($listpath) * 2;
                }
                # Get mapping info from scafstats file if available
                $mapped = sum_scafstats_reads($scafstatspath);
                $unmapped = $total - $mapped;
                # Get species name if one is given
                my $sp;
                if (defined $lib_sp_hash{$lib}) {
                    $sp = $lib_sp_hash{$lib};
                } else {
                    $sp = "NA";
                }
                print TAB join "\t", ($lib,$sp,$ref,$total,$mapped,$unmapped);
                print TAB "\n";
            }
            if ($doplot) { # Make cov-GC plots
                # Name for output file
                my $plotfile = "$plotdir/mapfunc_$ref\_$lib\_gccov.png";
                if (! -f $plotfile) {
                    print STDERR "Making plot for library $lib and target $ref\n";
                    doSystem(($Rscript_bin,
                              "$plotscript",
                              "--args",
                              "$cov",
                              "$ssu",
                              "$scafstatspath",
                              "$plotfile",
                              "$lib",
                              "$ref"));
                } else {
                    print STDERR "Plot file $plotfile already exists \n";
                }
            }
        }
    }
}
if ($dotable) {
    close(TAB);
}

## SUBS #######################################################################

sub wc { # Line count of a file
    my ($file) = @_;
    my $counter = 0;
    open(IN, "<", $file) or die ("$!");
    while (<IN>) {
        $counter++;
    }
    close(IN);
    return ($counter);
}

sub sum_scafstats_reads { # Sum number of unambiguously mapped reads from bbmap scafstats file
    my ($file) = @_;
    my $counter = 0;
    open(IN,"<", $file) or die ("$!");
    while (<IN>) {
        chomp;
        if ($_ !~ m/^#/) { # Ignore header line
            my @splitline = split /\s+/, $_;
            $counter += $splitline[5]; # Col6 "unambiguousReads"
        }
    }
    close(IN);
    return($counter);
}