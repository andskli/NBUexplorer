#!/usr/bin/env perl
#
# NBUexplorer - SUNWexplorer like utility for NetBackup environments
#
# Author: Andreas Lindh <andreas@superblock.se>
#

use vars qw($VERSION);

use strict qw(vars subs);
use warnings;
use Getopt::Long;
use File::Basename;
use Sys::Hostname;
use Data::Dumper;
use IO::Zlib;


# Set some global vars
my $OS = $^O;
my $HOSTNAME = hostname;
my $dumpdir = dirname(__FILE__);  # set the default directory
my $dumptime = time;

# FIX PATHS TO BINARIES AND SETUP COMMANDS
my $BPDBJOBSBIN;
my $BPPLLISTBIN;
my $AVAILABLEMEDIABIN;
my $GETLICENSEKEYBIN;
my $BPCONFIGBIN;
my $BPSYNCINFOBIN;
my $BPMEDIALISTBIN;
my $BPIMAGELISTBIN;
if ($OS eq "MSWin32") {
    if (!$ENV{'NBU_INSTALLDIR'}) {
        die "Could not find NBU_INSTALLDIR environment variable\n";
    }
    my $nbu_installdir = "$ENV{'NBU_INSTALLDIR'}";
    chomp($nbu_installdir);
    $BPPLLISTBIN = "\"$nbu_installdir\\NetBackup\\bin\\admincmd\\bppllist\"";
    $BPDBJOBSBIN = "\"$nbu_installdir\\NetBackup\\bin\\admincmd\\bpdbjobs\"";
    $AVAILABLEMEDIABIN = "\"$nbu_installdir\\NetBackup\\bin\\goodies\\available_media\"";
    $GETLICENSEKEYBIN = "\"$nbu_installdir\\NetBackup\\bin\\admincmd\\get_license_key\"";
    $BPCONFIGBIN = "\"$nbu_installdir\\NetBackup\\bin\\admincmd\\bpconfig\"";
    $BPSYNCINFOBIN = "\"$nbu_installdir\\NetBackup\\bin\\admincmd\\bpsyncinfo\"";
    $BPMEDIALISTBIN = "\"$nbu_installdir\\NetBackup\\bin\admincmd\\bpmedialist\"";
    $BPIMAGELISTBIN = "\"$nbu_installdir\\NetBackup\\bin\\admincmd\\bpimagelist\"";
} elsif (($OS =~ /darwin/) or ($OS eq "linux")) {
    my $nbu_installdir = "/usr/openv/netbackup";
    $BPPLLISTBIN = $nbu_installdir."/bin/admincmd/bppllist";
    $BPDBJOBSBIN = $nbu_installdir."/bin/admincmd/bpdbjobs";
    $AVAILABLEMEDIABIN = $nbu_installdir."/bin/goodies/available_media";
    $GETLICENSEKEYBIN = $nbu_installdir."/bin/admincmd/get_license_key";
    $BPCONFIGBIN = $nbu_installdir."/bin/admincmd/bpconfig";
    $BPSYNCINFOBIN = $nbu_installdir."/bin/admincmd/bpsyncinfo";
    $BPMEDIALISTBIN = $nbu_installdir."/bin/admincmd/bpmedialist";
    $BPIMAGELISTBIN = $nbu_installdir."/bin/admincmd/bpimagelist";
}
my %commands = (
    "bpdbjobs_report_allcolumns"        => ["$BPDBJOBSBIN", "-report -all_columns"],
    "bppllist_allpolicies_U"            => ["$BPPLLISTBIN", "-allpolicies -U"],
    "available_media"                   => ["$AVAILABLEMEDIABIN", ""],
    "get_license_key_features"          => ["$GETLICENSEKEYBIN", "-L features"],
    "get_license_key_keys"              => ["$GETLICENSEKEYBIN", "-L keys"],
    "bpconfig_U"                        => ["$BPCONFIGBIN", "-U"],
    "bpmedialist_U_mlist"               => ["$BPMEDIALISTBIN", "-U -mlist"],
    "bpmedialist_summary"               => ["$BPMEDIALISTBIN", "-summary"],
    "bpemdialist_summary_brief"         => ["$BPMEDIALISTBIN", "-summary -brief"],
    "bpimagelist_A_d_fromepoch"         => ["$BPIMAGELISTBIN", "-A -d 01/30/00 00:00:00"],
    "bpimagelist_A_media_d_fromepoch"   => ["$BPIMAGELISTBIN", "-A -media -d 01/30/00 00:00:00"],
);


my %opt;
my $help;
my $getoptresult = GetOptions(\%opt,
    "help|h|?" => \$help,
    "dir|d=s" => \$dumpdir,
);

sub output_usage {
    my $usage = qq{
Usage: $0 [options]

Options:
    -h/? | --help       : Get help

    -d | --dir          : Directory to dump to. Uses current directory if none
                        specified.

};
    die $usage;
}

output_usage() if (not $getoptresult);
output_usage() if ($help);


sub mk_dumpdir {
    # Return formatted timestamp
    my $dir = "$dumpdir/dump_$dumptime";
    mkdir $dir unless (-d $dir);
    return "$dir";
}


sub mk_zipped_filename {
    # Return formatted filename
    my $filebasename = $_[0];
    my $ending;
    if ($OS eq "MSWin32") {
        $ending = "zip";
    } elsif (($OS =~ /darwin/) or ($OS eq "linux")) {
        $ending = "gz";
    }
    return "$filebasename.$dumptime.out.$ending";
}

sub dump_to_zip {
    # Execute command and dump to zip
    # First argument is command, second is outputfile
    my $fh = IO::Zlib->new("$_[1]", "wb");
    if (defined $fh) {
        print $fh qx($_[0]);
    }
    $fh->close;
    return $_[1];
}

sub main {
    # Main logic
    my @files;
    my $dir = mk_dumpdir();
    for my $command (keys %commands) {
        my $binary = "$commands{$command}[0]";

        my $longcmd = "$commands{$command}[0] $commands{$command}[1]";
        print "Longcmd: $longcmd\n";
        my $filename = mk_zipped_filename($command);

        print "Evaulating if [$longcmd] is to be run..\n";

        if (-e $binary) {
            print "Binary $binary exists, executing [$longcmd] and dumping to $dir/$filename .. \n";
            dump_to_zip($longcmd, "$dir/$filename");
            push(@files, $filename);  # Insert generated file path into @files
        }
    }
}

main()
