#!/usr/local/bin/perl -w
# ======================================================================
#+
$usage = "

NAME
        sex2imcat.pl

PURPOSE
        Convert a SExtractor catalogue into imcat format.

USAGE
        sex2imcat.pl [flags] [options] input.scat

FLAGS
        -u        print this message
        -m        assume Massey format
        -h        assume Hudelot format
        -p        assume Phil format
        -pat      assume Pat format
        -s        assume stars.param format
        -H        assume HAGGLeS format
        -bpz      assume BPZ format
        -v        Verbose output

INPUTS
        input.scat      ASCII_HEAD catalogue from SExtractor

OPTIONAL INPUTS
        -o file         write output to \"file\" (def=STDOUT)
        -f file         corresponding image fits file (def=input.fits)
        -z magzero      photometric zero point used by SExtractor

OUTPUTS
        STDOUT          Filtered catalogue

COMMENTS

EXAMPLES

BUGS
  - Horrible hard-coding of various catalogue styles...

REVISION HISTORY:
  2003-05-??  Started Marshall (MRAO)
  2005-12-21  Added pat format.

\n";
#-
# ======================================================================

$sdir = $ENV{'SCRIPTUTILS_DIR'};
require($sdir."/perl/esystem.pl");
$doproc = 1;

use Getopt::Long;
GetOptions("o=s", \$outfile,
           "f=s", \$fitsfile,
           "z=f", \$zp,
           "m", \$massey,
           "h", \$hudelot,
           "p", \$phil,
           "pat", \$pat,
           "s", \$stars,
           "HAGGLeS", \$haggles,
           "bpz", \$bpz,
           "v", \$vb,       
           "u", \$help       
           );

(defined($help)) and die "$usage\n";
$num=@ARGV;
($num>0) or die "$usage\n";

if (defined($vb)){
$vb = 1;
} else {
$vb = 0;
}

$flush=0;
(defined($outfile)) or ($flush = 1);
$sensible=0;
(defined($fitsfile)) or ($sensible = 1);
$getzp=0;
(defined($zp)) or ($getzp = 1);

($vb) and print STDERR "Doing checks...\n";
# Check for imcat environment:

(defined($ENV{"IMCAT_DIR"})) or die "Imcat environment undefined.\n";

# Check for existence of catalogue:

$scatfile = shift @ARGV;
(-e $scatfile) or die "sex2imcat: $scatfile not found.\n";
($vb) and print STDERR "Using SExtractor catalogue file $scatfile\n";

# Set fits file name if required:

if ($sensible == 1) {
  $fitsfile = $scatfile;
  $fitsfile =~ s/(.*)\..*/$1\.fits/;
  ($fitsfile ne $scatfile) or die "Input file extension must be .scat\n";
}

# Check for existence of fits file:

( (defined($bpz)) or (-e $fitsfile)) or die "sex2imcat: $fitsfile not found.\n";
(not defined($bpz) and $vb) and print STDERR "Using fits file $fitsfile\n";

# Extract image size:

if ( not defined($bpz)){
($vb) and print STDERR "Extracting image size...\n";
chomp($xs = `stats -v N1 < $fitsfile`);
chomp($ys = `stats -v N2 < $fitsfile`);
($vb) and print STDERR "...file is $xs by $ys.\n";
}

# Extract photometric zero point:

if ( not defined($bpz)){
($vb) and print STDERR "Sorting out zero point...\n";
if ($getzp == 1) {
  chomp($zp = `/u/ki/pjm/imcat/bin/linux/imhead -v PHOTOZP < $fitsfile`);
}
# $zp = 30.8;
($vb) and print STDERR "...zero point is $zp.\n";
}

#Do imcat conversion:

($vb) and print STDERR "Cranking up imcat...\n";

if (defined($stars)) {

  &esystem("lc -C -L 0 -x -a {history:\\ Converted\\ from\\ SExtractor\\ with\\ sex2imcat.pl}  -N '1 2 x' -N '1 2 xp' -N '1 2 xmin' -N '1 2 xmax' -n a -n b -n th -n star -n fwhm -n smag -n sflux -n sarea -n id < $scatfile | lc -x id x fwhm star a b th smag -H 'fits_name = {$fitsfile}' -H 'fits_size = $xs $ys 2 vector' -H 'has_sky = 0' -H 'magzero = $zp' | lc +all 'x = \%x 0.5 0.5 2 vector vsub' | lc -x -a history:\\ SExtractor\\ ellipticities\\ added\\ by\\ massey-sex2imcat.pl +all 'es = \%a \%b - 0.034906585 \%th * cos * \%a \%b + / \%a \%b - 0.034906585 \%th * sin * \%a \%b + / 2 vector'  > junk", $doproc, 0);

} elsif (defined($massey)) {

  &esystem("lc -C -L 0 -x -a {history:\\ Converted\\ from\\ SExtractor\\ with\\ sex2imcat.pl}  -N '1 2 x' -N '1 2 xp' -N '1 2 xmin' -N '1 2 xmax' -n a -n b -n th -n star -n fwhm -n smag -n sflux -n sarea -n id -N '1 6 junk' < $scatfile | lc -x id x fwhm star a b th smag -H 'fits_name = {$fitsfile}' -H 'fits_size = $xs $ys 2 vector' -H 'has_sky = 0' -H 'magzero = $zp' | lc +all 'x = \%x 0.5 0.5 2 vector vsub' | lc -x -a history:\\ SExtractor\\ ellipticities\\ added\\ by\\ massey-sex2imcat.pl +all 'es = \%a \%b - 0.034906585 \%th * cos * \%a \%b + / \%a \%b - 0.034906585 \%th * sin * \%a \%b + / 2 vector'  > junk", $doproc, 0);

} elsif (defined($hudelot)) {

  &esystem("lc -C -L 0 -x -a {history:\\ Converted\\ from\\ SExtractor\\ with\\ sex2imcat.pl} -n id -N '1 3 junk' -n sflux -n smag -n smagerr -n junk2 -N '1 2 x' -N '1 3 junk3' -n a -n b -n flags  < $scatfile  | lc -x id x 'fwhm = \%a \%b * sqrt' 'star = 0.0' a b 'th = 0.0' smag -H 'fits_name = {$fitsfile}' -H 'fits_size = $xs $ys 2 vector' -H 'has_sky = 0' -H 'magzero = $zp' | lc +all 'x = \%x 0.5 0.5 2 vector vsub' | lc -x -a history:\\ SExtractor\\ ellipticities\\ added\\ by\\ massey-sex2imcat.pl +all 'es = \%a \%b - 0.034906585 \%th * cos * \%a \%b + / \%a \%b - 0.034906585 \%th * sin * \%a \%b + / 2 vector'  > junk", $doproc, 0);

} elsif (defined($phil)) {

  &esystem("lc -C -L 0 -x -a {history:\\ Converted\\ from\\ SExtractor\\ with\\ sex2imcat.pl} -n id  -N '1 2 x' -n star -n fwhm -n a -n b -n th -n smag -n flags  < $scatfile  | lc -x id x fwhm star a b th smag flags -H 'fits_name = {$fitsfile}' -H 'fits_size = $xs $ys 2 vector' -H 'has_sky = 0' -H 'magzero = $zp' | lc +all 'x = \%x 0.5 0.5 2 vector vsub' | lc -x -a history:\\ SExtractor\\ ellipticities\\ added\\ by\\ sex2imcat.pl +all 'es = \%a \%b - 0.034906585 \%th * cos * \%a \%b + / \%a \%b - 0.034906585 \%th * sin * \%a \%b + / 2 vector'  > junk", $doproc, 0);

} elsif (defined($pat)) {

  &esystem("lc -C -L 0 -x -a {history:\\ Converted\\ from\\ SExtractor\\ with\\ sex2imcat.pl} -n id  -N '1 2 x' -n xmin -n xmax -n ymin -n ymax -n star -n fwhm -n a -n b -n th -n smag -n smagerr -n magaper -n magerraper -n magiso -n magerriso -n flags -n alpha -n delta < $scatfile  | lc -x id x xmin xmax ymin ymax fwhm star a b th smag smagerr magaper magerraper magiso magerriso flags alpha delta -H 'fits_name = {$fitsfile}' -H 'fits_size = $xs $ys 2 vector' -H 'has_sky = 0' -H 'magzero = $zp' | lc +all 'x = \%x 0.5 0.5 2 vector vsub' | lc -x -a history:\\ SExtractor\\ ellipticities\\ added\\ by\\ sex2imcat.pl +all 'es = \%a \%b - 0.034906585 \%th * cos * \%a \%b + / \%a \%b - 0.034906585 \%th * sin * \%a \%b + / 2 vector'  > junk", $doproc, 0);

} elsif (defined($haggles)) {

  &esystem("lc -C -L 0 -x -a {history:\\ Converted\\ from\\ SExtractor\\ with\\ sex2imcat.pl} -n id  -N '1 2 x' -n a -n b -n th -n mumax -n smag -n smagerr  < $scatfile  | lc -x id x a b th mumax smag smagerr  -H 'fits_name = {$fitsfile}' -H 'fits_size = $xs $ys 2 vector' -H 'has_sky = 0' -H 'magzero = $zp' | lc +all 'x = \%x 0.5 0.5 2 vector vsub' | lc -x -a history:\\ SExtractor\\ ellipticities\\ added\\ by\\ sex2imcat.pl +all 'es = \%a \%b - 0.034906585 \%th * cos * \%a \%b + / \%a \%b - 0.034906585 \%th * sin * \%a \%b + / 2 vector'  > junk", $doproc, 0);

} elsif (defined($bpz)) {

#  &esystem("lc -C -L 0 -x -a {history:\\ Converted\\ from\\ BPZ\\ with\\ sex2imcat.pl} -n id -n zb -n zbmin -n zbmax -n Tb -n odds -n zml -n Tml -n chisq < $scatfile > junk", $doproc, 0);

  &esystem("lc -C -L 0 -x -a {history:\\ Converted\\ from\\ BPZ\\ with\\ sex2imcat.pl} -n id_bpz -n zb_aper -n zbmin_aper -n zbmax_aper -n Tb_aper -n odds_aper -n zml_aper -n Tml_aper -n chisq_aper -n zb_auto -n zbmin_auto -n zbmax_auto -n Tb_auto -n odds_auto -n zml_auto -n Tml_auto -n chisq_auto  -n zb_iso -n zbmin_iso -n zbmax_iso -n Tb_iso -n odds_iso -n zml_iso -n Tml_iso -n chisq_iso < $scatfile > junk", $doproc, 0);

} else {

($vb) and print STDERR "No sex catalogue defined, defaulting to Phil's format.\n";

  &esystem("lc -C -L 0 -x -a {history:\\ Converted\\ from\\ SExtractor\\ with\\ sex2imcat.pl} -n id  -N '1 2 x' -n star -n fwhm -n a -n b -n th -n smag -n flags  < $scatfile  | lc -x id x fwhm star a b th smag flags -H 'fits_name = {$fitsfile}' -H 'fits_size = $xs $ys 2 vector' -H 'has_sky = 0' -H 'magzero = $zp' | lc +all 'x = \%x 0.5 0.5 2 vector vsub' | lc -x -a history:\\ SExtractor\\ ellipticities\\ added\\ by\\ sex2imcat.pl +all 'es = \%a \%b - 0.034906585 \%th * cos * \%a \%b + / \%a \%b - 0.034906585 \%th * sin * \%a \%b + / 2 vector'  > junk", $doproc, 0);

}

#Do output:

($vb) and print STDERR "Outputting:...\n";
if ($flush == 1) {
  &esystem("cat junk", $doproc, $vb);
  &esystem("rm junk", $doproc, $vb);
} else {
  &esystem("mv junk $outfile", $doproc, $vb);
}

# ======================================================================


