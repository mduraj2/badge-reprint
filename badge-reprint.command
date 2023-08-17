#!/usr/bin/env perl

$project = 'badge-reprint';
$pathTo="/Users/Shared/Versions/$project/";
$fileFrom="$pathTo$project.command";

$version = '-4.1';
use File::Basename ();
use Term::ANSIColor;
use DBI;
use Digest::SHA qw(sha256_hex);

$dir = File::Basename::dirname($0);
$data = "/private/tmp/data.zpl";
$format = "$dir/formats/format_badge.zpl";

$dsn = "DBI:mysql:general:172.30.1.199";
$username = 'p3user';
$password = 'p3user';

$dbh = DBI->connect($dsn,$username,$password, \%attr) or handle_error (DBI::errstr);
checkPassword($dbh);

if (system("lpstat -a")) {
	system clear;
	sleep 2;
	print color('bold red');
	print "No printer added. Contact TE...\n";
	print color('reset');
	<>;
	exit;
}

system clear;

RESET:
checkVersion($dbh);
print "Enter password: ";
chomp ($pass = <>);
$pass = sha256_hex($pass);

if ($key ne $pass) {
	print color('bold red');
	system ("afplay '$dir/sounds/wrongansr.wav'");
	print "Incorrect password...Closing..";
	print color('reset');
	sleep 2;
	exit;
}

system(`history -c`);

USER:
system clear;
print color('bold green');
print "Printing tool$version - looking for a user\n";
print color('reset');

print "Enter first name: ";
chomp ($firstName = <>);

if (uc($firstName) eq "COMPLETE") {
	exit;
}

print "Enter last name: ";
chomp ($lastName = <>);

if ($firstName eq '' && $lastName eq '') {
	print color('bold yellow');
	print "You did not enter any value...try again...\n";
	print color('reset');
	sleep 3;
	goto USER;
}

$dbh = DBI->connect($dsn,$username,$password, \%attr) or handle_error (DBI::errstr);
loginSearch($dbh);

goto MAIN;

MAIN:

system clear;

print "#####################################\n";
print "Name: $name\nlogin: $login\n";
print "#####################################\n";
system "rm -f '$data'";

print color('bold green');
print "Printing tool$version - choosing a printer\n";
print color('reset');

@printers = `lpstat -a`;
$array_length = @printers;
# if (!$array_length) {
# 	print "test1";
# 	goto MAIN;
# }


@array = ();
$i = 0;
foreach (@printers) {
	$printer{$i}=@printers[$i];
	$spacebar = index($printer{$i}, " ");
	$printer{$i} = substr(@printers[$i],0,$spacebar);
	if (substr($printer{$i},0,1) eq "_") {
		$printer{$i} = substr($printer{$i},1,length($printer{$i}));
	}
	$printer{$i} =~ tr/_/./;

	print "Printer #$i = $printer{$i}\n";
	push @array, $i;
	$i = $i + 1;
}



print "Choose a printer or enter 'complete' to abort: ";
chomp ($choice = <>);
$choice = uc($choice);

if ($choice eq "COMPLETE") {
	goto USER;
}

if (!grep $_ eq $choice, @array) {
	print color('bold red');
	print "Wrong choice...try again\n";
	print color('reset');
	sleep 2;
	goto MAIN;
}

$i = $choice;
$printer = $printer{$i};

chomp ($num = 2);

system "lp -d '$printer' -o raw '$format'";
 
open ( $fh, '>', $data);

print $fh "^XA^XFbadge^PR3^FS^FN1^FD$name^FS^FN2^FD$login^FS^PQ$num^XZ";

close $fh;

system "lp -d '$printer' -o raw '$data'";
 
print "Label sent to printer.\n";

system ("afplay '$dir/sounds/rightansr.wav'");

sleep 2;

check_version();

goto USER;

sub checkPassword{
# query from the links table
    ($dbh) = @_;
    $sql = "SELECT encryptedpassword FROM passwords WHERE name = '$project'";
    $sth = $dbh->prepare($sql);
    
    # execute the query
    $sth->execute();
    
	my $ref;
    
    $ref = $sth->fetchall_arrayref([]);
    
	if ((0 + @{$ref}) eq 0) {
		system ("afplay '$dir/sounds/redalert.wav'");
		print color('bold red');
		print "No passwords found in db...Contact TE\n";
		print color('reset');
		exit;
	} else {
		foreach $data (@$ref)
            {
                ($key) = @$data;
            }
	}
    $sth->finish;
}

sub loginSearch{
	# query from the links table
    ($dbh) = @_;
    $sql = "SELECT * FROM oryxusers WHERE firstname LIKE '%$firstName%' AND lastname LIKE '%$lastName%'";
    $sth = $dbh->prepare($sql);
    
    # execute the query
    $sth->execute();
    
	my $ref;
    
    $ref = $sth->fetchall_arrayref([]);
    
	if ((0 + @{$ref}) eq 0) {
		system ("afplay '$dir/sounds/redalert.wav'");
		print color('bold red');
		print "No user found\n";
		print color('reset');
		sleep 3;
		goto USER;
	} elsif ((0 + @{$ref}) eq 1) {
    #print "Number of rows returned is ", 0 + @{$ref}, "\n";    
            foreach $data (@$ref)
            {
                ($first, $last, $badge) = @$data;
            }
			$name = uc("$first $last");
			$login = uc($badge);
	} else {
		$i = 1;
		foreach $data (@$ref)
            {
                ($first, $last, $badge) = @$data;
				print "$i: $first, $last, $badge\n";
				$i = $i + 1;
            }
			$first = "";
			$last = "";
			$badge = "";
			print color('bold yellow');
			print "Found more than 1 record. Try to be more specific...\n";
			print color('reset');
		<>;
		goto USER;
	}
    $sth->finish;
}

sub handle_error{
	print color('bold red');
	$time = localtime->datetime;
	system ("echo '$time\tUnable to connect to database\n' >> $logfile");
	print "Unable to connect to database. Contact your Supervisor\n";
	system ("afplay '$dir/sounds/wrongansr.wav'");
	print "Press Enter to close...\n";
	print color('reset');
	<>;
	exit;
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
												if ($version ne $latestVersion){
													downloadLatest();
													check_version();
												}
	} else {
		print color('bold red');
    	print "No version specified in db\n";
		print color('reset');
		print "#################################################\n";
		print "Press Enter to continue...";
		<>;
    	goto RESET;
	}
	
    $sth->finish;
}

sub downloadLatest{
	$passwordToCopy = 'apple';
	$userToCopy = 'apple';
	$IPAddressToCopy = '172.30.1.199';

	system `sshpass -p '$passwordToCopy' scp $userToCopy\@$IPAddressToCopy:$fileFrom $pathTo`;

}

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
			print "\nNew version: $new_ver\n";
			print "Current version: $version\n";
			print "Latest version: $latestVersion\n";
			if (($new_ver eq $version) && ($new_ver eq $latestVersion))
			{
				print "Found a match. Doing nothing...\n";
			}
			else
			{
				print "Found mismatch. Restarting...\n";
			
				system("$dir/Launch_badge_reprint.command $arg1");
				exit;
			}
		}	
	}
}
