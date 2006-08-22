#!/usr/bin/perl
# Batch chain log parser for GraphTalk AIA
# Written by Georgi D. Sotirov <gsotirov@obs.bg>
# Date: 2006-08-22
#
# This script will output the main information about the batches
# in CSV (Comma Separated Values) format.
#
# To use it make sure the file is executable at least to its owner:
# $ chmod u+x logparse.pl
# And then run it with at one argument - path to the log file
# $ ./logparse.pl my_log_file
#

(@ARGV == 1) or die "Usage: $0 <log file>\n";
  
$logfile = $ARGV[0];

sub reformat_date {
  $_[0] =~ s/([0-9]{2})([0-9]{2})([0-9]{4})/$1\/$2\/$3/;
  return $_[0];
}

open(LOGFILE, $logfile) or die "Error: Can not open file '$logfile': $!\n";

my $number = 0;
my %table;

# Put data in a hash since it can be spred in the file
while ( <LOGFILE> ) {
  my @VALS = split(/\s+/, $_);
  (scalar(@VALS) > 1) or next;
  my $batch = $VALS[1];

  if ( ! $table{$batch}{'order'} ) {
    $table{$batch}{'order'} = ++$number;
  }

  if ( $VALS[2] eq "debute" ) {
    $table{$batch}{'start_date'} = reformat_date($VALS[4]);
    $table{$batch}{'start_time'} = $VALS[6];
  }
  elsif ( $VALS[2] eq 'termine' ) {
    $table{$batch}{'end_date'} = reformat_date($VALS[4]);
    $table{$batch}{'end_time'} = $VALS[6];
  }
  elsif ( $VALS[2] =~ /[Rr]etour:?/ || $VALS[3] =~ /[Rr]etour:?/ ) {
    $table{$batch}{'return'} = $VALS[4];
  }
  elsif ( $VALS[2] eq 'NBERR' ) {
    my $i = 3;
    my $err = 0;
    while ( $VALS[$i] =~ /[0-9]+/ ) {
      if ( $VALS[$i] ) {
        $err += $VALS[$i];
      }
      ++$i;
    }
    $table{$batch}{'errors'} = $err;
  }
  elsif ( $VALS[2] =~ 'NBIT' ) {
    my $i = 3;
    my $step = 0;
    while ( $VALS[$i] =~ /[0-9]+/ ) {
      if ( $VALS[$i] ) {
        $step += $VALS[$i];
      }
      ++$i;
    }
    $table{$batch}{'steps'} = $step;
  }
}

close(LOGFILE) or warn "Warning: Closing of file '$logfile' failed: $!\n";

# Find data order
my @order;
foreach $key (keys %table) {
  $order[$table{$key}{'order'}] = $key;
}

# Print gathered information
print "Batch;Start date;Start time;End date;End time;Return code;Steps;Errors\n";
for (my $i = 1; $i < scalar(@order); ++$i ) {
  printf "%s;%s;%s;%s;%s;%d;%d;%d\n", $order[$i],
                                      $table{$order[$i]}{'start_date'},
                                      $table{$order[$i]}{'start_time'},
                                      $table{$order[$i]}{'end_date'},
                                      $table{$order[$i]}{'end_time'},
                                      $table{$order[$i]}{'return'},
                                      $table{$order[$i]}{'steps'},
                                      $table{$order[$i]}{'errors'};
}

exit 0;

