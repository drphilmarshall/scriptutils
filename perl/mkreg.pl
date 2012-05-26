#!/usr/local/bin/perl -w
# ======================================================================
#+
$usage = "

NAME
        mkreg.pl

PURPOSE
        Make a ds9 region file (circles or ellipses) from an object
        catalogue.

USAGE
        mkreg.pl [flags] [options] \$project.cat \$other.cat ...

FLAGS
        -u        Print this message
        -h        Ignore catalogue header (marked with \#)
        -wcs      Make regions in WCS coordinates
        -c        Plot circles of fixed radius R (default)
        -c2       Plot circles using radius from catalogue
        -e        Plot ellipses using e1, e2 from catalogue and fixed radius R
        -e2       Plot ellipses using e1, e2, r from catalogue
        -text     Plot text (using zcol value)
        -box      Box of size rbox and angle abox
        -ds9      load region file into ds9 directly
        -ds9clean clean ds9 regions
INPUTS
        \$project.cat     Object catalogue (multi-column text)

OPTIONAL INPUTS
        -o      file     Write output to \"file\" (def=\$project.reg)
        -colour string   Region marker colour (def=red)
        -xcol   i        Use ith column for x positions (def=1)
        -ycol   i        Use ith column for y positions (def=2)
        -rad    f        Use R=f pixels/arcsec (def=33/1.0)
        -rbox   f        Box size
        -abox   f        Box angle
        -rcol   i        Use ith column for radii (def=5)
        -e1col  i        Use ith column for e1 (def=-2)
        -e2col  i        Use ith column for e1 (def=-1)
        -zcol  i        Use ith column for z
        -format string Give formatting when using -text (e.g %ld def=%.1f)
        -nh      i  Ignore first nh lines of the catalogue
        -e2col  i        Use ith column for e2 (def=-1)
        \$other.cat ...   Other catalogues (multi-column text)
OUTPUTS
        \$project.reg     or explicitly named ds9 region output file

OPTIONAL OUTPUTS

COMMENTS

EXAMPLES

BUGS
  - No useful output to the screen
  - Defaults maybe mixed up


REVISION HISTORY:
  2003-05-??  Started Czoske (Bonn) and Marshall (MRAO)
  2005-08-20  WCS, text options added Bradac (KIPAC)

\n";
#-
# ======================================================================
$sdir = $ENV{'SCRIPTUTILS_DIR'};
require($sdir."/perl/esystem.pl");
$doproc = $vb =1;

use Getopt::Long;
GetOptions("o=s", \$outfile,
           "wcs", \$wcs,
           "text", \$text,
	   "box", \$box,
           "c", \$circle,
           "c2", \$circle2,
           "e", \$ellipse,
           "e2", \$ellipse2,
           "xcol=i", \$xcol,
           "ycol=i", \$ycol,
           "rad=f", \$radius,
           "rbox=f", \$rbox,
	   "abox=f", \$abox,
           "rcol=i", \$rcol,
           "e1col=i", \$e1col,
           "e2col=i", \$e2col,
           "zcol=i", \$zcol,
           "colour=s", \$colour,
	   "format=s", \$format,
	   "nh=i", \$nhead,
           "h", \$header,
	   "ds9", \$ds9,
	   "ds9clean", \$ds9clean,
           "u", \$help
           );

(defined($help)) and die "$usage\n";
$num=@ARGV;
($num>0) or die "$usage\n";
$header=1;
$sensible = 0;
(defined($outfile)) or ($sensible = 1);
(defined($format)) or ($format = "%.1f");
(defined($nhead)) or ($nhead = 0);
($num>1) and $sensible=1;

# Default region is a red circle of radius 20 pixels:
$shape = 0;
if (defined($circle)) {
  $shape = 0;
} elsif (defined($circle2)) {
  $shape = 1;
} elsif (defined($ellipse)) {
  $shape = 2;
} elsif (defined($ellipse2)) {
  $shape = 3;
} elsif (defined($text)) {
  $shape = 4;
} elsif (defined($box)) {
  $shape = 5;
  (defined($rbox)) or ($rbox = 1.0);
  (defined($abox)) or ($abox = 0.0);

}
(defined($colour)) or ($colour = "red");

# WCS regions:
if (defined($wcs)) {
$region = "fk5";
(defined($radius)) or ($radius = 1.0);
$radius = $radius/3600.0;
} else {
$region = "image";
(defined($radius)) or ($radius = 33);
}
if ((defined($wcs)) and  ($shape == 2 or $shape == 3)) {
    print "Make sure ellipticities are measured w.r.t. Ra \n";
}
# Default column numbers:
(defined($xcol)) or ($xcol = 1);
(defined($ycol)) or ($ycol = 2);
(defined($rcol)) or ($rcol = 5);
(defined($e1col)) or ($e1col = -2);
(defined($e2col)) or ($e2col = -1);

# Loop over catalogues:

while (defined($file = shift)){

    open (IN, $file) or die "$file: $!";

# Sort out sensible filename:
    if ($sensible) {
       $root = $file;
       $root =~ s/(.*)\..*/$1/;
       $outfile = $root.".reg";
    }

# Write region file header:
    open (OUT, ">$outfile") or die "Couldn't open $outfile: $!";
    print OUT "\# Region file format: DS9 version 3.0\n";
    print OUT "global color=$colour font=\"helvetica 10 normal\" select=1 edit=1 move=1 delete=1 include=1 fixed=0 \n";
# Step through lines of catalogue,
  
    while (<IN>){
# missing out header lines,
      (defined($header)) and next if (/^\#/ or /^$/) and ($nhead++);
     
      next unless $. > $nhead; 
     
      chomp;
      @line = split;
# and writing out appropriate region information:
      if ($shape==0) {
        print OUT "$region;circle($line[$xcol],$line[$ycol],$radius)\n";
      } elsif ($shape==1) {
        $radius = 0.5*$line[$rcol];
        print OUT "$region;circle($line[$xcol],$line[$ycol],$radius)\n";
      } elsif ($shape==2) {
        $e1 = $line[$e1col];
        $e2 = $line[$e2col];
        $phi = 57.3*atan2($e2,$e1);
	  if ($phi < 0.0) {$phi+=360.0};
	  $phi /= 2.0;
        $ee = sqrt($e1**2 + $e2**2);
        $a = $radius*(1 + $ee);
        $b = $radius*(1 - $ee);
        print OUT "$region;ellipse($line[$xcol],$line[$ycol],$a,$b,$phi)\n";
      } elsif ($shape==3) {
        $e1 = $line[$e1col];
        $e2 = $line[$e2col];
        $phi = 57.3*atan2($e2,$e1);
	  if ($phi < 0.0) {$phi+=360.0};
	  $phi /= 2.0;
        $ee = sqrt($e1**2 + $e2**2);
        $a = $line[$rcol]*(1 + $ee);
        $b = $line[$rcol]*(1 - $ee);
        print OUT "$region;ellipse($line[$xcol],$line[$ycol],$a,$b,$phi)\n";
    } elsif ($shape==4) {
	printf OUT "$region;text($line[$xcol],$line[$ycol]) # text={$format}\n",$line[$zcol];
	} elsif ($shape==5) {
	    (defined ($wcs)) and printf OUT "$region;box($line[$xcol],$line[$ycol], $rbox\", $rbox\", $abox)\n";
	     (defined ($wcs)) or printf OUT "$region;box($line[$xcol],$line[$ycol], $rbox, $rbox, $abox)\n";
       }
    
    
  }
    close(IN);
}

close(OUT);


(defined($ds9clean)) and esystem("xpaset -p ds9 regions delete all", $doproc, $vb);

(defined($ds9)) and esystem("cat $outfile | xpaset ds9 regions", $doproc, $vb);

# ======================================================================
