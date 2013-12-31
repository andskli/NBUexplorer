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

# FIX PATHS TO BINARIES
my $BPDBJOBSBIN;
my $BPPLLISTBIN;
if ($OS eq "MSWin32") {
    if (!$ENV{'NBU_INSTALLDIR'}) {
        die "Could not find NBU_INSTALLDIR environment variable\n";
    }
    my $nbu_installdir = "$ENV{'NBU_INSTALLDIR'}";
    chomp($nbu_installdir);
    $BPPLLISTBIN = "\"$nbu_installdir\\NetBackup\\bin\\admincmd\\bppllist\"";
    $BPDBJOBSBIN = "\"$nbu_installdir\\NetBackup\\bin\\admincmd\\bpdbjobs\"";
} elsif (($OS =~ /darwin/) or ($OS eq "linux")) {
    my $nbu_installdir = "/usr/openv/netbackup";
    $BPPLLISTBIN = $nbu_installdir."/bin/admincmd/bppllist";
    $BPDBJOBSBIN = $nbu_installdir."/bin/admincmd/bpdbjobs";
}
my %commands = (
    "bpdbjobs"      => ["$BPDBJOBSBIN", "-report -all_columns"],
    "bppllist"      => ["$BPPLLISTBIN", ""],
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
    my $command_input = $_[0];
    $command_input = basename($command_input);
    $command_input =~ s/\ /\_/ig;
    $command_input =~ s/\./\_/ig;
    my $ending;
    if ($OS eq "MSWin32") {
        $ending = "zip";
    } elsif (($OS =~ /darwin/) or ($OS eq "linux")) {
        $ending = "gz";
    }
    return "$command_input.$dumptime.out.$ending";
}

sub dump_to_zip {
    # Execute command and dump to zip
}

sub main {
    # Main logic
    my @files;
    my $dir = mk_dumpdir();
    my $binary;
    my $longcmd;
    my $filename;

    foreach my $command (keys %commands) {
        my $binary = "$commands{$command}[0]";

        my $longcmd = "@{$commands{$command}}";

        my $filename = mk_zipped_filename($longcmd);

        if (-e $binary) {
            print "Binary $binary exists, executing and dumping to $dir/$filename .. \n";
            my $fh = IO::Zlib->new("$dir/$filename", "wb");
            if (defined $fh) {
                print $fh qx($longcmd);
            }
            $fh->close;
            push(@files, $filename);  # Insert generated file path into @files
        }
    }
}

main()
