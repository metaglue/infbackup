#!/usr/bin/perl

###########################################################################
# $Id: infbackup,v10.1.1 - Build 1359 - 17.03.2018 16:10:20 Claus Bohm Exp $
#
# USAGE:
#
#	 actions:
#		 [-h  ] Display this help message and stop
#		 [-v  ] Display version of this script.
#		 [-un ] Domain / Repository User | or overwrite environment variable INFA_DEFAULT_DOMAIN_USER
#		 [-rp ] Domain / Repository Password | or overwrite environment variable INFA_DEFAULT_DOMAIN_PASSWORD
#		 [-dp ] Domain Database Password | or overwrite environment variable INFA_DEFAULT_DATABASE_PASSWORD
#
###########################################################################
# This script will back up the domain and all repositories on the
# current host.
# 
# To do this, it reads the nodemeta.xml file to get all the information
# it needs.
#
# A backup of the domain and the repositories will only performed if the 
# corresponding services are also active.
#
###########################################################################
# infbackup is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# infbackup is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with infbackup; see the file COPYING.	If not, write to the
# Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
###########################################################################

###################################################################################################
###		Required modules and program options
###################################################################################################

use strict;
use warnings;
use XML::Parser;
use POSIX qw(strftime);
use File::Basename;

###################################################################################################
###		Start INITIALIZATION
###################################################################################################

# Global Script Variables
our $VERSION										= "10.1.1";
our $BUILD											= "Build 1359";
our $DATE												= "17.03.2018 16:10:20";
our $RELEASE										= "production";
our $SCRIPT											= basename $0;

my $DryRun = 1;
my $DateFileFormat = "%Y%m%d%H%M%S";
my $FileDate = strftime ( $DateFileFormat, localtime );
my $DateFormat = "%Y-%m-%d %H:%M:%S";
my $BackupDate = strftime ( $DateFormat, localtime );

my ($arg1, $arg2, $arg3, $arg4, $arg5, $arg6 ) = @ARGV;
my $maxarg = $#ARGV +1;

my ($domainName, $nodeName, $host, $httpPort, $dbHost, $dbName, $dbConnectString, $dbPort, $dbType, $dbUsername, $repUsername);
my ($repservice, $repservicestatus, $mrsservice, $mrsservicestatus, $dombackupfile, $repbackupfile, $mrsbackupfile);
my ($infbackupdir, $dombackupdir, $mrsbackupdir);
my ($connectlog, $disconnectlog, $dombackuplog, $repbackuplog, $mrsbackuplog);
my ($CHILD_ERROR, $domrtc, $connectrtc, $disconnectrtc);
my ($unused, $rpused, $dpused);
my ($databasepassword, $username, $password);
my ($infacmd, $pmrep, $pmpasswd, $infabackup);
my ($mkbackupdir, $mkdomdir, $mkmrsdir);

my $dombackuprtc = 0;
my $repbackuprtc = 0;
my $mrsbackuprtc = 0;

my $ldlibpath = $ENV{'LD_LIBRARY_PATH'};
my $infahome = $ENV{'INFA_HOME'};
my $dbPassword = $ENV{'INFA_DEFAULT_DATABASE_PASSWORD'};
my $domUsername = $ENV{'INFA_DEFAULT_DOMAIN_USER'};
my $domPassword = $ENV{'INFA_DEFAULT_DOMAIN_PASSWORD'};
my $infalibpath = $infahome . '/server/bin';
my $filename = $infahome . '/isp/config/nodemeta.xml';
my %paths;
my $cmdmsg = '';

my @repservice = ();
my @mrsservice = ();
my @repservicestatus = ();
my @mrsservicestatus = ();

print "\nCopyright (c) 1993-2018 metaglue it-consulting. All Rights Reserved.\n";

###################################################################################################
###		get commandline args and interpret arguments
###################################################################################################
if ( $maxarg > 6 ) {
	$cmdmsg = "To many commandline options.";
	display_help();
}
if (( defined $arg1 ) && ( $arg1 eq '-h' )) {
	display_help();
}

if (( defined $arg1 ) && ( $arg1 eq '-v' )) {
	display_version();
}

if (( defined $arg1 ) && ( defined $arg2 ) && ( $arg1 eq '-un' )) {
	if ( not defined $unused ) {
		$unused = "un";
		$username = $arg2;
	}
	else {
		$cmdmsg = "Commandline Option has already been used: $arg1";
		display_help();
	}
}
elsif (( defined $arg1 ) && ( defined $arg2 ) && ( $arg1 eq '-rp' )) {
	if ( not defined $rpused ) {
		$rpused = "rp";
		$password = $arg2;
	}
	else {
		$cmdmsg = "Commandline Option has already been used: $arg1";
		display_help();
	}
}
elsif (( defined $arg1 ) && ( defined $arg2 ) && ( $arg1 eq '-dp' )) {
	if ( not defined $dpused ) {
		$dpused = "dp";
		$databasepassword = $arg2;
	}
	else {
		$cmdmsg = "Commandline Option has already been used: $arg1";
		display_help();
	}
}
elsif (( defined $arg1 ) && ( defined $arg2 ) && (( $arg1 ne '-un' ) || ( $arg1 ne '-rp' ) || ( $arg1 ne '-dp' ))) {
	$cmdmsg = "Wrong commandline option $arg1";
	display_help();
}

if (( defined $arg3 ) && ( defined $arg4 ) && ( $arg3 eq '-un' )) {
	if ( not defined $unused ) {
		$unused = "un";
		$username = $arg4;
	}
	else {
		$cmdmsg = "Commandline Option has already been used: $arg3";
		display_help();
	}
}
elsif (( defined $arg3 ) && ( defined $arg4 ) && ( $arg3 eq '-rp' )) {
	if ( not defined $rpused ) {
		$rpused = "rp";
		$password = $arg4;
	}
	else {
		$cmdmsg = "Commandline Option has already been used: $arg3";
		display_help();
	}
}
elsif (( defined $arg3 ) && ( defined $arg4 ) && ( $arg3 eq '-dp' )) {
	if ( not defined $dpused ) {
		$dpused = "dp";
		$databasepassword = $arg4;
	}
	else {
		$cmdmsg = "Commandline Option has already been used: $arg3";
		display_help();
	}
}
elsif (( defined $arg3 ) && ( defined $arg4 ) && (( $arg3 ne '-un' ) || ( $arg3 ne '-rp' ) || ( $arg3 ne '-dp' ))) {
	$cmdmsg = "Wrong commandline option $arg3";
	display_help();
}

if (( defined $arg5 ) && ( defined $arg6 ) && ( $arg5 eq '-un' )) {
	if ( not defined $unused ) {
	$unused = "un";
	$username = $arg6;
	}
	else {
		$cmdmsg = "Commandline Option has already been used: $arg5";
		display_help();
	}
}
elsif (( defined $arg5 ) && ( defined $arg6 ) && ( $arg5 eq '-rp' )) {
	if ( not defined $rpused ) {
		$rpused = "rp";
		$password = $arg6;
	}
	else {
		$cmdmsg = "Commandline Option has already been used: $arg5";
		display_help();
	}
}
elsif (( defined $arg5 ) && ( defined $arg6 ) && ( $arg5 eq '-dp' )) {
	if ( not defined $dpused ) {
		$dpused = "dp";
		$databasepassword = $arg6;
	}
	else {
		$cmdmsg = "Commandline Option has already been used: $arg5";
		display_help();
	}
}
elsif (( defined $arg5 ) && ( defined $arg6 ) && (( $arg5 ne '-un' ) || ( $arg5 ne '-rp' ) || ( $arg5 ne '-dp' ))) {
	$cmdmsg = "Wrong commandline option $arg5";
	display_help();
}

### Start working
print "Starting Script: $SCRIPT v $VERSION at $BackupDate\n\n";

### Check if environment is set correctly
if (not defined $ldlibpath) {
	$ENV{'LD_LIBRARY_PATH'} = $infalibpath;
}
else {
	if (index($ldlibpath, $infalibpath) == -1) {
		$ENV{'LD_LIBRARY_PATH'} = $ldlibpath . ':' . $infalibpath;
	}
}
if (not defined $infahome) {
	die "Environment for Informatica is not set. Please set the environment variable INFA_HOME\n";
}
else {
	$infacmd = $infahome . '/server/bin/infacmd.sh';
	$pmrep = $infahome . '/server/bin/pmrep';
	$pmpasswd = $infahome . '/server/bin/pmpasswd';
	$infabackup = $infahome . '/isp/bin/infasetup.sh backupDomain';
}

###################################################################################################
###		get User and Passwords from Environment or commandline
###################################################################################################
if ((not defined $username) && (not defined $domUsername)) {
  $cmdmsg = "Need Username or set the environment variable INFA_DEFAULT_DOMAIN_USER\n";
}

if ((defined $username) && (not defined $domUsername)) {
	$ENV{'INFA_DEFAULT_DOMAIN_USER'} = $username;
};

$repUsername = $ENV{'INFA_DEFAULT_DOMAIN_USER'};

if ((not defined $password) && (not defined $domPassword)) {
	$cmdmsg = "Need Password or set the environment variable INFA_DEFAULT_DOMAIN_PASSWORD\n";
}

if ((defined $password) && (not defined $domPassword)) {
	chomp($domPassword = `$pmpasswd $password | grep Encrypted | sed 's/-->//g' | sed 's/<--//g' | cut -d' ' -f3`);
	$ENV{'INFA_DEFAULT_DOMAIN_PASSWORD'} = $domPassword;
}

if ((not defined $databasepassword) && (not defined $dbPassword)) {
	$cmdmsg = "Need DataBase Password or set the environment variable INFA_DEFAULT_DATABASE_PASSWORD\n";
}

if ((defined $databasepassword) && (not defined $dbPassword)) {
	chomp($dbPassword = `$pmpasswd $password | grep Encrypted | sed 's/-->//g' | sed 's/<--//g' | cut -d' ' -f3`);
	$ENV{'INFA_DEFAULT_DATABASE_PASSWORD'} = $dbPassword;
}

###################################################################################################
###		get Informatica Domain information from nodemeta.xml via XLM::Parser
###################################################################################################
unless ( -f $filename ) {
	die "File $filename not found";
}

print "Get needed information for the backup:\n";
my $parser = XML::Parser->new( Handlers => {
	Start=>\&handle_start,
});
$parser->parsefile( $filename );

sub handle_start {
	my( $expat, $element, %attrs ) = @_;

	# ask the expat object about our position
	my $line = $expat->current_line;

	if( %attrs ) {
		while( my( $key, $value ) = each( %attrs )) {
			if(( $element eq "domainservice:GatewayNodeConfig" ) && ( $key eq "domainName" )) {
				$domainName = $value;
				print "\tDomain Name :\t$domainName\n";
			}
			if(( $element eq "domainservice:GatewayNodeConfig" ) && ( $key eq "nodeName" )) {
				$nodeName = $value;
				print "\tNode Name ..:\t$nodeName\n";
			}
			if(( $element eq "address" ) && ( $key eq "host" )) {
				$host = $value;
				print "\tGateway Host:\t$host\n";
			}
			if(( $element eq "address" ) && ( $key eq "httpPort" )) {
				$httpPort = $value;
				print "\tGateway Port:\t$httpPort\n";
			}
			if(( $element eq "domainservice:DBConnectivity" ) && ( $key eq "dbHost" )) {
				$dbHost = $value;
				print "\tDB Host ....:\t$dbHost\n";
			}
			
			if(( $element eq "domainservice:DBConnectivity" ) && ( $key eq "dbConnectString" )) {
				# in xml special characters are stored as ascii hex. therefore, a conversion takes place
				$dbConnectString = $value;
				$dbConnectString =~ s/\%2F/\//g;
				$dbConnectString =~ s/\%3B/\;/g;
				$dbConnectString =~ s/\%3D/\=/g;
				print "\tDB Connect .:\t$dbConnectString\n";
			}
			if(( $element eq "domainservice:DBConnectivity" ) && ( $key eq "dbName" )) {
				$dbName = $value;
				print "\tDB Name ....:\t$dbName\n";
			}
			if(( $element eq "domainservice:DBConnectivity" ) && ( $key eq "dbPort" )) {
				$dbPort = $value;
				print "\tDB Port ....:\t$dbPort\n";
			}
			if(( $element eq "domainservice:DBConnectivity" ) && ( $key eq "dbType" )) {
				$dbType = lc($value);
				print "\tDB Type ....:\t$dbType\n";
			}
			if(( $element eq "domainservice:DBConnectivity" ) && ( $key eq "dbUsername" )) {
				$dbUsername = $value;
				print "\tDB User ....:\t$dbUsername\n";
			}
		}
	}
	return ($domainName, $nodeName, $host, $httpPort, $dbHost, $dbName, $dbConnectString, $dbPort, $dbType, $dbUsername);
}

###################################################################################################
###		Backup can only done when Informatica Domain is up an running
###################################################################################################
print "\nCheck if the domain is available...";
my $domping = `$infacmd ping -DomainName $domainName`;
die "something went horribly wrong" if $CHILD_ERROR;
if ( $? == -1 ) {
	print "\ninfacmd.sh ping failed to execute: $!\n";
	print "$domping";
}
elsif ( $? & 127 ) {
	printf "\ninfacmd.sh ping died with signal %d, %s a coredump\n",
	( $? & 127 ), ( $? & 128 ) ? 'with' : 'without';
}
else {
	$domrtc = $?;
	if ( $domrtc != 0 ) {
		printf "\ninfacmd.sh ping exited with value %d\n", $? >> 8;
		print "$domping";
	} else {
		print " Domain $domainName was successfully pinged.\n\n";
	}
}

###################################################################################################
###		Look for repository services and get current status
###################################################################################################
if ( $domrtc == 0 ) {
	print "Get enabled services to backup.\n";
	chomp(@repservice = `$infacmd listServices -dn $domainName -hp $host:$httpPort -st RS | grep -v 'Command ran successfully'`);
	die "something went horribly wrong" if $CHILD_ERROR;
	if ( scalar @repservice == 0 ) {
		$?=0;
	}
	for my $i ( 0 .. $#repservice ) {
		my $currep = $i + 1;
		my $repserviceelement = $repservice[$i];
		chomp($repservicestatus = `$infacmd getServiceStatus -dn $domainName -hp $host:$httpPort -sn $repserviceelement | grep -v 'Command ran successfully'`);
		die "something went horribly wrong" if $CHILD_ERROR;
		push(@repservicestatus,$repservicestatus);
		print"\tRepository $repservice[$i] has status $repservicestatus[$i].\n";
	}

	chomp(@mrsservice = `$infacmd listServices -dn $domainName -hp $host:$httpPort -st MRS | grep -v 'Command ran successfully'`);
	die "something went horribly wrong" if $CHILD_ERROR;
	if ( scalar @mrsservice == 0 ) {
		$?=0;
	}
	for my $i ( 0 .. $#mrsservice ) {
		my $curmrs = $i + 1;
		my $mrsserviceelement = $mrsservice[$i];
		chomp($mrsservicestatus = `$infacmd getServiceStatus -dn $domainName -hp $host:$httpPort -sn $mrsserviceelement | grep -v 'Command ran successfully'`);
		die "something went horribly wrong" if $CHILD_ERROR;
		push(@mrsservicestatus,$mrsservicestatus);
		print"\tModel Repository $mrsservice[$i] has status $mrsservicestatus[$i].\n";
	}

###################################################################################################
###		Look for backup directory from Informatica node
###################################################################################################
	print "Get the current backup directory\n";
	chomp($infbackupdir = `$infacmd listNodeOptions -dn $domainName -nn $nodeName | grep BackupDir | sed 's/ //g' | cut -d'=' -f2`);
	die "something went horribly wrong" if $CHILD_ERROR;
	
###################################################################################################
###		Check if backup directories exist - if not, create
###################################################################################################
	print "\t$infbackupdir\n";
	$dombackupdir = $infbackupdir . '/' . $domainName;
	if ( -d $infbackupdir) {
		# Check for domain backup directory
		if ( !-d $dombackupdir) {
			print"\tCreate Domain backup direcktoy ", $dombackupdir, "...";
			$mkdomdir = `mkdir -p $dombackupdir`;
			die "something went horribly wrong" if $CHILD_ERROR;
			if ( $? == -1 ) {
				print "\nmkdir -p $dombackupdir failed to execute: $!\n";
				print "$mkdomdir";
			}
			elsif ( $? & 127 ) {
				printf "\nmkdir -p $dombackupdir died with signal %d, %s a coredump\n",
				( $? & 127 ), ( $? & 128 ) ? 'with' : 'without';
			}
			else {
				$dombackuprtc = $?;
				if ( $dombackuprtc != 0 ) {
					printf "\nmkdir -p $dombackupdir exited with value %d\n", $? >> 8;
					print "$mkdomdir";
				} else {
					print " done!\n";
				}
			}
		}
		# Check for every Model Repository service
		if ( scalar @mrsservice > 0 ) {
			for my $i ( 0 .. $#mrsservice ) {
				my $curmrs = $i + 1;
				my $mrsserviceelement = $mrsservice[$i];
				$mrsbackupdir = $infbackupdir . '/' . $mrsservice[$i];
				if ( !-d $mrsbackupdir) {
					print"\tCreate Model Repository backup direcktoy ", $mrsbackupdir, "...";
					$mkmrsdir = `mkdir -p $mrsbackupdir`;
					die "something went horribly wrong" if $CHILD_ERROR;
					if ( $? == -1 ) {
						print "\nmkdir -p $mrsbackupdir failed to execute: $!\n";
						print "$mkmrsdir";
					}
					elsif ( $? & 127 ) {
						printf "\nmkdir -p $mrsbackupdir died with signal %d, %s a coredump\n",
						( $? & 127 ), ( $? & 128 ) ? 'with' : 'without';
					}
					else {
						$dombackuprtc = $?;
						if ( $dombackuprtc != 0 ) {
							printf "\nmkdir -p $mrsbackupdir exited with value %d\n", $? >> 8;
							print "$mkmrsdir";
						} else {
							print " done!\n";
						}
					}
				}
			}
		}
	}
	# try to create the root backup directory and all domain and model repository directories
	else {
		print"Current backup directory does not exists!\n";
		print"\tCreate domain backup direcktoy ", $infbackupdir, "...";
		$mkbackupdir = `mkdir -p $infbackupdir`;
		die "something went horribly wrong" if $CHILD_ERROR;
		if ( $? == -1 ) {
			print "\nmkdir -p $infbackupdir failed to execute: $!\n";
			print "$mkbackupdir";
		}
		elsif ( $? & 127 ) {
			printf "\nmkdir -p $infbackupdir died with signal %d, %s a coredump\n",
			( $? & 127 ), ( $? & 128 ) ? 'with' : 'without';
		}
		else {
			$dombackuprtc = $?;
			if ( $dombackuprtc != 0 ) {
				printf "\nmkdir -p $infbackupdir exited with value %d\n", $? >> 8;
				print "$mkbackupdir";
			} else {
				print " done!\n";
			}
		}
		if ( -d $infbackupdir) {
			if ( !-d $dombackupdir) {
				print"\tCreate Domain backup direcktoy ", $dombackupdir, "...";
				$mkdomdir = `mkdir -p $dombackupdir`;
				die "something went horribly wrong" if $CHILD_ERROR;
				if ( $? == -1 ) {
					print "\nmkdir -p $dombackupdir failed to execute: $!\n";
					print "$mkdomdir";
				}
				elsif ( $? & 127 ) {
					printf "\nmkdir -p $dombackupdir died with signal %d, %s a coredump\n",
					( $? & 127 ), ( $? & 128 ) ? 'with' : 'without';
				}
				else {
					$dombackuprtc = $?;
					if ( $dombackuprtc != 0 ) {
						printf "\nmkdir -p $dombackupdir exited with value %d\n", $? >> 8;
						print "$mkdomdir";
					} else {
						print " done!\n";
					}
				}
			}
			# Check for every Model Repository service
			if ( scalar @mrsservice > 0 ) {
				for my $i ( 0 .. $#mrsservice ) {
					my $curmrs = $i + 1;
					my $mrsserviceelement = $mrsservice[$i];
					$mrsbackupdir = $infbackupdir . '/' . $mrsservice[$i];
					if ( !-d $mrsbackupdir) {
						print"\tCreate Model Repository backup direcktoy ", $mrsbackupdir, "...";
						$mkmrsdir = `mkdir -p $mrsbackupdir`;
						die "something went horribly wrong" if $CHILD_ERROR;
						if ( $? == -1 ) {
							print "\nmkdir -p $mrsbackupdir failed to execute: $!\n";
							print "$mkmrsdir";
						}
						elsif ( $? & 127 ) {
							printf "\nmkdir -p $mrsbackupdir died with signal %d, %s a coredump\n",
							( $? & 127 ), ( $? & 128 ) ? 'with' : 'without';
						}
						else {
							$dombackuprtc = $?;
							if ( $dombackuprtc != 0 ) {
								printf "\nmkdir -p $mrsbackupdir exited with value %d\n", $? >> 8;
								print "$mkmrsdir";
							} else {
								print " done!\n";
							}
						}
					}
				}
			}
		}
	}

###################################################################################################
###		Backup Informatica Domain
###################################################################################################
	print "\nStarting backup process...\n";
	print "\tBackup Domain \t\t\t$domainName...";
	$dombackupfile = $dombackupdir . '/' . $domainName . '_' . $FileDate . '.mrep';
	if ( $DryRun == 0 ) {
		if (defined $dbHost) {
			$dombackuplog = `$infabackup -da $dbHost:$dbPort -ds $dbName -dt $dbType -du $dbUsername -bf $dombackupfile -dn $domainName`;
			die "something went horribly wrong" if $CHILD_ERROR;
		}
		if (defined $dbConnectString) {
			$dombackuplog = `$infabackup -cs '$dbConnectString' -dt $dbType -du $dbUsername -bf $dombackupfile -dn $domainName`;
			die "something went horribly wrong" if $CHILD_ERROR;
		}
	}

	if ( $? == -1 ) {
		print "\ninfasetup.sh backupDomain failed to execute: $!\n";
		print "$dombackuplog";
	}
	elsif ( $? & 127 ) {
		printf "\ninfasetup.sh backupDomain died with signal %d, %s a coredump\n",
		( $? & 127 ), ( $? & 128 ) ? 'with' : 'without';
	}
	else {
		$dombackuprtc = $?;
		if ( $dombackuprtc != 0 ) {
			printf "\ninfasetup.sh backupDomain exited with value %d\n", $? >> 8;
			print "$dombackuplog";
		} else {
			print " done!\n";
		}
	}

###################################################################################################
###		Backup every enabled Informatica Repository
###################################################################################################
	for my $i ( 0 .. $#repservice ) {
		my $currep = $i + 1;
		my $repservice = $repservice[$i];
		my $repservicestatus = $repservicestatus[$i];

		if ( $repservicestatus eq 'Enabled') {
			# Connect to Repository Service
			print "\tConnecting to Repository \t$repservice...";
			$connectlog = `$pmrep connect -d $domainName -r $repservice -n $repUsername -X INFA_DEFAULT_DOMAIN_PASSWORD`;
			die "something went horribly wrong" if $CHILD_ERROR;
			if ( $? == -1 ) {
				print "\npmrep connect failed to execute: $!\n";
				print "$connectlog";
			}
			elsif ( $? & 127 ) {
				printf "\npmrep connect died with signal %d, %s a coredump\n",
				( $? & 127 ), ( $? & 128 ) ? 'with' : 'without';
			}
			else {
				$connectrtc = $?;
				if ( $connectrtc != 0 ) {
					printf "\npmrep connect exited with value %d\n", $? >> 8;
					print "$connectlog";
				}
				else {
					print " done!\n";
				}
			}
			# Backup Repository Service
			print "\tBackup Repository \t\t$repservice...";
			$repbackupfile = $infbackupdir . '/' . $repservice . '_' . $FileDate . '.rep';
			if ( $DryRun == 0 ) {
				$repbackuplog = `$pmrep backup -o $repbackupfile -d 'Backup done with metaglue BackupScript at $BackupDate'`;
				die "something went horribly wrong" if $CHILD_ERROR;
			}
			if ( $? == -1 ) {
				print "\npmrep backup failed to execute: $!\n";
				print "$repbackuplog";
			}
			elsif ( $? & 127 ) {
				printf "\npmrep backup died with signal %d, %s a coredump\n",
				( $? & 127 ), ( $? & 128 ) ? 'with' : 'without';
			}
			else {
				$repbackuprtc = $?;
				if ( $repbackuprtc != 0 ) {
					printf "\npmrep backup exited with value %d\n", $? >> 8;
					print "$repbackuplog";
				}
				else {
					print " done!\n";
				}
			}
			# disconnecting from Repository Service
			print "\tDisconnecting from Repository \t$repservice...";
			$disconnectlog = `$pmrep cleanup`;
			die "something went horribly wrong" if $CHILD_ERROR;
			if ( $? == -1 ) {
				print "\npmrep cleanup failed to execute: $!\n";
				print "$disconnectlog";
			}
			elsif ( $? & 127 ) {
				printf "\npmrep cleanup died with signal %d, %s a coredump\n",
				( $? & 127 ), ( $? & 128 ) ? 'with' : 'without';
			}
			else {
				$disconnectrtc = $?;
				if ( $disconnectrtc != 0 ) {
					printf "\npmrep cleanup exited with value %d\n", $? >> 8;
					print "$disconnectlog";
				} else {
					print " done!\n";
				}
			}
		}
		else {
			print "Backup of the RepositoryService $repservice skipped. Status is $repservicestatus.";
		}
	}

###################################################################################################
###		Backup every enabled Informatica Model Repository
###################################################################################################
	for my $i ( 0 .. $#mrsservice ) {
		my $curmrs = $i + 1;
		my $mrsservice = $mrsservice[$i];
		my $mrsservicestatus = $mrsservicestatus[$i];
		if ( $mrsservicestatus eq 'Enabled') {
			print "\tBackup Model Repository \t$mrsservice...";
			$mrsbackupfile = $infbackupdir . '/' . $mrsservice . '/' . $mrsservice . '_' . $FileDate . '.mrep';
			if ( $DryRun == 0 ) {
				$mrsbackuplog = `$infacmd mrs BackupContents -dn $domainName -sn $mrsservice -of $mrsbackupfile -ds 'Backup done with metaglue BackupScript at $BackupDate'`;
				die "something went horribly wrong" if $CHILD_ERROR;
			}
			if ( $? == -1 ) {
				print "\ninfacmd.sh mrs BackupContents failed to execute: $!\n";
				print "$mrsbackuplog";
			}
			elsif ( $? & 127 ) {
				printf "\ninfacmd.sh mrs BackupContents died with signal %d, %s a coredump\n",
				( $? & 127 ), ( $? & 128 ) ? 'with' : 'without';
			}
			else {
				$mrsbackuprtc = $?;
				if ( $mrsbackuprtc != 0 ) {
					printf "\ninfacmd.sh mrs BackupContents exited with value %d\n", $? >> 8;
					print "$repbackuplog";
				}
				else {
					print " done!\n";
				}
			}
		}
		else {
			print "Backup of the ModelRepositoryService $mrsservice skipped. Status is $mrsservicestatus.";
		}
	}

###################################################################################################
###		Check process status
###################################################################################################
	my $FinishedDate = strftime ( $DateFormat, localtime );
	if (( $mrsbackuprtc == 0 ) && ( $repbackuprtc == 0 ) && ( $dombackuprtc == 0 )) {
		print "\nBackup process ended succeeded at $FinishedDate.\n";
		exit(0);
	}
	else {
		print "\nBackup process FAILED at $FinishedDate.\n";
		exit(1);
	}
}

sub display_help {
	print "$cmdmsg\n";
	print "usage: $SCRIPT [actions]\n";
	print "\n";
	print "	If you start this program without arguments, the following environment variables must be set:\n";
	print "		INFA_DEFAULT_DOMAIN_USER\n";
	print "		INFA_DEFAULT_DOMAIN_PASSWORD\n";
	print "		INFA_DEFAULT_DATABASE_PASSWORD\n";
	print "\n";
	print "	possible actions are:\n";
	print "	[-h  ]	display this help message and stop.\n";
	print "	[-v  ]	Display version of this program and stop.\n";
	print "	[-un ]	Domain / Repository User | or overwrite environment variable INFA_DEFAULT_DOMAIN_USER.\n";
	print "	[-rp ]	Domain / Repository Password | or overwrite environment variable INFA_DEFAULT_DOMAIN_PASSWORD.\n";
	print "	[-dp ]	Domain Database Password | or overwrite environment variable INFA_DEFAULT_DATABASE_PASSWORD.\n";
	print "\n";
	print "\n";
	exit(0);
};

sub display_version {
	print "\n";
	print "$SCRIPT - $RELEASE v$VERSION - $BUILD	 $DATE\n\n";
	exit(0);
};
