#!/usr/local/bin/perl -w
# ======================================================================
#+
$usage = "

NAME
        transform_cat_to_wcs.pl

PURPOSE        
        Rotate imcat catalogue (x,y in pixels) onto WCS defined in fits file.

FLAGS
        -u      Print this message
        -v      Verbose output

INPUTS
        file.cat        imcat catalogue

OPTIONAL INPUTS
        -o outfile	write output to \"outfile\" (def=file.WCS.cat)
        -x ra           provide RA of catalogue centre (deg, def=CRVAL1)
        -y dec          provide Dec of catalogue centre (deg, def=CRVAL2)

OUTPUTS
        gallery.ps       or explicitly named output file

OPTIONAL OUTPUTS

COMMENTS

EXAMPLES
        transform_cat_to_wcs.pl -x 256.34252 -y 32.3476372 file.cat 

BUGS
  - Existing ra and dec columns are overwritten

REVISION HISTORY:
  2006-05-11  Started Marshall (KIPAC)

\n";
#-
# ======================================================================

$doproc = 1;

use Getopt::Long;
GetOptions("o=s", \$outfile,
           "x=f", \$ra,    
           "y=f", \$dec,    
	     "v", \$verbose,
	     "u", \$help
	    );

(defined($help)) and die "$usage\n";
$num=@ARGV;
($num>0) or die "$usage\n";

$vb = 0;
(defined($verbose)) and $vb = 1;

$getRA = 0;
$getDec = 0;
(defined($ra)) or ($getRA = 1);
(defined($dec)) or ($getDec = 1);

$sensible=0;
(defined($outfile)) or ($sensible = 1);

# Check for imcat environment:

(defined($ENV{"IMCATDIR"})) or die "TRANSFORM_CAT_TO_WCS: Imcat environment undefined.\n"; 
# $dir = '/u/ki/pjm/imcat/bin/linux/';
$dir = $ENV{"IMCATDIR"};

# Check for existence of catalogue:

$catfile = shift @ARGV;
(-e $catfile) or die "TRANSFORM_CAT_TO_WCS: Catalogue $catfile not found.\n";

# Check for existence of FITS image associated with catalogue:

chomp($fitsfile = `lc -p fits_name < $catfile | cut -b2-100`);
print STDERR "FITS file = $fitsfile\n";
($fitsfile eq "") and die "TRANSFORM_CAT_TO_WCS: No FITS image associated with catalogue.\n";
(-e $fitsfile) or die "TRANSFORM_CAT_TO_WCS: $fitsfile not found.\n";

# Output filename:

if ($sensible == 1) {
  $root = $catfile;
  $root =~ s/(.*)\..*/$1/;
  $outfile = $root.".WCS.cat";
}

# Get WCS information:

chomp($CRVAL1 = `$dir/imhead -v CRVAL1 < $fitsfile`);
if ($getRA == 1) {
  $ra = $CRVAL1;
}
chomp($CRVAL2 = `$dir/imhead -v CRVAL2 < $fitsfile`);
if ($getDec == 1) {
  $dec = $CRVAL2;
}
chomp($CRPIX1 = `$dir/imhead -v CRPIX1 < $fitsfile`);
chomp($CRPIX2 = `$dir/imhead -v CRPIX2 < $fitsfile`);
chomp($CD1_1 = `$dir/imhead -v CD1_1 < $fitsfile`);
chomp($CD1_2 = `$dir/imhead -v CD1_2 < $fitsfile`);
chomp($CD2_1 = `$dir/imhead -v CD2_1 < $fitsfile`);
chomp($CD2_2 = `$dir/imhead -v CD2_2 < $fitsfile`);
print STDERR "CRVAL1 = $CRVAL1\n";
print STDERR "CRVAL2 = $CRVAL2\n";
print STDERR "CRPIX1 = $CRPIX1\n";
print STDERR "CRPIX2 = $CRPIX2\n";
print STDERR "CD1_1 = $CD1_1\n";
print STDERR "CD1_2 = $CD1_2\n";
print STDERR "CD2_1 = $CD2_1\n";
print STDERR "CD2_2 = $CD2_2\n";

# Use this information to compute RA and Dec of each object, and also 
# the offset in arcseconds from the specified field centre.
# RA and Dec agree with those from getwcsinfo to < 10" in RA, < 0.01" 
# in Dec, source of disagreement unknown. WCS transform in FITS file is 
# good for centre of field only probably.

&esystem("lc -x +all -H 'RA = $ra' -H 'Dec = $dec' < $catfile |
lc -x +all 'pixoff = %x[0] $CRPIX1 - %x[1] $CRPIX2 - 2 vector' |
lc -x +all 'ra = %pixoff[0] $CD1_1 * %pixoff[1] $CD1_2 * + $CRVAL1 +' 'dec = %pixoff[0] $CD2_1 * %pixoff[1] $CD2_2 * + $CRVAL2 +' |
lc -x +all 'xoff = %ra $ra - -3600.0 * %dec $dec - 3600.0 * 2 vector' |
lc -x +all -r pixoff -a 'history: WCS transformation applied by transform_cat_to_wcs: .pl' > junk",$doproc,$vb);

# Now rotate gamma values too - need to know rotation angle:

# $detCD = 3600*$CD1_1*3600*$CD2_2 - 3600*$CD1_2*3600*$CD2_1;
# $detCD = sqrt(abs($detCD));
# $dphi1 = 3600*$CD1_1/$detCD;
# $dphi1 = acos($dphi1);
# $dphi2 = 3600*$CD2_1/$detCD;
# $dphi2 = asin($dphi2);
# # $dphi = 0.5*($dphi1 + $dphi2) + 1.570796327;
# $dphi = 3.141592654 - 0.5*($dphi1 + $dphi2);
# # $dphi = 0.5*($dphi1 + $dphi2);
# $dphierr = 0.5*abs($dphi1 - $dphi2);
# print STDERR "dphi = $dphi +/- $dphierr\n";
$dphi = 3.141592654 - 0.5*atan2($CD2_1,$CD1_1);
print STDERR "dphi = $dphi\n";

&esystem("lc -x +all 'modgamma = %gamma %gamma dot sqrt' 'twophigamma = %gamma[1] %gamma[0] atan2 ' < junk |
lc -x +all 'phigamma = %twophigamma 6.283185307 + %twophigamma %twophigamma 0 < ? 0.5 *' |
lc -x +all 'rotphigamma = %phigamma $dphi +' |
lc -x +all 'rotgamma1 = %rotphigamma 2.0 * cos %modgamma *' 'rotgamma2 = %rotphigamma 2.0 * sin %modgamma *' | 
lc -x +all 'rotgamma = %rotgamma1 %rotgamma2 2 vector' |
lc -x +all -r modgamma -r twophigamma -r phigamma -r rotphigamma -r rotgamma1 -r rotgamma2 > $outfile",$doproc,$vb);

#=======================================================================

sub acos { atan2( sqrt(1.0 - $_[0] * $_[0]), $_[0] ) }
sub asin { atan2($_[0], sqrt(1.0 - $_[0] * $_[0] ) ) } 

#=======================================================================














