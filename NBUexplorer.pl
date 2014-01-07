#!/usr/bin/env perl
#
# NBUexplorer - SUNWexplo like utility for NetBackup environments
#
# This script should be executed with sudo permissions or as root so that
# the necessary commands can be run successfully.
#
# Author: Andreas Lindh <andreas@superblock.se>
#

use vars qw($VERSION);

use strict qw(vars subs);
use warnings;
use Getopt::Long;
use File::Basename;
use File::Path qw(rmtree);
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
my $BPGETCONFIGBIN;
my $BPERRORBIN;
my $BPCLLISTBIN;
my $BPIMMEDIABIN;
my $BPSTULISTBIN;
my $BPPSBIN;
my $BPCLIMAGELISTBIN;
my $VMQUERYBIN;
my $VMPOOLBIN;
my $VMRULEBIN;
my $TPCLEANBIN;
my $CRCONTROLBIN;
if ($OS eq "MSWin32") {
    if (!$ENV{'NBU_INSTALLDIR'}) {
        die "Could not find NBU_INSTALLDIR environment variable\n";
    }
    my $nbu_installdir = "$ENV{'NBU_INSTALLDIR'}";
    chomp($nbu_installdir);
    $nbu_installdir =~ s/^(.*?)\\$/$1/g;  # Remove trailing backslashes

    $BPPLLISTBIN                = "$nbu_installdir\\NetBackup\\bin\\admincmd\\bppllist.exe";
    $BPDBJOBSBIN                = "$nbu_installdir\\NetBackup\\bin\\admincmd\\bpdbjobs.exe";
    $AVAILABLEMEDIABIN          = "$nbu_installdir\\NetBackup\\bin\\goodies\\available_media.exe";
    $GETLICENSEKEYBIN           = "$nbu_installdir\\NetBackup\\bin\\admincmd\\get_license_key.exe";
    $BPCONFIGBIN                = "$nbu_installdir\\NetBackup\\bin\\admincmd\\bpconfig.exe";
    $BPSYNCINFOBIN              = "$nbu_installdir\\NetBackup\\bin\\admincmd\\bpsyncinfo.exe";
    $BPMEDIALISTBIN             = "$nbu_installdir\\NetBackup\\bin\admincmd\\bpmedialist.exe";
    $BPIMAGELISTBIN             = "$nbu_installdir\\NetBackup\\bin\\admincmd\\bpimagelist.exe";
    $BPGETCONFIGBIN             = "$nbu_installdir\\NetBackup\\bin\\admincmd\\bpgetconfig.exe";
    $BPERRORBIN                 = "$nbu_installdir\\NetBackup\\bin\\admincmd\\bperror.exe";
    $BPCLLISTBIN                = "$nbu_installdir\\NetBackup\\bin\\admincmd\\bpcllist.exe";
    $BPIMMEDIABIN               = "$nbu_installdir\\NetBackup\\bin\\admincmd\\bpimmedia.exe";
    $BPSTULISTBIN               = "$nbu_installdir\\NetBackup\\bin\\admincmd\\bpstulist.exe";
    $BPPSBIN                    = "$nbu_installdir\\NetBackup\\bin\\bpps.exe";
    $BPCLIMAGELISTBIN           = "$nbu_installdir\\NetBackup\\bin\\bpclimagelist.exe";
    $VMQUERYBIN                 = "$nbu_installdir\\Volmgr\\bin\\vmquery.exe";
    $VMPOOLBIN                  = "$nbu_installdir\\Volmgr\\bin\\vmpool.exe";
    $VMRULEBIN                  = "$nbu_installdir\\Volmgr\\bin\\vmrule.exe";
    $TPCLEANBIN                 = "$nbu_installdir\\Volmgr\\bin\\tpclean.exe";
    $CRCONTROLBIN               = "$nbu_installdir\\pdde\\pdcr\\bin\\crcontrol.exe";
} elsif (($OS =~ /darwin/) or ($OS eq "linux")) {
    my $nbu_installdir = "/usr/openv/netbackup";
    $BPPLLISTBIN                = $nbu_installdir."/bin/admincmd/bppllist";
    $BPDBJOBSBIN                = $nbu_installdir."/bin/admincmd/bpdbjobs";
    $AVAILABLEMEDIABIN          = $nbu_installdir."/bin/goodies/available_media";
    $GETLICENSEKEYBIN           = $nbu_installdir."/bin/admincmd/get_license_key";
    $BPCONFIGBIN                = $nbu_installdir."/bin/admincmd/bpconfig";
    $BPSYNCINFOBIN              = $nbu_installdir."/bin/admincmd/bpsyncinfo";
    $BPMEDIALISTBIN             = $nbu_installdir."/bin/admincmd/bpmedialist";
    $BPIMAGELISTBIN             = $nbu_installdir."/bin/admincmd/bpimagelist";
    $BPGETCONFIGBIN             = $nbu_installdir."/bin/admincmd/bpgetconfig";
    $BPERRORBIN                 = $nbu_installdir."/bin/admincmd/bperror";
    $BPCLLISTBIN                = $nbu_installdir."/bin/admincmd/bpcllist";
    $BPIMMEDIABIN               = $nbu_installdir."/bin/admincmd/bpimmedia";
    $BPSTULISTBIN               = $nbu_installdir."/bin/admincmd/bpstulist";
    $BPPSBIN                    = $nbu_installdir."/bin/bpps";
    $BPCLIMAGELISTBIN           = $nbu_installdir."/bin/bpclimagelist";
    $VMQUERYBIN                 = "/usr/openv/volmgr/bin/vmquery";
    $VMPOOLBIN                  = "/usr/openv/volmgr/bin/vmpool";
    $VMRULEBIN                  = "/usr/openv/volmgr/bin/vmrule";
    $TPCLEANBIN                 = "/usr/openv/volmgr/bin/tpclean";
    $CRCONTROLBIN               = "/usr/openv/pdde/pdcr/bin/crcontrol";
}
my %commands = (
    "bpdbjobs_report_allcolumns"        => ["$BPDBJOBSBIN", "-report -all_columns"],
    "bppllist_allpolicies_U"            => ["$BPPLLISTBIN", "-allpolicies -U"],
    "bppllist_allpolicies"              => ["$BPPLLISTBIN", "-allpolicies"],
    "available_media"                   => ["$AVAILABLEMEDIABIN", ""],
    "get_license_key_features"          => ["$GETLICENSEKEYBIN", "-L features"],
    "get_license_key_keys"              => ["$GETLICENSEKEYBIN", "-L keys"],
    "bpconfig_U"                        => ["$BPCONFIGBIN", "-U"],
    "bpmedialist_mlist"                 => ["$BPMEDIALISTBIN", "-mlist"],
    "bpmedialist_summary"               => ["$BPMEDIALISTBIN", "-summary"],
    "bpmedialist_summary_brief"         => ["$BPMEDIALISTBIN", "-summary -brief"],
    "bpimagelist_A_d_fromepoch"         => ["$BPIMAGELISTBIN", "-A -d 01/30/00 00:00:00"],
    "bpimagelist_A_media_d_fromepoch"   => ["$BPIMAGELISTBIN", "-A -media -d 01/30/00 00:00:00"],
    "bpgetconfig"                       => ["$BPGETCONFIGBIN", ""],
    "bperror_all_d_fromepoch"           => ["$BPERRORBIN", "-all -d 01/30/00 00:00:00"],
    "bperror_media_d_fromepoch"         => ["$BPERRORBIN", "-media -d 01/30/00 00:00:00"],
    "bpcllist_allclasses_U"             => ["$BPCLLISTBIN", "-allclasses -U"],
    "bpimmedia_U"                       => ["$BPIMMEDIABIN", "-U"],
    "bpimmedia"                         => ["$BPIMMEDIABIN", ""],
    "bpstulist_U"                       => ["$BPSTULISTBIN", "-U"],
    "bpstulist_l"                       => ["$BPSTULISTBIN", "-l"],
    "bpps_a"                            => ["$BPPSBIN", "-a"],
    "bpclimagelist"                     => ["$BPCLIMAGELISTBIN", ""],
    "vmquery_a"                         => ["$VMQUERYBIN", "-a"],
    "vmquery_a_bx"                      => ["$VMQUERYBIN", "-a -bx"],
    "vmquery -a -w"                     => ["$VMQUERYBIN", "-a -w"],
    "vmpool_listall"                    => ["$VMPOOLBIN", "-listall"],
    "vmrule_listall"                    => ["$VMRULEBIN", "-listall"],
    "tpclean_L"                         => ["$TPCLEANBIN", "-L"],
    "crcontrol_getmode"                 => ["$CRCONTROLBIN", "--getmode"],
    "crcontrol_dsstat"                  => ["$CRCONTROLBIN", "--dsstat"],
    "crcontrol_processqueueinfo"        => ["$CRCONTROLBIN", "--processqueueinfo"],
    "crcontrol_queueinfo"               => ["$CRCONTROLBIN", "--queueinfo"],
);


my %opt;
my $help;
my $deleteold;
my $getoptresult = GetOptions(\%opt,
    "help|h|?"          => \$help,
    "dir|d=s"           => \$dumpdir,
    "delold=s"        => \$deleteold,
);

sub output_usage {
    my $usage = qq{
Usage: $0 [options]

Options:
    -h/? | --help       : Get help

    -d | --dir          : Directory to dump to. Uses current directory if none
                        specified.
    --delold <hours>    : Remove directories found in topdir older than hours.

};
    die $usage;
}

output_usage() if (not $getoptresult);
output_usage() if ($help);


sub mk_dumpdir {
    # Return formatted timestamp
    my $dir = "$dumpdir/$HOSTNAME"."_dump_".$dumptime;
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
    return "$HOSTNAME.$filebasename.$dumptime.out.$ending";
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


sub find_olddirs {
    # First argument passed to this function should be unixtime
    my $delbefore = $_[0];
    my @directories_to_del;
    opendir(DIR, $dumpdir) or die "Could not open $dumpdir: $!\n";
    while (my $d = readdir(DIR)) {
        if (-d $d) {
            if ($d =~ m/.*\_.*\_([0-9]+)$/) {
                my $t = $1;
                if ($t < $delbefore) {
                    print "Found directory to remove: $d (time $t)\n";
                    push(@directories_to_del, $d);
                }
            }
       }
    }
    return @directories_to_del;
}


sub main {
    # Main logic
    my @files;
    my $dir = mk_dumpdir();
    for my $command (keys %commands) {
        my $binary = "$commands{$command}[0]";

        my $longcmd = "$commands{$command}[0] $commands{$command}[1]";
        my $filename = mk_zipped_filename($command);

        if (-e $binary) {
            print "Binary $binary exists, executing [$longcmd] and dumping to $dir/$filename .. \n";
            dump_to_zip($longcmd, "$dir/$filename");
            push(@files, $filename);  # Insert generated file path into @files
        }
    }
    if ($deleteold) {
        my $olddate = time() - ($deleteold * 60 * 60);
        print "Trying to delete directories created before: ".localtime($olddate)."\n";
        my @directories_to_del = find_olddirs($olddate);
        foreach my $d (@directories_to_del) {
            print "Removing directory $d\n";
            rmtree($d) or warn "Could not remove $d: $!\n";
        }
    }
}

main()
