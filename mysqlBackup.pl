#!/usr/bin/perl
# MySQL Server Backup
# ----------------------------------------------------------------------------
# This perl library will connect to the mysql server as defined in the users
# .my.cnf file. If this file does not exist, the program will exit. Once
# connected to the MySQL server, it will generate a list of databases, and 
# run the mysqldump command on each storing the output in a .sql format to be
# compressed later.
#
# Additional features (yet to be added) include emailing or transfer the
# compressed file to another source other then the current machine. Also
# exploring other options then mysqldump which can lock tables and cause the
# server to appear down to the end user.
#
# Why am I doing this? Want to learn perl! Depending on how ballzy I am, may 
# update this to for use strict;
#
#
#
# @author	Adam Brenner <aebrenne@uci.edu>
# @version	1.0
#
#
# DON'T BE A DICK PUBLIC LICENSE
#
#                           Version 2, December 2011
#
# Copyright (C) 2009 Philip Sturgeon <email@philsturgeon.co.uk>
# Re-modified by helloadam <ha@netops.me> Copyright (C) 2011
#
# Everyone is permitted to copy and distribute verbatim or modified copies of 
# this license document, and changing it is allowed as long as the name is 
# changed.
#
#                        DON'T BE A DICK PUBLIC LICENSE
#       TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#
# 1. Do whatever you like with the original work, just don't be a dick. Being 
#    a dick includes - but is not limited to - the following instances:
#
#     1a. Outright copyright infringement - Don't just copy this and change 
#         the name.
#     1b. Selling the unmodified - original copy - with no work done what so 
#         ever, that's REALLY being a dick.
#     1c. Modifying the original work to contain hidden harmful content. That 
#         would make you a PROPER dick.
#
# 2. If you become rich through modifications, related works/services, or 
#    supporting the original work, share the love. Only a dick would make 
#    loads off this work and not buy the original works creator(s) a drink, 
#    or offer some sort of financial donation.
#
# 3  Don't be a dick and redistribute of this very source code without giving
#    credit to the original authors. To avoid being such dick, retain the 
#    above copyright notice and this very license. 
#
# 4. Code is provided with no warranty. Using somebody else's code and 
#    bitching when it goes wrong makes you a DONKEY dick. Fix the problem 
#    yourself. A non-dick would submit the fix back.

use File::Which;

# Configurations
##############################################################################
my $mysql      = which('mysql');      # Path to MySQL
my $mysqldump  = which ('mysqldump'); # Path to MySQL Dump
my $backupDest = "/backup";           # Backup path (a folder)
my $workingDir = $backupDest."/tmp";  # Working directory for tmp files
my $pathToCNF  = "/root/.my.cnf";     # Path to .my.cnf file - containts user
                                      # and password for mysql host (if exists)

# If the .my.cnf file exists and has any of these option, we will favor the 
# .my.cnf file over any settings listed here. To disable checking for .my.cnf
# simple leave $pathToCNF blank with double quotes "";
my $hostname  = "localhost";          # MySQL host
my $mysqlUser = "";                   # Will be read from .my.cnf (if exists)
my $mysqlPass = "";                   # Will be read from .my.cnf (if exists)

# Functions
##############################################################################
sub say {
	print $_[0]."\n";
}

my ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);
my $time  = sprintf("%0.2d:%0.2d:%0.2d",$hour,$min,$sec);
my $date  = sprintf("%0.4d.%0.2d.%0.2d",$year+1900,++$mon,$mday);
my $timestamp = "$date.$time";


# Routes and URI's
##############################################################################
## -e is file
## -d if folder

if(!defined($mysql) && !-e $mysql) {
	say "Could not find path to MySQL";
	exit;
}
if(!defined($mysqldump) && !-e $mysqldump) {
	say "Could not find path to MySQL Dump";
	exit;
}
if(!-d $backupDest) {
	say "Could not find our backup path";
	exit;
}
if(!-d $workingDir) {
	unless(mkdir $workingDir) {
		die "Unable to create tmp working directory in $backupDest";
	}
}

## Reads CNF file for username and password for MySQL server
if(defined($pathToCNF) && -e $pathToCNF) {

	open (pathToCNF,"<$pathToCNF") || 
		die "Can't read CNF file, but it is present on system";
	while (<pathToCNF>) {
		# skip lines that start with # in them (comments)...irony!
		(/^\s*[#|;]/ && next) || chomp;
		my ($key,$val) = split(/\s*=\s*/);
		if ($key eq 'user') { 
			$mysqlUser = $val; 
		}
		if ($key eq 'password' || $key eq 'pass') { 
			$mysqlPass = $val; 
		}
		if ($key eq 'host') { 
			$hostname = $val; 
		}
	}
}

my $databases = "$mysql -u $mysqlUser -h $hostname -p$mysqlPass -Bse 'show databases'";

system $databases;
