#!/usr/local/bin/perl -w
# ======================================================================
#+
$usage = "

NAME
        shearprofile.pl

PURPOSE
        Read in an object catalogue, offset it and compute tangential shear.
        Also compute tangential shear after rotating the galaxies by
        45 degrees (the 'B modes'). Bin the galaxies according to some scheme
        and output the shear profiles as 3 column text (x,y,e).


USAGE
        shearprofile.pl [flags] [options] \$project.cat \$other.cat ...

FLAGS
        -errors   Include error propagation
        -u        Print this message
        -h        Ignore catalogue header (marked with \#)

INPUTS
        \$project.cat   Object catalogue (multi-column text)
        \$other.cat     Another object catalogue (multi-column text)

OPTIONAL INPUTS
        -oE     Efile   Write output to \"file\" (def=\$project.Eprofile.txt)
        -oB     Bfile   Write output to \"file\" (def=\$project.Bprofile.txt)
        -cx       f     X position of cluster center
        -cy       f     Y position of cluster center
        -rmin     f     Minimum radius [0.0]
        -rmax     f     Maximum radius [10.0]
        -nbin     i     No. of radius bins [20.0]
        -xcol     i     Use ith column for x positions (def=0)
        -ycol     i     Use ith column for y positions (def=1)
        -e1col    i     Use ith column for e1 (def=-4)
        -e1errcol i     Use ith column for e1err (def=-3)
        -e2col    i     Use ith column for e2 (def=-2)
        -e2errcol i     Use ith column for e2err (def=-1)
        -lc             Output in lc catalog format

OUTPUTS
        \$project.Eprofile.txt     or explicitly named output catalogue file
        \$project.Bprofile.txt

OPTIONAL OUTPUTS

COMMENTS

EXAMPLES

BUGS
 - no option to reduce verbosity

REVISION HISTORY:
  2006-07-26 Started Marshall (KIPAC)
  2007-05-30 Added cluster center offset, changed to arbitrary coords Applegate (KIPAC)

\n";
#-
# ======================================================================

# $\="\n";

use Getopt::Long;
GetOptions("oE=s", \$Eoutfile,
           "oB=s", \$Boutfile,
	   "cx=f", \$cx,
	   "cy=f", \$cy,
           "rmin=f", \$rmin,
           "rmax=f", \$rmax,
           "nbin=i", \$nbin,
           "xcol=i", \$xcol,
           "ycol=i", \$ycol,
           "e1col=i", \$e1col,
           "e2col=i", \$e2col,
           "e1errcol=i", \$e1errcol,
           "e2errcol=i", \$e2errcol,
           "errors", \$errors,
           "h", \$header,
           "u", \$help,
	   "lc", \$lc
           );

(defined($help)) and die "$usage\n";
$num=@ARGV;
($num == 0) and die "$usage\n";

$sensible = 0;
(defined($Eoutfile)) or ($sensible = 1);
($num>1) and $sensible=1;

# Default column numbers:
(defined($xcol)) or ($xcol = 0);
(defined($ycol)) or ($ycol = 1);
(defined($e1col)) or ($e1col = -4);
(defined($e1errcol)) or ($e1errcol = -3);
(defined($e2col)) or ($e2col = -2);
(defined($e2errcol)) or ($e2errcol = -1);

# Default binning parameters:
(defined($cx)) or ($cx = 0);
(defined($cy)) or ($cy = 0);
(defined($rmin)) or ($rmin = 0.0);
#$rmin = $rmin*60.0; 
(defined($rmax)) or ($rmax = 10.0);
#$rmax = $rmax*60.0; 
(defined($nbin)) or ($nbin = 20);
$dr = ($rmax - $rmin) / $nbin;



# Loop over catalogues:

while (defined($file = shift)){

# Set up binning grid:

    for ($i = 0; $i < $nbin; $i++){
      $rbin[$i] = $dr * ($i + 0.5);
      $Ebin[$i] = 0.0;
      $Ebinerr[$i] = 0.0;
      $Bbin[$i] = 0.0;
      $Bbinerr[$i] = 0.0;
    }

    open (IN, $file) or die "$file: $!";
    print STDERR "\nReading data from $file \n";

# Sort out sensible filename:
    if ($sensible) {
       $root = $file;
       $root =~ s/(.*)\..*/$1/;
       $Eoutfile = $root.".Eprofile.txt";
       $Boutfile = $root.".Bprofile.txt";
    }

# Count objects:
    $count = 0;
    $headcount = 0;

    (defined($header)) and (<IN>);
# Step through lines of catalogue,
    while (<IN>){
      $headcount ++;
      next if ($headcount < 7);
      chomp;
# dealing with header lines,
      if (/^\#/ or /^$/){
        next;
      } else {
        @line = split;
      }
# and working out appropriate object information:

# First get all the quantities:
      $x = $line[$xcol];
      $y = $line[$ycol];
      $e1 = $line[$e1col];
      $e2 = $line[$e2col];

      if (defined($errors)){
        $e1err = $line[$e1errcol];
        $e2err = $line[$e2errcol];
      }

# First compute radius and hence bin number:
      $xrel = $x - $cx;
      $yrel = $y - $cy;
      $r = sqrt($xrel*$xrel + $yrel*$yrel);
      $i = int(($r - $rmin) / $dr);
	$phi = atan2($yrel,$xrel);
      $cos2phi = cos(2.0*$phi);
      $sin2phi = sin(2.0*$phi);

# Calculate tangential shear and add it to the (weighted) sum:     
      
	$E = -($e1*$cos2phi+$e2*$sin2phi);
      if (defined($errors)){
        $w = 1.0/($e1err*$e1err*$cos2phi*$cos2phi + $e2err*$e2err*$sin2phi*$sin2phi);
        $Ebin[$i] += $E*$w; 
        $Ebinerr[$i] += $w; 
#         print STDERR "r, i, phi, cos2phi, sin2phi, E: $r, $i, $phi, $cos2phi, $sin2phi, $E\n";
#         print STDERR "w, Ebin, Ebinerr: $w, $Ebin[$i], $Ebinerr[$i]\n";
      } else {
        $nbin[$i] ++; 
        $Ebin[$i] += $E; 
        $Ebinerr[$i] += $E*$E; 
      }
           
# Now rotate ellipticity by 45 degrees:

	$b1 =  $e2;
      $b2 = -$e1;
      
      $B = -($b1*$cos2phi+$b2*$sin2phi);
      if (defined($errors)){
        $w = 1.0/($e2err*$e2err*$cos2phi*$cos2phi + $e1err*$e1err*$sin2phi*$sin2phi);
        $Bbin[$i] += $B*$w; 
        $Bbinerr[$i] += $w; 
      } else {
        $Bbin[$i] += $B; 
        $Bbinerr[$i] += $B*$B; 
      }
     
      $count++;

    }
    close(IN);
    print STDERR "$count objects processed\n";


# Now work out averages and errors and finish!
# Open output files:
    if (defined($lc)){
	open (EOUT, "| lc -C -n x -n y -n e > $Eoutfile") or die "can't fork: $!";
	open (BOUT, "| lc -C -n x -n y -n e > $Boutfile") or die "can't fork: $!";
    } else {
	open (EOUT, ">$Eoutfile") or die "Couldn't open $Eoutfile: $!";
	open (BOUT, ">$Boutfile") or die "Couldn't open $Boutfile: $!";
    }

    for ($i = 0; $i < $nbin; $i++){
      if (defined($errors)){
        if ($Ebinerr[$i] > 0.0){
          $Ebin[$i] = $Ebin[$i] / $Ebinerr[$i];
          $Ebinerr[$i] = sqrt(1.0 / $Ebinerr[$i]);
          $Bbin[$i] = $Bbin[$i] / $Bbinerr[$i];
          $Bbinerr[$i] = sqrt(1.0 / $Bbinerr[$i]);
        }
      } else {
        if ($nbin[$i] > 0.0){
          $Ebin[$i] = $Ebin[$i] / $nbin[$i];
          $Ebinerr[$i] = sqrt($Ebinerr[$i] / $nbin[$i] - $Ebin[$i]*$Ebin[$i]);
          $Ebinerr[$i] = $Ebinerr[$i] / sqrt($nbin[$i] - 1.0);
          $Bbin[$i] = $Bbin[$i] / $nbin[$i];
          $Bbinerr[$i] = sqrt($Bbinerr[$i] / $nbin[$i] - $Bbin[$i]*$Bbin[$i]);
          $Bbinerr[$i] = $Bbinerr[$i] / sqrt($nbin[$i] - 1.0);
        }
      }
#       print STDERR "i, rbin, Ebin, Ebinerr: $i, $rbin[$i] $Ebin[$i], $Ebinerr[$i]\n";
#   Print out xye text:
      print EOUT "$rbin[$i]  $Ebin[$i]  $Ebinerr[$i]\n";
      print BOUT "$rbin[$i]  $Bbin[$i]  $Bbinerr[$i]\n";
    }

    close(EOUT) or die "Couldn't close $Eoutfile: $!";
    close(BOUT) or die "Couldn't close $Boutfile: $!";
    
    print STDERR "E-mode profile in $Eoutfile\n";
    print STDERR "B-mode profile in $Boutfile\n";
    

}

# ======================================================================
