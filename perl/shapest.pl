#!/usr/local/bin/perl -w
# ======================================================================
#+
$usage = "

NAME
        shapest.pl

PURPOSE
        Extract object shapes from image, given SExtractor positions.

USAGE
        shapest.pl [flags] [options] \$project.cat

FLAGS
        -u			print this message
        -clean		overwrite existing files

INPUTS
        \$project.cat     Text catalogue of objects

OPTIONAL INPUTS
        -o outfile	write output to \"outfile\"
        -s sigma        provide image sigma (def=calculate)
        -m mode         provide image mode (def=calculate)
        -v verb         verbosity level (def=1)
        -threshold n    n-sigma acceptance threshold (def=5)

OUTPUTS
        \$project.master.cat or some explicitly named catalogue

EXAMPLES

BUGS

REVISION HISTORY:
        2003-05-?? Started Czoske (Bonn) and Marshall (MRAO)
        2005-08-24 Various upgrades by Bradac and Norte (KIPAC)
\n";
#-
# ======================================================================

$sdir = $ENV{'SCRIPTUTILS_DIR'};
require($sdir."/perl/esystem.pl");
$doproc = 1;

use Getopt::Long;
GetOptions("o=s", \$outfile,
           "s=f", \$sigma,    
           "m=f", \$mode,    
           "threshold=f", \$nsigma,    
	     "clean", \$clean,
	     "u", \$help
	    );

(defined($help)) and die "$usage\n";
$num=@ARGV;
($num>0) or die "$usage\n";

$sensible=0;
(defined($outfile)) or ($sensible = 1);

(defined($verb)) or ($verb = 1);

$calcstats=0;
((defined($sigma)) and (defined($mode))) or ($calcstats = 1);

(defined($nsigma)) or ($nsigma = 5);

# Check for imcat environment:

(defined($ENV{"IMCATDIR"})) or die "Imcat environment undefined.\n"; 

# Check for existence of catalogue:

$catfile = shift @ARGV;
(-e $catfile) or die "shapest: $catfile not found.\n";

# Pull out photometric zero point::

chomp($zp=`lc -p magzero < $catfile`);
#print STDERR "zp = $zp\n\n";
#die "\n";

# Set up filename root and output filenames:

$root = $catfile;
$root =~ s/(.*)\..*/$1/;

$gotsigfile = $root.".gotsig.cat";
$gotskyfile = $root.".gotsky.cat";
$gotap1file = $root.".gotap1.cat";
$gotshapesfile = $root.".gotshapes.cat";
$gotap2file = $root.".gotap2.cat";

if ($sensible == 1) {
  $outfile = $root.".master.cat";
}

# Set imcat to work:

if (-e $gotsigfile and -s $gotsigfile and not (defined($clean))){
  print STDERR "\n$gotsigfile exists, moving on to get sky.\n";
} else {
  print STDERR "Calculating rg values, do not interrupt!\n";
  if ($calcstats == 1) {
&esystem("lc -b  < $catfile | cleancat -m smag 8 | 
getsig -d 0.2 -r .5 20 > $gotsigfile", $doproc, $verb); 
  } else {
&esystem("cleancat -m smag 8 < $catfile | 
getsig -d 0.2 -r .5 20 -s $sigma $mode > $gotsigfile", $doproc, $verb); 
  }
}

if (-e $gotskyfile and -s $gotskyfile and not (defined($clean))){
  print STDERR "$gotskyfile exists, moving on to photometry.\n";
} else {
  print STDERR "Calculating sky background, do not interrupt!\n";
&esystem("lc -b -i '\%nu $nsigma >' < $gotsigfile |  
getsky -Z rg 3 > $gotskyfile", $doproc, $verb); 
}

if (-e $gotap1file and -s $gotap1file and not (defined($clean))){
  print STDERR "$gotap1file exists, moving on to get shapes.\n";
} else {
  print STDERR "Doing first pass photometry, do not interrupt!\n";
&esystem("apphot -z $zp < $gotskyfile > $gotap1file", $doproc, $verb);   
}

if (-e $gotshapesfile and -s $gotshapesfile and not (defined($clean))){
  print STDERR "$gotshapesfile exists, moving on to better photometry.\n";
} else {
  print STDERR "Measuring object shapes, do not interrupt!\n";
&esystem("getshapes < $gotap1file > $gotshapesfile", $doproc, $verb);   
}

if (-e $gotap2file and -s $gotap2file and not (defined($clean))){
  print STDERR "$gotap2file exists, moving on to better photometry.\n";
} else {
  print STDERR "Doing second pass photometry, do not interrupt!\n";
#&esystem("  lc -i '\%d \%d dot sqrt 1 < ' < $gotshapesfile |   
#lc +all 'x = \%x \%d vadd' |  
#apphot -z $zp > $gotap2file");
&esystem("lc -x < $gotshapesfile |   
lc +all 'x = \%x \%d vadd' |  
apphot -z $zp > $gotap2file", $doproc, $verb);
}
  
if (-e $outfile and -s $outfile and not (defined($clean))){
  print STDERR "$outfile exists, everything is already done!\n";
} else {
  print STDERR "Measuring object shapes, do not interrupt!\n";
&esystem("getshapes < $gotap2file > $outfile", $doproc, $verb);
}

# ======================================================================
