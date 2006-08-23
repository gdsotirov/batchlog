#!/usr/bin/perl
# Batch chain log parser for GraphTalk AIA
# Written by Georgi D. Sotirov <gsotirov@obs.bg>
# Date: 2006-08-23
#
# This script will output the main information about the batches
# in CSV (Comma Separated Values) format.
#
# To use it make sure the file is executable at least to its owner:
# $ chmod u+x logparse.pl
# And then run it with at one argument - path to the log file
# $ ./logparse.pl my_log_file
#
# Note: This script asumes that:
#         1. Dates are in format DDMMYYYY
#         2. Times are in format HH:MM:SS
#         3. Genrally that data is correct, no verification included
#

(@ARGV == 1) or die "Usage: $0 <log file>\n";
  
$SEP = ";"; # Output field separator

$logfile = $ARGV[0];

sub reformat_date($) {
  $_[0] =~ s/([0-9]{2})([0-9]{2})([0-9]{4})/$1\/$2\/$3/;
  return $_[0];
}

sub parse_time($) {
  ($hour, $min, $sec) = split(/:/, $_[0]);
  return $hour * 3600 + $min * 60 + $sec;
}

sub format_time($) {
  my $secs = $_[0];
  my $hour = int($secs / 3600);
  $secs %= 3600;
  my $min = int($secs / 60);
  $secs %= 60;
  return sprintf "%02d:%02d:%02d", $hour, $min, $secs;
}

sub calc_duration($$) {
  my $secs1 = parse_time($_[0]);
  my $secs2 = parse_time($_[1]);
  if ( $secs2 < $secs1 ) {
    $secs2 += 24 * 3600; # Add one day if the end date is in the next daynight
  }
  my $dur = $secs2 - $secs1;
  return format_time($dur);
}

open(LOGFILE, $logfile) or die "Error: Can not open file '$logfile': $!\n";

my $number = 0;
my %table;

# PASS 1: Collect data in a hash since it can be spred in the file
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

# PASS 2: Find data order, calculate duration
my @order;
foreach $key (keys %table) {
  $order[$table{$key}{'order'}] = $key;
  $table{$key}{'duration'} = calc_duration($table{$key}{'start_time'}, $table{$key}{'end_time'});
}

# Print gathered information
print "Batch${SEP}Start date${SEP}Start time${SEP}End date${SEP}End time${SEP}Duration${SEP}Steps${SEP}Errors${SEP}Exit code\n";
for (my $i = 1; $i < scalar(@order); ++$i ) {
  printf "%s${SEP}%s${SEP}%s${SEP}%s${SEP}%s${SEP}%s${SEP}%d${SEP}%d${SEP}%d\n",
          $order[$i],
          $table{$order[$i]}{'start_date'},
          $table{$order[$i]}{'start_time'},
          $table{$order[$i]}{'end_date'},
          $table{$order[$i]}{'end_time'},
          $table{$order[$i]}{'duration'},
          $table{$order[$i]}{'steps'},
          $table{$order[$i]}{'errors'},
          $table{$order[$i]}{'return'};
}

exit 0;

