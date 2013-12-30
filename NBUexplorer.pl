#!/usr/bin/env perl
#
# NBUexplorer -SUNWexplorer like utility for NetBackup environments
#
# Author: Andreas Lindh <andreas@superblock.se>
#

use vars qw($VERSION);

use strict qw(vars subs);
use warnings;
use Getopt::Long;
use File::Basename;
use Sys::Hostname;

# Set some global vars
my $OS = $^O;
my $HOSTNAME = hostname;
my $dumpdir = dirname(__FILE__);  # set the default directory

# FIX PATHS TO BINARIES
if ($OS eq "MSWin32") {
    if (!$ENV{'NBU_INSTALLDIR'}) {
        die "Could not find NBU_INSTALLDIR environment variable\n";
    }
    my $nbu_installdir = "$ENV{'NBU_INSTALLDIR'}";
    chomp($nbu_installdir);
    our $BPPLLISTBIN = "\"$nbu_installdir\\NetBackup\\bin\\admincmd\\bppllist\"";
    our $BPDBJOBSBIN = "\"$nbu_installdir\\NetBackup\\bin\\admincmd\\bpdbjobs\"";
} else {
    my $nbu_installdir = "/usr/openv/netbackup";
    our $BPPLLISTBIN = $nbu_installdir."/bin/admincmd/bppllist";
    our $BPDBJOBSBIN = $nbu_installdir."/bin/admincmd/bpdbjobs";
}


my %opt;
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

sub mk_timestamp
{
    return time;
}
