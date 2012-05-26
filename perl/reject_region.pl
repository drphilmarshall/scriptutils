#!/usr/local/bin/perl -w
# ======================================================================
#+
$usage = "

NAME
        mkreg.pl

PURPOSE
        Mask catalogue using ds9 regions file.

USAGE
        reject_region.pl [flags] {options] mask.reg \$project.cat

FLAGS
        -u              print this message
        -i              accept sources in region instead

INPUTS
        mask.reg        ds9 region file specifying mask
        \$project.cat    catalogue to be masked

OPTIONAL INPUTS
        -o file         write output to \"file\" (def=STDOUT)
        -x xcol         column number of x values (def=1)
        -y ycol         column number of y values (def=2)
        -n name         ignore e.g. circles (otherwise only ellipses

OUTPUTS
        STDOUT          Filtered catalogue

COMMENTS

EXAMPLES

BUGS
  - esystem verbosity hard coded to zero

REVISION HISTORY:
  2005-07-01  Started Marshall (KIPAC)
  2007-06-26  Added DS9 v4.0 support - Applegate (KIPAC)

\n";
#-
# ======================================================================

$sdir = $ENV{'SCRIPTUTILS_DIR'};
require($sdir."/perl/esystem.pl");
require($sdir."/perl/polygon.pl");
$doproc = 1;
use Getopt::Long;
GetOptions("o=s", \$outfile,
           "x=f", \$xcol,
           "y=f", \$ycol,
           "i", \$invert,
	   "n=s", \$ignorereg,
           "u", \$help
          );

(defined($help)) and die "$usage\n";
$num=@ARGV;
($num==2) or die "$usage\n";

$flush=0;
(defined($outfile)) or ($flush = 1);

(defined($xcol)) or ($xcol = 1);
(defined($ycol)) or ($ycol = 2);
(defined($ignorereg)) or ($ignorereg = "bla");

# Check for imcat environment:

(defined($ENV{"IMCAT_DIR"})) or die "Imcat environment undefined.\n";

# Read in regions: ignore ellipses (and others)!:

$regionfile = shift;
open (REG, $regionfile) or die "Couldn't open $regionfile: $!";
$icirc = $ibox = $ipoly = $iann = $iellipse = 0;
while (<REG>){

    next if (/^\#/ or /^$/ or /^global/);
    
    /(image;)?(.*)\((.*)\)/;
    $regtype = $2;
    $regparam = $3;

    next if (!$regtype or !$regparam);
    if ($regtype eq "circle"){
	if ($ignorereg ne "circle"){
	    ($circ_x[$icirc], $circ_y[$icirc], $circ_r[$icirc])
		= split(',', $regparam);
	}
	$icirc++;
	next;
    } elsif ($regtype eq "annulus"){
	if ($ignorereg ne "annulus"){
	    ($ann_x[$iann], $ann_y[$iann], $ann_r1[$iann], $ann_r2[$iann])
		= split(',', $regparam);
	}
	$iann++;
	next;
    } elsif ($regtype eq "ellipse"){
      $iellipse++;
      next;
    } elsif ($regtype eq "box") {
	if ($ignorereg ne "box"){
	    ($box_x[$ibox], $box_y[$ibox], $box_dx[$ibox], $box_dy[$ibox])
		= split(',', $regparam);
	    $box_dx[$ibox] /= 2;   # need half box sizes in check
	    $box_dy[$ibox] /= 2;
	}
	$ibox++;
	next;
    } elsif ($regtype eq "polygon"){
	if ($ignorereg ne "polygon"){	
	    @polyvert = split(',', $regparam);
	    $nvert[$ipoly] = @polyvert/2;
	    for ($ivert=0; $ivert<$nvert[$ipoly]; $ivert++){
		$$poly_x[$ipoly][$ivert] = $polyvert[2*$ivert];
		$$poly_y[$ipoly][$ivert] = $polyvert[2*$ivert+1];
	    }

	    $$poly_x[$ipoly][$nvert[$ipoly]] = $polyvert[0];
	    $$poly_y[$ipoly][$nvert[$ipoly]] = $polyvert[1];
	}
      $ipoly++;
      next;
#    } else {
#     die "Unknown regions type: $regtype\n";
    }
}
close(REG);

$ncirc = @circ_x;
$nann = @ann_x;
$nbox = @box_x;
$npoly = $ipoly;

print STDERR "Regions file $regionfile:\n";
print STDERR "    Circles:  $ncirc\n";
if ($ignorereg eq "circle"){
    print STDERR "    Circles (ignored):  $icirc\n";
}
print STDERR "    Annuli:   $nann\n";
if ($ignorereg eq "annuli"){
    print STDERR "    Annuli (ignored):  $iann\n";
}
print STDERR "    Boxes:    $nbox\n";
if ($ignorereg eq "box"){
    print STDERR "    Boxes (ignored):  $ibox\n";
}
print STDERR "    Polygons: $npoly\n";
if ($ignorereg eq "polygon"){
    print STDERR "    Polygons (ignored):  $ipoly\n";
}
print STDERR "    Ellipses (ignored): $iellipse\n";

# Read input catalogue one line at a time, copying header lines and
# filtering according to regions:

$k = 1;

while (defined($cat = shift)){
    $cat =~ /(.*)\..*/;
    $junk = "$cat.junk";
    open(CAT, $cat) or die "$cat: $!";
    open(OUT, ">$junk") or die "$junk: $!";
    $iread = 0;
    $ikept = 0;
    OBJECT: while (<CAT>){
      if (/^\#/ or /^$/){
        print OUT $_;
        next OBJECT;
      }
      $iread++;
      ($xobj, $yobj) = (split)[$xcol,$ycol];
      $flag = 0;
      for ($i = 0; $i<$ncirc; $i++){
        (check_circle($xobj, $yobj,
                  $circ_x[$i], $circ_y[$i], $circ_r[$i])
         == $k) and $flag = 1;
      }
      for ($i = 0; $i<$nann; $i++){
        (check_annulus($xobj, $yobj,
                  $ann_x[$i], $ann_y[$i], $ann_r1[$i], $ann_r2[$i])
         == $k) and $flag = 1;
      }
      for ($i=0; $i<$nbox; $i++){
        (check_box($xobj, $yobj,
                 $box_x[$i], $box_y[$i], $box_dx[$i], $box_dy[$i])
         == $k) and $flag = 1;
      }
      for ($i=0; $i<$npoly; $i++){
        (is_in_polygon($xobj, $yobj, $nvert[$i]+1, $$poly_x[$i], $$poly_y[$i])
         == $k ) and $flag = 1;
      }
      if (defined($invert)) {
        if ($flag == 1){
          print OUT $_;
          $ikept++;
        }
      } else {
        if ($flag == 0){
          print OUT $_;
          $ikept++;
        }
      }
  }
  close (CAT);
  close (OUT);
  print STDERR "$cat: $iread objects scanned, $ikept objects kept.\n";
}

# Do output, using lc to add a header line:

if ($flush == 1) {
  &esystem("lc -x -a history:\\ masked\\ with\\ \\$regionfile\\ by\\ reject_regions.pl < $junk", $doproc, 0);
} else {
  &esystem("lc -x -a history:\\ masked\\ with\\ \\$regionfile\\ by\\ reject_regions.pl < $junk > $outfile", $doproc, 0);
}

# Clean up and finish:

&esystem("rm $junk", $doproc, 0);

#=======================================================================

sub check_circle{
    my ($xobj, $yobj, $x0, $y0, $r) = @_;
    my ($dx, $dy);

    (($dx = abs($xobj - $x0)) > $r) and (return 0);
    (($dy = abs($yobj - $y0)) > $r) and (return 0);
    ($dx*$dx+$dy*$dy > $r*$r) and (return 0);

    return 1;
}

#-----------------------------------------------------------------------

sub check_annulus{
    my ($xobj, $yobj, $x0, $y0, $r1, $r2) = @_;
    my ($dx, $dy, $rr);

    $dx = abs($xobj - $x0);
    $dy = abs($yobj - $y0);
    $rr = sqrt($dx*$dx+$dy*$dy);
    $dx = abs($xobj - $x0);
    ($dx > $r2) and (return 0);
    $dy = abs($yobj - $y0);
    ($dy > $r2) and (return 0);
    $rr = sqrt($dx*$dx+$dy*$dy);
    ($rr > $r2) and (return 0);
    ($rr < $r1) and (return 0);

    return 1;
}

#-----------------------------------------------------------------------

sub check_box{
    my ($xobj, $yobj, $x0, $y0, $dx, $dy) = @_;

    (abs($xobj - $x0) > $dx) and (return 0);
    (abs($yobj - $y0) > $dy) and (return 0);

    return 1;
}

#=======================================================================



