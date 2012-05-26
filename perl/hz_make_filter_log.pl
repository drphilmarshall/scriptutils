#!/usr/local/bin/perl -w
# =============================================================================
#+
$usage = "

NAME
        hz_make_filter_log.pl

PURPOSE
        From a filter.res file, make a filter.log file.

USAGE
        hz_make_filter_log.pl mag2mag_filters.res

FLAGS
        -u        Print this message

INPUTS
        filterresfile
   
OPTIONAL INPUTS

OUTPUTS

OPTIONAL OUTPUTS

COMMENTS

EXAMPLES

BUGS

REVISION HISTORY:
  2007-02-28 Started Marshall (UCSB)

\n";
#-
# ======================================================================

$sdir = $ENV{'SCRIPTUTILS_DIR'};
require($sdir."/perl/hz_library.pl");

use Getopt::Long;
GetOptions("u", \$help
           );

(defined($help)) and die "$usage\n";

if (defined($filterresfile = shift)){
  open (IN, $filterresfile) or die "$filterresfile: $!";
  close (IN);
} else {
  die "No input file supplied.\n";
}

# Get filternames:
@filternames = &hz_read_filter_res_file($filterresfile);

$outfile = "filter.log";

# Write to file:
open (OUT, ">$outfile") or die "Couldn't open $outfile: $!";
print OUT "\t#\tFilter\n";
print OUT "------------------------------------------------------------------------------\n";
for ($i = 0; $i < $#filternames+1; $i++){
  $j = $i + 1; 
  print OUT "\t$j\t$filternames[$i]\n";
}
close(OUT);
    
# ======================================================================
