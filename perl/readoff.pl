#!/usr/local/bin/perl -w
# ============================================================================
#+
$usage = "\n
NAME
        readoff.pl

PURPOSE
        Read in a text file, assume that the first two columns represent x and
        y datapoints, make sure they are sorted in order of increasing x, 
        and then readoff the value of y given x (or vice versa).

USAGE
        readoff.pl [flags] [-x \$x] [-y \$y] data.txt

FLAGS
  -u              print this message

INPUTS
   data.txt       ascii text file

OPTIONAL INPUTS
  -x x            Input x value - return y
  -y y            Input y value - return x
  -magic n        Output magic number n if input value is outside range

COMMENTS
  If function is multivalued, print all occurrences!

EXAMPLES
  readoff.pl -x 6536 spectrum.txt

OUTPUTS
  stdout          Value of y (or x)

OPTIONAL OUTPUTS

BUGS
  - file is assumed to be sorted in ascending order of x
  - no header values allowed

REVISION HISTORY:
  2007-12-18 Started - Marshall (UCSB)

\n";
#-
# ==============================================================================

# $sdir = $ENV{'SCRIPTUTILS_DIR'};
# require($sdir."/perl/esystem.pl");
# $doproc = 1;

use Getopt::Long;
GetOptions("x=f", \$x0,
           "y=f", \$y0,
           "magic=f", \$magicnumber,
           "u", \$help
          );

(defined($help)) and die "$usage\n";
$num=@ARGV;
($num>0) or die "$usage\n";

$donothing = 1;
$findygivenx = 0;
$findxgiveny = 0;
if (defined($x0)){
  $findygivenx = 1;
  $donothing = 0;
} elsif (defined($y0)){  
  $findxgiveny = 1;
  $donothing = 0;
}
($donothing) and die "$usage\n";

#-------------------------------------------------------------------------------

# Check for infile's existence:

$infile = shift @ARGV;
(-e $infile) or die "ERROR: $infile does not exist.";

# Read in data:

open DATA, $infile or die "ERROR: cannot read $infile: $!";

# Package up x and y arrays - BUG here, free-format data readin is not clean..

$i = 0;
while (<DATA>){ # iterate through $infile

  next if (/^\#/ or /^$/);
  chomp;
  @cols = split;

  $x[$i] = $cols[0];
  $y[$i] = $cols[1];
  $i ++;
#    print "x = $x[$i]   y = $y[$i]\n";
}
# print STDERR "  Read in $#x lines of data...\n";


if ($findygivenx){
# Case 1 - find y given x. Just search sorted x array until you find x0, then
# linearly interpolate to get y.
# BUG!? Assume values are sorted by x... and contain no other numbers...
  $ii = -1;
  $y0 = $magicnumber;
#   ($x0 < $x[0]) and goto YOUTPUT;
#   ($x0 > $x[$#x]) and goto YOUTPUT; 

  $i = 0;
  if ($x0 >= $x[0]){
    do {
      $i++;
      ($x[$i] >= $x0) and $ii = $i;
#       print STDERR "  $i   $x[$i]   $ii\n";
      if ($ii > 0) {
        $x1 = $x[$ii-1];
        $x2 = $x[$ii];
        $y1 = $y[$ii-1];
        $y2 = $y[$ii];
        $y0 = $y1 + ($y2 - $y1)*($x0 - $x1)/($x2 - $x1);
      }
    } until (($ii > 0) or ($i == $#x));
#     print STDERR "  exited loop, ii=$ii, i=$i\n";
  }
YOUTPUT:
  if ($ii < 0 and not defined($magicnumber)){
    print STDERR "x-value $x0 outside data range \n";
  } else {
    print STDOUT "$y0 \n"; 
  }  
    
} else {
# Case 2 - find x given y. Search y array until you find y0, then
# linear interpolate to get x. Then continue!
  $ii = -1;
  $ready = 0;
  $count = 0;
  if ($y[0] > $y0){
    $above = 1;
    $below = 0;
  } else {
    $above = 0;
    $below = 1;
  }  
  for ($i = 1; $i < $#x; $i++){ # iterate through $infile
    if ($y[$i] > $y0){
      ($below) and $ready = 1;
      $above = 1;
      $below = 0;
    } else {
      ($above) and $ready = 1;
      $above = 0;
      $below = 1;
    }  
    if ($above and $ready) {
      $ii = $i;
    } elsif ($below and $ready) {
      $ii = $i;
    }  
#     print STDERR "$i x=$x[$i] y=$y[$i] - above=$above, ready=$ready, ii=$ii \n";
    if ($ii > 0) {
      $x1 = $x[$ii-1];
      $x2 = $x[$ii];
      $y1 = $y[$ii-1];
      $y2 = $y[$ii];
      $x0 = $x1 + ($x2 - $x1)*($y0 - $y1)/($y2 - $y1);
      print STDOUT "$x0 \n"; 
      $count++;
      $ii = 0;
      $ready = 0;
    }
  }
  ($count == 0) and print STDERR "y-value $y0 outside data range \n";

}

FINISH:
# ======================================================================
