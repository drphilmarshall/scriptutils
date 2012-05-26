#!/usr/local/bin/perl -w
# =============================================================================
#+
$usage = "

NAME
        hz_make_bolometric_filter.pl

PURPOSE
        Write a 200-point FILTER.RES entry for appending to hyperz filter set.

USAGE
        hz_make_bolometric_filter.pl

FLAGS
        -u        Print this message

INPUTS

OPTIONAL INPUTS

OUTPUTS

OPTIONAL OUTPUTS

COMMENTS

EXAMPLES

BUGS

REVISION HISTORY:
  2007-02-27 Started Marshall (UCSB)
  2007-02-28 Switched to more standard 2-column plain text Marshall (UCSB)

\n";
#-
# ======================================================================

# $\="\n";

use Getopt::Long;
GetOptions("u", \$help
           );

(defined($help)) and die "$usage\n";


# Default numbers - make sure they are within range of spectra [91:97400]!:
$xmin = 100.0;
$xmax = 95000.0;
$n = 200;

$outfile = "Bolometric.res";

# Write to files:
open (OUT, ">$outfile") or die "Couldn't open $outfile: $!";
# print OUT "\t$n\tBolometric\n";
for ($i = 0; $i < $n; $i++){
#   $j = $i + 1;
  if ($i == 0) {
    $x = int($xmin);
    $t = 0.0;
  } elsif ($i == 1) {
    $x = int($xmin + 1.0);
    $t = 1.0;
  } elsif ($i == ($n-2)) {
    $x = int($xmax - 1.0);
    $t = 1.0;
  } elsif ($i == ($n-1)) {
    $x = int($xmax);
    $t = 0.0;
  } else { 
    $a = 1.0*$i/(1.0*$n);
# Logarithmic/geometric spacing  
    $x = int(($xmin**(1.0-$a)) * ($xmax**$a));
# # Uniform [0:20000] spacing redshifted to z=4: 
#     $x = int($xmin + $a * ($xmax - $xmin));
    $t = 1.0;
  }

#   print OUT "\t$j\t$x\t$t\n";
  print OUT "\t$x\t\t$t\n";
}
close(OUT);

print "New filter.res file written to $outfile\n";
    
# ======================================================================
