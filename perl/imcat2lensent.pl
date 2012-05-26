#!/usr/local/bin/perl -w
# ======================================================================
#+
$usage = "

NAME
        imcat2lensent.pl

PURPOSE
        Return a catalog in LensEnt2 format

USAGE
        imcat2lensent.pl [flags] [options] \$project.cat

FLAGS
        -u              print this message
        -wcs            Assume world coordinates
        -clean          overwrite intermediate files

INPUTS
        objects.cat     Text catalogue of objects
        -x x0           x-coordinate of desired catalogue origin
        -y y0           y-coordinate of desired catalogue origin

OPTIONAL INPUTS
        -o outfile      write output to \"outfile\"
        -xcol i         x coordinate column number (0-indexed, def=1)
        -ycol j         x coordinate column number (0-indexed, def=2)
        -e1col i        e1 column number (0-indexed, def=-2)
        -e2col j        e2 column number (0-indexed, def=-1)
        -p pixelscale   pixel scale of catalog (ignored if wcs)
        -s sigma        uncertainty on ellipticity values (def=0.3)
        -c sigcrit      value of critical density (def=1.0)

OUTPUTS
        \$project.le2.txt   or some explicitly named catalogue

EXAMPLES
        imcat2lensent.pl -o outfile.cat \
                         -wcs -x 137.8602294922 -y 5.8373279572 \
                         -xcol 10 -ycol 11 test.cat

BUGS

REVISION HISTORY:
        2005-08-01 Started Cevallos and Marshall (KIPAC)
        2005-08-21 WCS option added Bradac (KIPAC)
        2005-08-24 Column numbers, ell width freed Marshall (KIPAC)
\n";
#-
# ======================================================================

$sdir = $ENV{'SCRIPTUTILS_DIR'};
require($sdir."/perl/esystem.pl");
$doproc = 1;

use Getopt::Long;
GetOptions("o=s", \$outfile,
           "x=f", \$x0,
           "y=f", \$y0,
           "p=f", \$pixel,
           "c=f", \$sigcrit,
           "s=f", \$sigma,
           "wcs", \$wcs,
           "xcol=i", \$xcol,
           "ycol=i", \$ycol,
           "e1col=i", \$e1col,
           "e2col=i", \$e2col,
           "u", \$help
          );

(defined($help)) and die "$usage\n";
$num=@ARGV;
($num>0) or die "$usage\n";

(defined($x0)) or die "ERROR: specify x-coordinate for central object";
(defined($y0)) or die "ERROR: specify y-coordinate for central object";

(not defined($pixel) and not defined($wcs)) and die "ERROR: specify pixel scale";
(defined($wcs)) and ($pixel = 3600.0);

(defined($sigcrit)) or ($sigcrit = 1);

(defined($sigma)) or ($sigma = 0.3);

# Default column numbers:
(defined($xcol)) or ($xcol = 1);
(defined($ycol)) or ($ycol = 2);
(defined($e1col)) or ($e1col = -2);
(defined($e2col)) or ($e2col = -1);

$sensible=0;
(defined($outfile)) or ($sensible = 1);

#-----------------------------------------------------------------------


# Check for imcat environment:

# Read in a catalog file from command, check its existence,
# blat its contents into @info

$cat = shift @ARGV;

#Define $outfile:

if ($sensible) {
   $root = $cat;
   $root =~ s/(.*)\..*/$1/;
   $outfile = "$root".".le2.txt";
}

# Count number of galaxies:

open CAT, $cat or die "Cannot read catalog file: $!";
@info = <CAT>;
$hash = 0;
$end = 0;
while($end == 0){
  foreach $hashline(@info){
    if($hashline =~ /^\#/){
          $hash++;
    }
    else{
       $end = 1;
    }
  }
}
$numgals = $#info - $hash +1;
close CAT;

# Open file for writing:
print "Output file $outfile\n";
open(FILE, ">$outfile") or die "ERROR: $!";
print FILE "LensEnt2 input catalogue, by imcat2lensent.pl\n $numgals \n $sigcrit \n\n";
print FILE "\t x \t y \t\t e1 \t e1err \t e2 \t e2err \n\n";

# Re-open catalogue, skip header, copy lines:

open CAT, $cat;
while (<CAT>){
  next if (/^\#/ or /^$/);
  chomp;
  @jcols = split;

  if (defined($wcs)) {
    $x = -($jcols[$xcol] - $x0) * $pixel * cos($y0*3.141592654/180.0);
    $y = ($jcols[$ycol] - $y0) * $pixel;
  } else {
    $x = ($jcols[$xcol] - $x0) * $pixel;
    $y = ($jcols[$ycol] - $y0) * $pixel;
  }

  $e1 = $jcols[$e1col];
  $e2 = $jcols[$e2col];

# Cut on ellipticity - zero-weight if larger than 2:

  $ee = sqrt($e1*$e1 + $e2*$e2);
  if ($ee > 2) {
    $err = 0.0;
  } else {
    $err = $sigma;
  }

  printf FILE "%8.1f %8.1f\t %8.3f\t %4.3f\t %4.3f\t %4.3f\n", $x, $y, $e1, $err, $e2, $err;

}

close(FILE);
close CAT;

# ======================================================================
