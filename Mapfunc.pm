package Mapfunc;

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION = 1.00;
@ISA = qw (Exporter);
@EXPORT = qw(hashTSV_KV hashTSV_KKV doSystem previewCmd);
@EXPORT_OK = qw ();
%EXPORT_TAGS = (DEFAULT => [qw(hashTSV_KV hashTSV_KKV doSystem previewCmd)]);

## SUBS #######################################################################


# Open TSV file, split cols by tab, hash with indicated columns as keys
sub hashTSV { 
    my ($file, $keyCol, $valCol) = @_;
    my %hash;
    open(IN, "<", $file) or die ("File $file not found: $!");
    while (<IN>) {
        chomp;
        my @splitline = split "\t";
        $hash{$splitline[$keyCol]} = $splitline[$valCol];
    }
    close(IN);
    return (\%hash);
}

# Open TSV file, split cols by tab, and hash with col1 as key and col2 as val
sub hashTSV_KV {
    my ($file) = @_;
    my %hash;
    open(IN, "<", $file) or die ("File $file not found: $!");
    while (<IN>) {
        chomp;
        my @splitline = split "\t";
        $hash{$splitline[0]} = $splitline[1];
    }
    close(IN);
    return (\%hash);
}

# Open TSV file, split cols by tab, and hash with col1 as key1, col2 as key2, and col3 as val
sub hashTSV_KKV {
    my ($file) = @_;
    my %hash;
    open(IN, "<", $file) or die ("File $file not found: $!");
    while (<IN>) {
        chomp;
        my @splitline = split "\t";
        $hash{$splitline[0]}{$splitline[1]} = $splitline[2];
    }
    close(IN);
    return (\%hash);
}

# Join array of executable name and arguments and run with system, return system exit value
sub doSystem {
    my @cmd = @_;
    my $cmd_join = join " ", @cmd;
    my $returnval = system ("$cmd_join");
    return $returnval;
}

# Join array of executable name and arguments and print to STDOUT (for previewing command)
sub previewCmd {
    my @cmd = @_;
    my $cmd_join = join " ", @cmd;
    print $cmd_join."\n";
}