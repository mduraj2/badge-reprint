#!/usr/bin/env perl

$project = 'badge-reprint';
$version = '-1.0';

#use strict;
use Term::ANSIColor;
#use warnings;
use v5.10; # for say() function
use Time::Piece;
use File::Basename ();
use Digest::SHA qw(sha256_hex);

$dir = File::Basename::dirname($0);

use DBI;
say "Perl MySQL Connect Database";
# MySQL database configuration
$dsn0 = "DBI:mysql:general:localhost";

$username = 'root';
$password = '';
$dbh = DBI->connect($dsn0,$username,$password, \%attr) or handle_error (DBI::errstr);

print "done";
check_version();
checkVersion($dbh);
if ($new_ver ne $latestVersion){
updateVersion($dbh);
}
print "$new_ver";

sub check_version{

	my $file = "$dir/badge-reprint.command";

	open(FH, $file) or die $!;

	while(my $string = <FH>)
	{
		if($string =~ /.version.[=]./)
		{
			print "$string";
			$len_string = (length $string) - 15;
			$new_ver = substr($string,12,$len_string);
		}	
	}
}

sub updateVersion{
	($dbh) = @_;
    $sql = "UPDATE general.versions SET version='$new_ver' WHERE name='$project'";

    $sth = $dbh->prepare($sql);
    
    # execute the query
    $sth->execute();
	
    $sth->finish;
}

sub checkVersion{
	($dbh) = @_;
    $sql = "SELECT version FROM general.versions
	WHERE name='$project'";

    $sth = $dbh->prepare($sql);
    
    # execute the query
    $sth->execute();
	
	my $ref;
    
    $ref = $sth->fetchall_arrayref([]);
    if ((0 + @{$ref}) > 0)
	{
	 foreach $data (@$ref)
            {
                ($latestVersion) = @$data;
            }
												
	} else {
		print color('bold red');
    	print "No version specified in db\n";
		print color('reset');
		print "#################################################\n";
		print "Press Enter to continue...";
		<>;
	}
	
    $sth->finish;
}

