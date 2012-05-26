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
        -v        Verbose output
        -r        Random catalog (not for weak lensing)

INPUTS
        input.scat      ASCII_HEAD catalogue from SExtractor, this version
                        will figure out all the variables itself

OPTIONAL INPUTS
        -o file         write output to \"file\" (def=STDOUT)
        -f file         corresponding image fits file (def=input.fits)
        -z magzero      photometric zero point used by SExtractor
        --n1 --n2       start and stop of the column for name

OUTPUTS
        STDOUT          Filtered catalogue

COMMENTS

EXAMPLES

BUGS
  - Horrible hard-coding of various catalogue styles...

REVISION HISTORY:
  2003-05-??  Started Marshall (MRAO)
  2005-12-21  Added pat format.
  29-June-2006 16:48 Marusa decided to fix the bug

\n";
#-
# ======================================================================
sub trimwhitespace($);
sub trimwhitespace($)
{
        my $string = shift;
        $string =~ s/^\s+//;
        $string =~ s/\s+$//;
        return $string;
}

$sdir = $ENV{'SCRIPTUTILS_DIR'};
require($sdir."/perl/esystem.pl");
$doproc = 1;

use Getopt::Long;
GetOptions("o=s", \$outfile,
           "f=s", \$fitsfile,
           "z=f", \$zp,
	   "r", \$random,
           "v", \$vb,       
	   "n1=f", \$n1,       
	   "n2=f", \$n2,        
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


# Check for existence of catalogue:

$scatfile = shift @ARGV;
(-e $scatfile) or die "sex2imcat: $scatfile not found.\n";
($vb) and print STDERR "Using SExtractor catalogue file $scatfile\n";

$junk = "$scatfile.junk";
print "$junk\n";

# Set fits file name if required:

if ($sensible == 1) {
  $fitsfile = $scatfile;
  $fitsfile =~ s/(.*)\..*/$1\.fits/;
  ($fitsfile ne $scatfile) or die "Input file extension must be .scat\n";
}

# Check for existence of fits file:

(-e $fitsfile) or print  STDERR "sex2imcat: $fitsfile not found.\n";
($vb) and print STDERR "Using fits file $fitsfile\n";

# Extract image size:
$fitsline = " ";
if (-e $fitsfile) {
($vb) and print STDERR "Extracting image size...\n";
chomp($xs = `stats -v N1 < $fitsfile`);
chomp($ys = `stats -v N2 < $fitsfile`);
($vb) and print STDERR "...file is $xs by $ys.\n";

# Extract photometric zero point:


($vb) and print STDERR "Sorting out zero point...\n";
if ($getzp == 1) {
  chomp($zp = `imhead -v PHOTOZP < $fitsfile`);
}
($vb) and print STDERR "...zero point is $zp.\n";
$fitsline =  "-H 'fits_name = {$fitsfile}' -H 'fits_size = $xs $ys 2 vector' -H 'has_sky = 0' -H 'magzero = $zp'" 
}
#Do imcat conversion:

($vb) and print STDERR "Cranking up imcat and figuring out which variables we use \n";

  open (IN, $scatfile) or die "$scatfile: $!";
@keywords =();
$keys = 1;
$imcatline = "";
$id = 0;
defined($n1) or $n1 = 6;
defined($n2) or $n2 = 15;
$idold=0;
while (defined($inline = <IN>) and ($keys)) {
    if ($inline =~ /^\#/){
	chomp($inline);
	$ls=length($inline);
	$rest=$ls - 70;
	if (defined($random)) {
	    $id++;
	    (($ls > 21) and ($name = trimwhitespace(substr($inline, $n1, $n2)))) or ($name = " ");
	    $desc = " ";  $units = " "; 
	}
	else{
	    (($ls > 5) and ($id = trimwhitespace(substr($inline, 2, 3)))) or ($id = 0);
	    (($ls > 21) and ($name = trimwhitespace(substr($inline, 6, 15)))) or ($name = " ");
	    (($ls > 69) and ($desc = trimwhitespace(substr($inline, 21, 48)))) or ($desc = " ");
	    (($ls > 70) and ($units = trimwhitespace(substr($inline, 70, $rest)))) or ($units = " ");
	}
	$count = 2; 
	while (($id-$idold) > 1){
	    push @keywords,{id => $idold, name =>  $nameold.$count, desc =>  $descold, units => $unitsold}; 
	    $idold++;
	    $imcatline = $imcatline." -n $nameold$count ";
	    $count++;
	    print STDERR "$id $nameold.$count  $unitsold $descold\n";
	}
	print STDERR "$id $name $units $desc\n";
	push @keywords,{id => $id, name =>  $name, desc =>  $desc, units => $units};
	$nameold = $name; $descold=$desc; $unitsold=$units; $idold = $id;
	$imcatline = $imcatline." -n $name "; 
    }
    else { $keys = 1;}
}

if (defined($random)) {
  &esystem("lc -C -L 0 -x -a {history:\\ Converted\\ from\\ SExtractor\\ with\\ sex2imcat.pl}  $imcatline < $scatfile  > $junk", $doproc, 1);
  print STDERR "$imcatline\n";
}
else {
  &esystem("lc -C -L 0 -x -a {history:\\ Converted\\ from\\ SExtractor\\ with\\ sex2imcat.pl}  $imcatline < $scatfile  | lc  'id = %NUMBER' 'x = %X_IMAGE %Y_IMAGE 2 vector' 'fwhm = %FWHM_IMAGE' 'star = %CLASS_STAR' 'a = %A_IMAGE' 'b = %B_IMAGE' 'th = %THETA_IMAGE' 'smag = %MAG_BEST' 'flags = %FLAGS' +all ${fitsline} | lc +all 'x = \%x 0.5 0.5 2 vector vsub' | lc -x -a history:\\ SExtractor\\ ellipticities\\ added\\ by\\ sex2imcat.pl +all 'es = \%a \%b - 0.034906585 \%th * cos * \%a \%b + / \%a \%b - 0.034906585 \%th * sin * \%a \%b + / 2 vector' > $junk", $doproc, 0);
}


#Do output:

($vb) and print STDERR "Outputting:...\n";
if ($flush == 1) {
  &esystem("cat $junk", $doproc, $vb);
  &esystem("rm $junk", $doproc, $vb);
} else {
  &esystem("mv $junk $outfile", $doproc, $vb);
}

# ======================================================================
