#!/usr/local/bin/perl -w
# ======================================================================
#+
$usage = "

NAME
        ellrotate.pl

PURPOSE
        Read in an object catalogue, offset and rotate it according to 
        the command line options, and return a rotated catalogue in the
        original format. Default positions are x and y in arcsec
        relative to supplied centre.

USAGE
        ellrotate.pl [flags] [options] \$project.cat \$other.cat ...

FLAGS
        -u        Print this message
        -h        Ignore catalogue header (marked with \#)
        -relative Output x and y will be relative coords in arcsec
        -errors   Include error propagation
        -test     Do a test case (\$project = test)
        
INPUTS
        \$project.cat     Object catalogue (multi-column text)

OPTIONAL INPUTS
        -o     file      Write output to \"file\" (def=\$project.wcs.cat)
        -FITS image      Get WCS information from header of FITS file 
                           \"image\" (def=\$project.fits)
        -x0     f        Desired centroid Ra 
        -y0     f        Desired centroid Dec
        -CRPIX1 f        Reference x (pixels, def=0)
        -CRPIX2 f        Reference y (pixels, def=0)
        -CRVAL1 f        Reference Ra (degrees, def=0.0)
        -CRVAL2 f        Reference Dec degrees, def=0.0)
        -CRROTA f        Position angle
        -CRDELT f        Pixel scale / arcsec
        -xcol   i        Use ith column for x positions (def=1)
        -ycol   i        Use ith column for y positions (def=2)
        -e1col  i        Use ith column for e1 (def=-4)
        -e1errcol   i    Use ith column for e1err (def=-3)
        -e2col  i        Use ith column for e2 (def=-2)
        -e2errcol   i    Use ith column for e2err (def=-1)
        \$other.cat ...  Other catalogues (same format multi-column text)

OUTPUTS
        \$project.wcs.cat     or explicitly named output catalogue file

OPTIONAL OUTPUTS

COMMENTS

EXAMPLES

FITS file header says:

CRPIX1  =              145.201 / Reference Pixel in X                           
CRPIX2  =             -2408.02 / Reference Pixel in Y                           
CRVAL1  =        214.612347283 / R.A. (degrees) of reference pixel              
CRVAL2  =        52.5890665126 / Declination of reference pixel                 
CTYPE1  = 'RA---TAN'           / the coordinate type for the first axis         
CTYPE2  = 'DEC--TAN'           / the coordinate type for the second axis        
CD1_1   =   -5.49578036933E-06 / Degrees / Pixel                                
CD1_2   =   -6.26559628274E-06 / partial of second axis coordinate w.r.t. x     
CD2_1   =   -6.26579776421E-06 / partial of first axis coordinate w.r.t. x      
CD2_2   =    5.49464180336E-06 / partial of first axis coordinate w.r.t. y      

This corresponds to 

CRDELT  = 8.3333333E-06
CRROTA  = 48.74

Note that the Reference pixel and posistion is off the cutout - and
indeed is wrong... The following command gives the right result, a
catalogue with positions in WCS and the rotation done right.

ellrotate.pl -test \
-CRPIX1   108.53871 \
-CRPIX2   114.6686 \
-CRVAL1   214.58665 \
-CRVAL2    52.603155 \
-CRROTA    48.74 \
-CRDELT     8.333333E-06

This next example puts the test.wcs.cat as relative coords in arcsec:
here we need to specify a suitable centre:

ellrotate.pl -test \
-o test.relative.cat \
-relative \
-x0       214.58819 \
-y0        52.602997 \
-CRPIX1   108.53871 \
-CRPIX2   114.6686 \
-CRVAL1   214.58665 \
-CRVAL2    52.603155 \
-CRROTA    48.74 \
-CRDELT     8.333333E-06

Now look at test.fits, test.reg, test.wcs.reg etc etc.

In general it's better to use the WCS info in the FITS header:

ellrotate.pl test.cat \
-o test.FITS.cat \
-relative \
-x0       214.58819 \
-y0        52.602997 \
-image    test.fits


BUGS
 - no option to reduce verbosity

REVISION HISTORY:
  2006-07-26 Started Marshall (KIPAC)

\n";
#-
# ======================================================================

# $\="\n";

use Getopt::Long;
GetOptions("o=s", \$outfile,
           "x0=f", \$x0,
           "y0=f", \$y0,
           "CRPIX1=f", \$CRPIX1,
           "CRPIX2=f", \$CRPIX2,
           "CRVAL1=f", \$CRVAL1,
           "CRVAL2=f", \$CRVAL2,
           "CRDELT=f", \$CRDELT,
           "CRROTA=f", \$CRROTA,
           "xcol=i", \$xcol,
           "ycol=i", \$ycol,
           "e1col=i", \$e1col,
           "e2col=i", \$e2col,
           "e1errcol=i", \$e1errcol,
           "e2errcol=i", \$e2errcol,
	     "image=s", \$image,
           "relative", \$relative,
           "errors", \$errors,
           "test", \$test,
           "h", \$header,
           "u", \$help
           );

(defined($help)) and die "$usage\n";
$num=@ARGV;
(($num == 0) and ! defined($test)) and die "$usage\n";

$sensible = 0;
(defined($outfile)) or ($sensible = 1);
($num>1) and $sensible=1;

# Transformation WCS information - either from file, or from command
# line:

if (defined($image)){
  $CRPIX1 = qx{imhead < test.fits | grep CRPIX1 | head -1 | cut -d"=" -f2 | cut -d"/" -f1};
  $CRPIX2 = qx{imhead < test.fits | grep CRPIX2 | head -1 | cut -d"=" -f2 | cut -d"/" -f1};
  $CRVAL1 = qx{imhead < test.fits | grep CRVAL1 | head -1 | cut -d"=" -f2 | cut -d"/" -f1};
  $CRVAL2 = qx{imhead < test.fits | grep CRVAL2 | head -1 | cut -d"=" -f2 | cut -d"/" -f1};
  $CD1_1  = qx{imhead < test.fits | grep CD1_1  | head -1 | cut -d"=" -f2 | cut -d"/" -f1};
  $CD1_2  = qx{imhead < test.fits | grep CD1_2  | head -1 | cut -d"=" -f2 | cut -d"/" -f1};
  $CD2_1  = qx{imhead < test.fits | grep CD2_1  | head -1 | cut -d"=" -f2 | cut -d"/" -f1};
  $CD2_2  = qx{imhead < test.fits | grep CD2_2  | head -1 | cut -d"=" -f2 | cut -d"/" -f1};
  $CRROTA = atan2($CD1_2,$CD1_1);
  if ($CRROTA < 0.0) {$CRROTA+=2.0*3.141592654};
  $CRDELT = sqrt(abs($CD1_1*$CD2_2 - $CD1_2*$CD2_1))*3600.0;
} else {  
# Set up defaults for transformation:
  (defined($CRPIX1)) or $CRPIX1 = 0.0;
  (defined($CRPIX2)) or $CRPIX2 = 0.0;
  (defined($CRVAL1)) or $CRVAL1 = 0.0;
  (defined($CRVAL2)) or $CRVAL2 = 0.0;
  (defined($CRROTA)) or $CRROTA = 0.0;
  (defined($CRDELT)) or $CRDELT = 1.0;
# Construct CD matrix:  
  $CRROTA = 3.141592654*$CRROTA/180.0;
  $CD1_1 = -$CRDELT * cos($CRROTA);
  $CD1_2 = -$CRDELT * sin($CRROTA);
  $CD2_1 = -$CRDELT * sin($CRROTA);
  $CD2_2 =  $CRDELT * cos($CRROTA);
}

print STDERR "\n************************";
print STDERR "\nThis is ellrotate.pl";
print STDERR "\n************************";
print STDERR "\n";

print STDERR "\nTransforming to WCS using the following keywords:\n";
print STDERR "CRPIX1 = $CRPIX1";
print STDERR "CRPIX2 = $CRPIX2";
print STDERR "CRVAL1 = $CRVAL1";
print STDERR "CRVAL2 = $CRVAL2";
print STDERR "CRROTA = $CRROTA\n";
print STDERR "CRDELT = $CRDELT\n";
print STDERR "CD1_1  = $CD1_1";
print STDERR "CD1_2  = $CD1_2";
print STDERR "CD2_1  = $CD2_1";
print STDERR "CD2_2  = $CD2_2\n";

# Relative coordinates:
if (defined($relative)) {
print STDERR "Output catalogue will have positions in arcsec\n";
print STDERR "relative to following centroid:\n";
print STDERR "x0 = $x0\n";
print STDERR "y0 = $y0\n";
$scale = 3600.0;
} else {
print STDERR "Output positions will be in degrees WCS\n";
$scale = 1.0;
}
(defined($x0)) or $x0 = 0.0;
(defined($y0)) or $y0 = 0.0;

if (defined($test)) {
  $errors = 1;
# Set up fake catalogue, and insert it into the argument list:
  $testfile = "test.cat";
  open (TEST, ">$testfile") or die "Couldn't open $testfile: $!";
  # Object 1:
  $id = 1; 
  $x = 100;
  $y = 150;
  $e1 = 0.6;
  $e2 = 0.0;
  $e1err = 0.1;
  $e2err = 0.1;
  @line = ($id,$x,$y,$e1,$e1err,$e2,$e2err);
  print TEST "@line\n";
  # Object 2:
  $id = 2; 
  $x =  50;
  $y = 100;
  $e1 = -0.6;
  $e2 = 0.0;
  $e1err = 0.1;
  $e2err = 0.1;
  @line = ($id,$x,$y,$e1,$e1err,$e2,$e2err);
  print TEST "@line\n";
  # Object 3:
  $id = 3; 
  $x = 100;
  $y =  50;
  $e1 = 0.6;
  $e2 = 0.0;
  $e1err = 0.1;
  $e2err = 0.1;
  @line = ($id,$x,$y,$e1,$e1err,$e2,$e2err);
  print TEST "@line\n";
  # Object 4:
  $id = 4; 
  $x = 150;
  $y = 100;
  $e1 = -0.6;
  $e2 = 0.0;
  $e1err = 0.1;
  $e2err = 0.1;
  @line = ($id,$x,$y,$e1,$e1err,$e2,$e2err);
  print TEST "@line\n";
  close (TEST);
  $ARGV[0] = $testfile;
}

# Default column numbers:
(defined($xcol)) or ($xcol = 1);
(defined($ycol)) or ($ycol = 2);
(defined($e1col)) or ($e1col = -4);
(defined($e1errcol)) or ($e1errcol = -3);
(defined($e2col)) or ($e2col = -2);
(defined($e2errcol)) or ($e2errcol = -1);

# Loop over catalogues:

while (defined($file = shift)){

    open (IN, $file) or die "$file: $!";
    print STDERR "\nReading data from $file ...\n";

# Sort out sensible filename:
    if ($sensible) {
       $root = $file;
       $root =~ s/(.*)\..*/$1/;
       $outfile = $root.".wcs.cat";
    }

# Count objects:
    $count = 0;
    $headcount = 0;

# Write region file header:
    open (OUT, ">$outfile") or die "Couldn't open $outfile: $!";
    (defined($header)) and (<IN>);
# Step through lines of catalogue,
    while (<IN>){
      chomp;
# dealing with header lines,      
      if (/^\#/ or /^$/){
        print OUT "$_\n";
        $headcount++;
        next;        
      } else {
        @line = split;
      }
      
# and working out appropriate object information:

# First get all the quantities:
      $i = $line[$xcol];
      $j = $line[$ycol];
      $e1 = $line[$e1col];
      $e2 = $line[$e2col];
      
      if (defined($errors)){
        $e1err = $line[$e1errcol];
        $e2err = $line[$e2errcol];
      }
      
# Now transform the coordinates - define relative x to be antiparallel
# to right ascension:

      $dx = $i - $CRPIX1;
      $dy = $j - $CRPIX2;
      
      $dra =  ($CD1_1*$dx + $CD1_2*$dy)/cos(3.141592654*$CRVAL2/180.0);
      $x =  $CRVAL1 + $dra;
      (defined($relative)) and $x = -($x - $x0) * cos(3.141592654*$CRVAL2/180.0) * $scale;
      $ddec = ($CD2_1*$dx + $CD2_2*$dy);
      $y =  $CRVAL2 + $ddec;
      (defined($relative)) and $y =  ($y - $y0) * $scale;

# And now apply rotation to the ellipticities:
  
      $c = cos(2.0*$CRROTA);
      $s = sin(2.0*$CRROTA);
      $e1prime = $e1*$c + $e2*$s;
      $e2prime = $e2*$c - $e1*$s;
      if (defined($errors)){
        $cc = $c*$c;
        $ss = $s*$s;
        $v1 = $e1err*$e1err;
        $v2 = $e2err*$e2err;
        $e1primeerr = sqrt($v1*$cc + $v2*$ss);
        $e2primeerr = sqrt($v1*$ss + $v2*$cc);
      }

# Print out modified line:
      
      $line[$xcol] = $x;
      $line[$ycol] = $y;
      $line[$e1col] = $e1prime;
      $line[$e2col] = $e2prime;
      if (defined($errors)){
        $line[$e1errcol] = $e1primeerr;
        $line[$e2errcol] = $e2primeerr;
      }
       print OUT "@line\n";        
     
      $count++;
     
    }
    close(IN);
    print STDERR "\n$headcount header lines written to $outfile\n";
    print STDERR "$count object lines written to $outfile\n";
    close(OUT);

}

# ======================================================================
