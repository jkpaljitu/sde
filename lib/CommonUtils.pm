#!/usr/bin/perl -w
################################################################################
# Script Name  	: CommonUtils.pm
# Version      	: 1.0.0
# Created date 	: 11-Aug-2014
# Created by    : Jitendra Pal (jpal)
# Description   : Modules with all common functionality used to develop scripts
################################################################################
# Modification History-1
# Version       : 
# Modify Date   : 
# Modified By   : 
# Description   : 
################################################################################
# Package/Class name
package CommonUtils;

# Modules used
use strict;

################################################################################
# Subroutine   	: new
# Purpose       : Constructor with initialized value for commonly used variables
# Parameters   	: class name by default
# Return Value 	: Returns an object blessed with the same class
################################################################################
sub new {
  my $class = shift;
  my $platform = "unix";
  $platform = $ENV{OS} if (defined $ENV{OS});
  my $user = "undef";
  $user = $ENV{P4USER} if (defined $ENV{P4USER});
  $user = $ENV{USERNAME} if ($platform eq "Windows_NT");
  my $slash = "\/";
  $slash = "\\" if ($platform eq "Windows_NT");
  my $self = {
    # Exit codes
    PASSCODE => 0,
    FAILCODE => 1,
    LINUX_CMD_ID => "/usr/bin/id",
    LINUX_CMD_DF => "/bin/df",
    LINUX_CMD_MKDIR => "/bin/mkdir",
    LINUX_CMD_ECHO => "/bin/echo",
    # repository
    REPOSITORY => "//depot/margot",
    # OS platforms
    WINDOWS => "Windows_NT",
    UNIX => "unix",
    # For making compatible to both Windows and Unix
    OS => $platform,
    # User who is executing the script
    USER => $user,
    # Slash as per type of OS
    SLASH => $slash,
    # LDAP SEARCH
    LDAP_SEARCH => "/usr/bin/ldapsearch -xb \'ou=active,ou=employees,ou=people,o=arubanetworks.com\' -h ldap.arubanetworks.com uid=", 
    # Misclenious
    CONTACT => "jkpal2@rediffmail.com",
  };
  bless $self, $class;
  return $self;
}
 
################################################################################
# Subroutine   	: DESTROY
# Purpose       : Destructor
# Parameters   	: void
# Return Value 	: void
################################################################################
sub DESTROY {
  return;
}

################################################################################
# Subroutine   	: sPromptUser
# Purpose       : Get the user input during the runtime
# Parameters   	: 0. object 1. String to prompt 2. Default value
# Return Value 	: Return the STDIN input value 
################################################################################
sub sPromptUser {
  shift;
  my ($promptStr, $defaultVal) = @_;
  if ($defaultVal) {
    print $promptStr, "[", $defaultVal, "]: ";
  } 
  else {
    print $promptStr, ": ";
  }
  $| = 1;               # After print force a flush
  $_ = <STDIN>;         # input from STDIN
  chomp;
  if ("$defaultVal") {
    return $_ ? $_ : $defaultVal;
  } 
  else {
    return $_;
  }
}

################################################################################
# Subroutine   	: sGetOpts
# Purpose       : Sets the argument passed to the script
# Parameters   	: 1. Hash reference 2. list of options
# Return Value 	: Returns either 0 (passcode) or 1 (failcode)
################################################################################
sub sGetOpts {
  my ($object, $hOptions, @arguments) = @_;
  my %passedArgs;
  my @opts = keys (%$hOptions);
  my (@temp, @args);
  my ($cmdOpt, $passed, $isOpt, $set, $unknown, $i, $isVal);
  if ($#opts == -1) {
    print "\nERROR: sGetOpts(): no argument passed!\n";
    return $object->{FAILCODE};
  }
  $isOpt = 0;
  $isVal = 0;
  foreach $i (@ARGV) {
    if ($i =~ /^-(.+)$/) {
      if ($isOpt) {
        $passedArgs{$passed} = "single_option";
        $isOpt = 1;
      }
      else {
        $isOpt++;
        $isVal = 0;
      }
      $passed = $1;
    }
    else {
      unless ($isOpt) {
        print "\nERROR: sGetOpts(): \"$i\" option format is wrong!\n";
        return $object->{FAILCODE};
      }
      else {
        $passedArgs{$passed} = $i;
        $isVal++;
        $isOpt = 0;
      }
    }
  }
  if ($isOpt) {
    $passedArgs{$passed} = "single_option";
  }
  foreach $passed (keys(%passedArgs)) {
    my @unknowns;
    $unknown = 0;
    foreach $set (@arguments) {
      @args = split /=/,$set;
      if ($args[0] =~ /^$passed/) {
        if (grep $args[0], @opts) {
          if ($args[1]) {
            if ($passedArgs{$passed} eq "single_option") {
              print "\nERROR: sGetOpts(): option \"\-".$args[0]."\" needs a value!\n";
              return $object->{FAILCODE};
            }
            $$hOptions{$args[0]} = $passedArgs{$passed};
          }
          else {
            if ($passedArgs{$passed} ne "single_option") {
              print "\nERROR: sGetOpts(): option \"\-".$args[0]."\" doesn't need a value!\n";
              return $object->{FAILCODE};
            }
            $$hOptions{$args[0]} = 1;
          }
        }
        else {
          print "\nERROR: sGetOpts(): \"\-$passed\" option not defined!\n";
          return $object->{FAILCODE};
        }
        $unknown++;
      }
    }
    unless ($unknown) {
      print "\nERROR: sGetOpts(): \"\-$passed\" is an invalid option!\n";
      return $object->{FAILCODE};
    }
  }
  return $object->{PASSCODE};
}

################################################################################
# Subroutine   	: sGetSite
# Purpose       : To get current site name
# Parameters   	: No arguments passed
# Return Value 	: site name as string
################################################################################
sub sGetSite {
  my ($object) = @_;
  my ($timeZone, $siteName);
  if ($object->{OS} eq $object->{WINDOWS}) {
    $timeZone = `systeminfo | find "Time Zone" 2>&1`;
    chomp ($timeZone);
    if ($timeZone =~ /GMT+05:30/) {
      $siteName = $object->{SITE_BLR1};
    }
    else {
      $siteName = $object->{SITE_SVL1};
    }
  }
  else {
    $timeZone = `date '+%Z'`;
    chomp ($timeZone);
    if ($timeZone =~ /IST/) {
      $siteName = $object->{SITE_BLR1};
    }
    else {
      $siteName = $object->{SITE_SVL1};
    }
    }
  return $siteName;
}

################################################################################
# Subroutine   	: sGetDefaultLogPath
# Purpose       : To get the default log path
# Parameters   	: No Parameter passed
# Return Value 	: Returns the log path as string (empty string incase of error)
################################################################################
sub sGetDefaultLogPath {
  my ($object) = @_;
  my $logPath;
  if ($object->{OS} eq $object->{WINDOWS}) {
    # To check whether USERPROFILE environment variable exists
    if (defined "$ENV{USERPROFILE}") {
      $logPath = $ENV{USERPROFILE};
    }
  }
  else {
    if (defined $ENV{USER}) {
      $logPath = $object->{SLASH}."tmp";
    }
  }
  return $logPath;
}

################################################################################
# Subroutine   	: sFileOpenErr
# Purpose       : To print the file opening error message and return fail code
# Parameters   	: 1. The file name 2. actual error message
# Return Value 	: Returns the fail code (1)
################################################################################
sub sFileOpenErr {
        my ($object, $fileName, $actErrMsg) = @_;
        print "\nError: The file $fileName can't be opened. ".$actErrMsg."\n";
        return $object->{FAILCODE};
}

################################################################################
# Subroutine   	: sFileCloseErr
# Purpose       : To print the file closing error message and return fail code
# Parameters   	: 1. The file name 2. actual error message
# Return Value 	: Returns the fail code (1)
################################################################################
sub sFileCloseErr {
        my ($object, $fileName, $actErrMsg) = @_;
        print "\nERROR: The file $fileName can't be closed. ".$actErrMsg."\n";
        return $object->{FAILCODE};
}

################################################################################
# Subroutine   	: sSend
# Purpose       : send mail
# Parameters   	: from, to, subject and message
# Return Value 	: error message or empty string in case of successful
################################################################################
sub sSend {
  require Mail::Sendmail;
  shift;
  my ($from, $to, $subject, $msg) = @_;
  sendmail(
    From	=> $from,
    To		=> $to,
    Subject	=> $subject,
    Message	=> $msg,
  ) || return "Error sending mail: $Mail::Sendmail::error";
  return "";
}

################################################################################
# Subroutine   	: sGetNextDate
# Purpose       : Generates the next date to the passed date
# Parameters   	: Date whose next date has to be found out
# Return Value 	: Returns the next date as string format (yyyy-mm-dd)
################################################################################
sub sGetNextDate {
  my ($object, $date) = @_;
  my ($year, $month, $day, $nextDate, $isLeapYear);
  my ($nextYear, $nextMonth, $nextDay);
  my %months = ("01" => "31",
                "02" => "28",
                "03" => "31",
                "04" => "30",
                "05" => "31",
                "06" => "30",
                "07" => "31",
                "08" => "31",
                "09" => "30",
                "10" => "31",
                "11" => "30",
                "12" => "31",
               );
  if ($date =~ /^(\d\d\d\d)-(\d\d)-(\d\d)$/) {
    $year = $1;
    $month = $2;
    $day = $3;
  }
  else {
    print "\nERROR: Invalid date format passed to sGetNextDate\(\)!\n";
    return $object->{FAILCODE};
  }
  if ($month eq "02") {
    if ($object->sLeapYearCheck($year)) {
      $months{"02"} = "29";
    }
  }
  if ($day eq $months{$month}) {
    $nextDay = "01";
    unless ($month eq "12") {
      $nextMonth = $month+1;
      $nextMonth = "0".$nextMonth if ($nextMonth =~ /^\d$/);
      $nextYear = $year;
    }
    else {
      $nextMonth = "01";
      $nextYear = $year+1;
    }
  }
  else {
    $nextDay = $day+1;
    $nextDay = "0".$nextDay if ($nextDay =~ /^\d$/);
    $nextMonth = $month;
    $nextYear = $year;
  }
  $nextDate = $nextYear."-".$nextMonth."-".$nextDay;
  return $nextDate;
}
################################################################################
# Subroutine   	: sGetPrevDate
# Purpose       : Generates the previous date to the passed date
# Parameters   	: Date whose previous date has to be found out
# Return Value 	: Returns the previous date as string format (yyyy-mm-dd)
################################################################################
sub sGetPrevDate {
  my ($object, $date) = @_;
  my ($year, $month, $day, $prevDate, $isLeapYear);
  my ($prevYear, $prevMonth, $prevDay);
  my %months = ("01" => "31",
                "02" => "28",
                "03" => "31",
                "04" => "30",
                "05" => "31",
                "06" => "30",
                "07" => "31",
                "08" => "31",
                "09" => "30",
                "10" => "31",
                "11" => "30",
                "12" => "31",
               );
  if ($date =~ /^(\d\d\d\d)-(\d\d)-(\d\d)$/) {
    $year = $1;
    $month = $2;
    $day = $3;
  }
  else {
    print "\nERROR: Invalid date format passed to sGetPrevDate\(\)!\n";
    return $object->{FAILCODE};
  }
  if ($month eq "02") {
    if ($object->sLeapYearCheck($year)) {
      $months{"02"} = "29";
    }
  }
  if ($day eq "01") {
    if ($month eq "01") {
      $prevMonth = "12";
      $prevYear = $year-1;
    }
    else {
      $prevMonth = $month-1;
      $prevYear = $year;
    }
    $prevDay = $months{$month};
  }
  else {
    $prevDay = $day-1;
    $prevMonth = $month;
    $prevYear = $year;
  }
  $prevDay = "0".$prevDay if ($prevDay =~ /^\d$/);
  $prevMonth = "0".$prevMonth if ($prevMonth =~ /^\d$/);

  $prevDate = $prevYear."-".$prevMonth."-".$prevDay;
  return $prevDate;
}

################################################################################
# Subroutine   	: sLeapYearCheck
# Purpose       : Checks whether the year passed as argument is a leap year
# Parameters   	: year which has to be checked for leap year
# Return Value 	: Returns 1 if yes else 0
################################################################################
sub sLeapYearCheck {
  shift;
  my ($year) = @_;
  my $leapYear = 0; # Not a leap year
  if ((($year % 4 == 0)&&($year % 100 != 0))||
      (($year % 4 == 0)&&($year % 100 == 0)&&($year % 400 == 0))) {
    $leapYear = 1; # Is a leap year
  }
  return $leapYear;    
}

################################################################################
# Subroutine   	: sGetDateTime
# Purpose       : Get the current date and time as the format <yyyy-mm-dd hh:mm:ss>
# Parameters   	: 1. The string "date" or ""time" or "datetime" or "timestamp"
# Return Value 	: 1. Date or time or datetime as string (ex-2007-07-25 11:36:54)
################################################################################
sub sGetDateTime {
  shift;
  my ($dateOrTime) = @_;
  my ($date, $time);
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
  # As the year will be offset to 1900 we need to add 1900
  $year += 1900;
  # As the month starts from 0
  $mon++;
  # As the month up to Sept. it is single digit 
  $mon = "0".$mon if ($mon =~ /^\d$/);
  # As the day up to 9th it is single digit
  $mday = "0".$mday if ($mday =~ /^\d$/); 
  $date = $year."-".$mon."-".$mday;
  $hour = "0".$hour if ($hour =~ /^\d$/);
  $min = "0".$min if ($min =~ /^\d$/);
  $sec = "0".$sec if ($sec =~ /^\d$/);
  $time = $hour.":".$min.":".$sec;
  return $date if ($dateOrTime eq "date");
  return $time if ($dateOrTime eq "time");
  return $date." ".$time if ($dateOrTime eq "datetime");
  return $date.":".$time if ($dateOrTime eq "timestamp");
}

################################################################################
# Subroutine    : sEpochToDatetime
# Purpose       : convert epoch to <yyyy-mm-dd:hh:mm:ss>
# Parameters    : epoch
# Return Value  : date-time string (ex: 2007-07-25:11.36.54)
################################################################################
sub sEpochToDatetime {
  shift;
  my ($epoch) = @_;
  my ($year, $month, $mday, $hour, $minute, $second);
  my ($wday, $yday, $isdst);
  ($second,$minute,$hour,$mday,$month,$year,$wday,$yday,$isdst) = localtime($epoch);
  $year += 1900;
  $month += 1;
  return ("$year-$month-$mday $hour:$minute:$second");
}

################################################################################
# Subroutine   	: sIsValidUserID
# Purpose       : Check whether the user id exist 
# Parameters   	: 1. Object 2. user id
# Return Value 	: Returns 1 if the user id exists else returns 0 
################################################################################
sub sIsValidUserID {
  my ($object, $uid) = @_;
  my $output = `$object->{LINUX_CMD_ID} $uid 2>&1`;
  return 0 if ($output =~ /: No such user/);
  return 1;
}

################################################################################
# Subroutine   	: sIsValidBugID
# Purpose       : Check whether the bugid exist is a valid one
#                 (new and sync are considered as valid bugids)
# Parameters   	: 1. Object 2. bugid
# Return Value 	: Returns 1 if the bugid is valid else returns 0 
################################################################################
sub sIsValidBugID {
  shift;
  my ($bugid) = @_;
  if ($bugid =~ /^new$/ || $bugid =~ /^sync$/) {
    return 1;     # valid
  }
  else {
    my ($bug);# = <run bug tracking tool CLI/API to check>;
    chomp($bug);
    return 1 if ($bug eq $bugid);   # valid
  }
  return 0;       # not a valid bug id
}

################################################################################
# Subroutine   	: sIsValidEmailAlias
# Purpose       : Check whether the email alias (userid or mailer) exists
# Parameters   	: 1. Object 2. email alias
# Return Value 	: Returns 1 if the alias exists else returns 0 
################################################################################
sub sIsValidEmailAlias {
  my ($object, $alias) = @_;
  #return 0 if (`$object->{LINUX_ALIAS_EXPAND} $alias 2>&1` =~ /unknown alias/);
  #return 1;
}

################################################################################
# Subroutine   	: sAvailableSpace
# Purpose       : Check the storage space availability
# Parameters   	: 1. Object 2. email alias
# Return Value 	: Returns percentage (%) of space available, else
#                 returns 101 in case of any error 
################################################################################
sub sAvailableSpace {
  my ($object, $storage) = @_;
  my $cmd = $object->{LINUX_CMD_DF}." -h $storage";
  my $output = `$cmd`;
  if($output =~ /(\d+)\%\s+$storage/) {
    return 100-$1;
  }
  print "CommonUtils::sAvailableSpace: ERROR: could not found the available space! Error from command, \"$cmd\":\n";
  print "\t$output\n";
  return 101;
}

################################################################################
# Subroutine   	: aUnique
# Purpose       : Find unique elements from the 2 arrays passed
# Parameters   	: 1. Object 2. 1st array reference 2. 2nd array reference
# Return Value 	: Returns an array with unique elements 
################################################################################
sub aUnique {
  shift;  # object is not required
  my ($first, $second) = @_;
  my @result;
  foreach (@$first) {
    push (@result, $_) unless (grep(/$_/, @result));
  }
  return @result;
}

################################################################################
# Subroutine    : aMinus
# Purpose       : Find elements in 1st list that are not in 2nd list
# Parameters    : 1. Object 2. 1st array reference 2. 2nd array reference
# Return Value  : Returns an array with required elements       
################################################################################
sub aMinus {
  shift;  # object is not required
  my ($first, $second) = @_;
  my @result;
  foreach (@$first) {
    push (@result, $_) unless (grep(/$_/, @$second));
  }
  return @result;
}

################################################################################
# Subroutine    : sHost
# Purpose       : Find name or ip of the host where the script is running
# Parameters    : 1. Object 2. "name" or "ip"
# Return Value  : Returns either name of ip upon success else failcode(1)       
################################################################################
sub sHost {
  my ($object, $type) = @_;
  my ($cmd, $host);
  if ($type eq "name") {
    $cmd = "/bin/hostname";
  }
  elsif ($type eq "ip") {
    $cmd = "/sbin/ifconfig eth0 | grep \'inet addr:\' | cut -d: -f2 | awk \'{ print \$1}\'";
  }
  else {
    print "CommonUtils::sHost:ERROR: the argument can either \"name\" or \"ip\"!\n";
    return $object->{FAILCODE};
  }
  $host = `$cmd 2>&1`;
  chomp($host);
  return $host;
}  

################################################################################
# EOF
1;
