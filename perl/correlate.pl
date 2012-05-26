#!/usr/local/bin/perl -w
# ======================================================================
#+
$usage = "\n
NAME
        correlate.pl

PURPOSE
        Read in two catalogs and compute their correlation function.

USAGE
        correlate.pl [flags] [options] A.txt B.txt

FLAGS
  -u              print this message

INPUTS
   *.txt          2 x 4 column (x,y,e1,e2) ascii text catalogues

OPTIONAL INPUTS
  -o root         write output to \"root\" plus suitable extensions
  -r rmax         maximum radius for binning grid
  -n nbin         no. of bins in binning grid
  -tt             Output tt correlator
  -xx             Output xx correlator
  -tx             Output tx correlator
  -plus           Output Xi+ correlation function
  -minus          Output Xi- correlation function
  -cross          Output Xix correlation function
  -all            Default: return all correlators
  -fast           Use external call to fortran to speed things up
  -q              Quiet operation

COMMENTS
  Best to have x and y (and so rmax) in arcsec.

EXAMPLES
  correlate.pl -r 500 -n 1000 -tt stars.txt galaxies.txt

OUTPUTS
  outfile         3 column ascii text catalogue (r, corr, error)

OPTIONAL OUTPUTS

BUGS
  - Incomplete header documentation
  - Cannot take catalogues with headers
  - No sensible default maximum radius
  - No sensible default bin number
  - Doesn't cut runtime in half if comparing against same catalog
  - Possible problem with split line...

REVISION HISTORY:
  2005-08-01 Started Cevallos and Marshall (KIPAC)
  2005-09-12 More correlators output, switched to flag system - Marshall (KIPAC)

\n";
#-
# ==============================================================================

$sdir = $ENV{'SCRIPTUTILS_DIR'};
require($sdir."/perl/esystem.pl");
$doproc = 1;

use Getopt::Long;
GetOptions("o=s", \$outfileroot,
           "r=f", \$rmax,
           "n=i", \$nbin,
           "tt", \$makett,
           "tx", \$maketx,
           "xx", \$makexx,
           "plus", \$makeXiplus,
           "minus", \$makeXiminus,
           "cross", \$makeXicross,
           "all", \$makeall,
           "fast", \$fast,
           "q", \$quiet,
           "u", \$help
          );

(defined($help)) and die "$usage\n";
$num=@ARGV;
($num>0) or die "$usage\n";

$vb = 1;
(defined($quiet)) and $vb = 0;

(defined($fast)) and $fast = 1;
(defined($fast)) or $fast = 0;

$sensible=0;
(defined($outfileroot)) or ($sensible = 1);

(defined($rmax)) or $rmax = 3600;
(defined($nbin)) or $nbin = 50;

(defined($makett)) and $makett = 1;
(defined($maketx)) and $maketx = 1;
(defined($makexx)) and $makexx = 1;
(defined($makeplus)) and $makeplus = 1;
(defined($makeminus)) and $makeminus = 1;
(defined($makecross)) and $makecross = 1;

$makeall = 0;
($makett or $maketx or $makexx or $makeXiplus or $makeXiminus or $makeXicross) 
or ($makeall = 1);
(defined($makeall)) and $makeall = 1;

#-------------------------------------------------------------------------------

# Check for imcat environment:
# (defined($ENV{"IMCATDIR"})) or die "Imcat environment undefined.\n";

# Take in types and catalogs, check for catalog's existence:

$catA = shift @ARGV;
(-e $catA) or die "$correlate.pl: $catA does not exist.";

$catB = shift @ARGV;
(-e $catB) or die "$correlate.pl: $catB does not exist.";


# Set up output filenames:

if ($sensible) {
  $rootA = $catA;
  $rootB = $catB;
  $rootA =~ s/(.*)\..*/$1/;
  $rootB =~ s/(.*)\..*/$1/;
  $ttfile = $rootA.".vs.".$rootB.".tt.txt";
  $txfile = $rootA.".vs.".$rootB.".tx.txt";
  $xxfile = $rootA.".vs.".$rootB.".xx.txt";
  $Xiplusfile = $rootA.".vs.".$rootB.".Xiplus.txt";
  $Ximinusfile = $rootA.".vs.".$rootB.".Ximinus.txt";
  $Xicrossfile = $rootA.".vs.".$rootB.".Xicross.txt";
} else {
  $ttfile = $outfileroot.".tt.txt";
  $txfile = $outfileroot.".tx.txt";
  $xxfile = $outfileroot.".xx.txt";
  $Xiplusfile =  $outfileroot.".Xiplus.txt";
  $Ximinusfile = $outfileroot.".Ximinus.txt";
  $Xicrossfile = $outfileroot.".Xicross.txt";
}

if ( $vb ) {
  if ( $makett or $makeall ){
  print STDERR "tt correlation will be written to $ttfile\n";
  }
  if ( $maketx or $makeall ){
  print STDERR "tx correlation will be written to $txfile\n";
  }
  if ( $makexx or $makeall ){
  print STDERR "xx correlation will be written to $xxfile\n";
  }
  if ( $makeXiplus or $makeall ){
  print STDERR "Xiplus correlation will be written to $Xiplusfile\n";
  }
  if ( $makeXiminus or $makeall ){
  print STDERR "Ximinus correlation will be written to $Ximinusfile\n";
  }
  if ( $makeXicross or $makeall ){
  print STDERR "Xicross correlation will be written to $Xicrossfile\n";
  }
}
#-------------------------------------------------------------------------------

if ($fast) {
# Jump out and do the calculations fast in fortran...
# Need to protect fortran from problem filenames!
  &esystem("cp $catA A.cat", $doproc, $vb);
  &esystem("cp $catB B.cat", $doproc, $vb);
  
  $ffile = "fortran.inp";
  open (FOUT, ">$ffile") or die "Couldn't open $ffile: $!";
  print FOUT "A.cat\n";
  print FOUT "B.cat\n";
  print FOUT "$nbin\n";
  print FOUT "$rmax\n";
  print FOUT "$vb\n";
  close (FOUT);

  &esystem("cat $ffile | correlate.exe > /dev/null 2>&1", $doproc, 0);
  &esystem("mv tt.txt $ttfile", $doproc, $vb);
  &esystem("mv tx.txt $txfile", $doproc, $vb);
  &esystem("mv xx.txt $xxfile", $doproc, $vb);
  &esystem("mv Xiplus.txt $Xiplusfile", $doproc, $vb);
  &esystem("mv Ximinus.txt $Ximinusfile", $doproc, $vb);
  &esystem("mv Xicross.txt $Xicrossfile", $doproc, $vb);
  &esystem("rm $ffile A.cat B.cat", $doproc, $vb);
  
  goto FINISH;

}


#-------------------------------------------------------------------------------
# Original SLOW perl...

# Read in catalog data:

open CAT, $catA or die "Cannot read $catA: $!";
@dataA = <CAT>;
close CAT;

open CAT, $catB or die "Cannot read $catB: $!";
@dataB = <CAT>;
close CAT;

# Set up binning grid:

# The length of each bin (dr) = total length / number of bins

$dr = $rmax / $nbin;

# @rbin contains midpoints of bins

for ($k = 0; $k < $nbin; $k++){
  $rbin[$k] = ($dr * ($k + 0.5));
}

# Set up statistics:

for ($k = 0; $k < $nbin; $k++){
  $sumtt[$k] = 0.0;
  $sumsqtt[$k] = 0.0;
  $sumtx[$k] = 0.0;
  $sumsqtx[$k] = 0.0;
  $sumxx[$k] = 0.0;
  $sumsqxx[$k] = 0.0;
  $totalNum[$k] = 0;
}

# Do calculations:

#print $#dataA,$#dataB;
$ohmygod = $#dataA*$#dataB;
$count = 0;

($vb) and print STDERR "Correlating $ohmygod pairs...\n";

for ($i = 0; $i < $#dataA; $i++){ # iterate through $catA

  @Acols = split(/\s+/, $dataA[$i]);
  $xA[$i] = $Acols[0];
  $yA[$i] = $Acols[1];
  $e1A[$i] = $Acols[2];
  $e2A[$i] = $Acols[3];

  #print "$xA[$i] $yA[$i] $e1A[$i] $e2A[$i]\n";

  for ($j = 0; $j < $#dataB; $j++){ # iterate through $catB

    $count++;
    
    @Bcols = split(/\s+/, $dataB[$j]);
    $xB[$j] = $Bcols[0];
    $yB[$j] = $Bcols[1];
    $e1B[$j] = $Bcols[2];
    $e2B[$j] = $Bcols[3];

    #print "$xB[$j] $yB[$j] $e1B[$j] $e2B[$j]";

    # Compute r:

    $deltaX = abs($xA[$i] - $xB[$j]);

    $deltaY = abs($yA[$i] - $yB[$j]);

    $R = sqrt($deltaX*$deltaX + $deltaY*$deltaY);

    next if (($R == 0) or ($R > $rmax));

    # Which bin do they go into?

    $k = int( $R / $dr );

    # Inner products: E-mode and B-mode with angles involved:

    $cosphi = $deltaX / $R;
    $sinphi = $deltaY / $R;

    $cosphisq = $cosphi*$cosphi;
    $sinphisq = $sinphi*$sinphi;
    $cos2phi = $cosphisq - $sinphisq;
    $sin2phi = 2 * $sinphi * $cosphi;
    $cos2phisq = $cos2phi*$cos2phi;
    $sin2phisq = $sin2phi*$sin2phi;
    $cos2phisin2phi = $cos2phi*$sin2phi;

#     if ( $mode eq "E" or $mode eq "s" ){
#       $gammaE = ($cos2phisq * ($e1A[$i]*$e1B[$j])) + 
#                 ($sin2phisq * ($e2A[$i]*$e2B[$j])) + 
#                 ($cos2phisin2phi * ($e2A[$i]*$e1B[$j] + $e1A[$i]*$e2B[$j]));
#     }
#     if ($mode eq "B" or $mode eq "s" ){
#       $gammaB = ($cos2phisq * ($e2A[$i]*$e2B[$j])) + 
#                 ($sin2phisq * ($e1A[$i]*$e1B[$j])) + 
#                 ($cos2phisin2phi * ($e1A[$i]*$e2B[$j] + $e2A[$i]*$e1B[$j]));
#     }
# 

# Correlation functions from Schneider's notes - 
# build up averages as we go:

    if ( $makett or $makeXiplus or $makeXiminus or $makeall ) {
    
#	print "cos2phisq=".$cos2phisq."\n";
#	print "sin2phisq=".$sin2phisq."\n";
#	print "cos2phisin2phi=".$cos2phisin2phi."\n";
#	print "e1A=".$e1A[$i]."\n";
#	print "e1B=".$e1B[$i]."\n";
#	print "e2A=".$e2A[$i]."\n";
#	print "e2B=".$e2B[$i]."\n";
#	exit;

      $tt =   ($cos2phisq * ($e1A[$i]*$e1B[$j]))
            + ($sin2phisq * ($e2A[$i]*$e2B[$j]))
            + ($cos2phisin2phi * ($e2A[$i]*$e1B[$j] + $e1A[$i]*$e2B[$j]));
    
      $sumtt[$k] += $tt;
      $sumsqtt[$k] += $tt*$tt;
      
    }
    
    if ( $makexx or $makeXiplus or $makeXiminus or $makeall ) {

      $xx =   ($cos2phisq * ($e2A[$i]*$e2B[$j]))
            + ($sin2phisq * ($e1A[$i]*$e1B[$j]))
            - ($cos2phisin2phi * ($e1A[$i]*$e2B[$j] + $e2A[$i]*$e1B[$j]));

      $sumxx[$k] += $xx;
      $sumsqxx[$k] += $xx*$xx;
      
    }

    if ( $maketx or $makeXicross or $makeall ) {

      $tx =   ($cos2phisq * ($e1A[$i]*$e2B[$j]))
            - ($sin2phisq * ($e2A[$i]*$e1B[$j]))
            - ($cos2phisin2phi * ($e1A[$i]*$e1B[$j] - $e2A[$i]*$e2B[$j]));

      $sumtx[$k] += $tx;
      $sumsqtx[$k] += $tx*$tx;
      
    }

    $totalNum[$k] += 1;

  }

  $percent = int(100*$count/$ohmygod);
  ($vb) and print STDERR "$percent% completed.\r";

}

#-------------------------------------------------------------------------------

# Open output for writing binned correlation function:

if ( $makett or $makeall ){
  open (TTOUT, ">$ttfile") or die "Couldn't open $ttfile: $!";
}
if ( $maketx or $makeall ){
  open (TXOUT, ">$txfile") or die "Couldn't open $txfile: $!";
}
if ( $makexx or $makeall ){
  open (XXOUT, ">$xxfile") or die "Couldn't open $xxfile: $!";
}
if ( $makeXiplus or $makeall ){
  open (XIPLUSOUT, ">$Xiplusfile") or die "Couldn't open $Xiplusfile: $!";
}
if ( $makeXiminus or $makeall ){
  open (XIMINUSOUT, ">$Ximinusfile") or die "Couldn't open $Ximinusfile: $!";
}
if ( $makeXicross or $makeall ){
  open (XICROSSOUT, ">$Xicrossfile") or die "Couldn't open $Xicrossfile: $!";
}

# Start writing:

for ($k = 0; $k < $nbin; $k++){

  if($totalNum[$k] > 1){           # To avoid division by zero

    # Calculate mean and squared error on mean, for tt, tx, xx:

    if ( $makett or $makeXiplus or $makeXiminus or $makeall ) {

      $meantt[$k]  = $sumtt[$k] / $totalNum[$k];
      $errsqtt[$k] = ($sumsqtt[$k]/$totalNum[$k] - $meantt[$k]*$meantt[$k]) /
                                  ($totalNum[$k]-1);
      $errtt[$k] = sqrt($errsqtt[$k]);
    }

    if ( $makexx or $makeXiplus or $makeXiminus or $makeall ) {

      $meanxx[$k]  = $sumxx[$k] / $totalNum[$k];
      $errsqxx[$k] = ($sumsqxx[$k]/$totalNum[$k] - $meanxx[$k]*$meanxx[$k]) /
                                  ($totalNum[$k]-1);
      $errxx[$k] = sqrt($errsqxx[$k]);
    }

    if ( $maketx or $makeXicross or $makeall ) {

      $meantx[$k]  = $sumtx[$k] / $totalNum[$k];
      $errsqtx[$k] = ($sumsqtx[$k]/$totalNum[$k] - $meantx[$k]*$meantx[$k]) /
                                  ($totalNum[$k]-1);
      $errtx[$k] = sqrt($errsqtx[$k]);
    }

    # Now form three correlation functions:

    if ( $makeXiplus or $makeall ) {
      $meanXiplus[$k] = $meantt[$k] + $meanxx[$k];
      $errXiplus[$k] = sqrt($errsqtt[$k] + $errsqxx[$k]);
    }

    if ( $makeXiminus or $makeall ) {
      $meanXiminus[$k] = $meantt[$k] - $meanxx[$k];
      $errXiminus[$k] = sqrt($errsqtt[$k] + $errsqxx[$k]);
    }

    if ( $makeXicross or $makeall ) {
      $meanXicross[$k] = $meantx[$k];
      $errXicross[$k] = $errtx[$k];
    }

    $currentRad = $rbin[$k];

    # Print out:

    if ( $makett or $makeall ){
      print TTOUT "$currentRad \t $meantt[$k] \t $errtt[$k] \n";
    }
    if ( $maketx or $makeall ){
      print TXOUT "$currentRad \t $meantx[$k] \t $errtx[$k] \n";
    }
    if ( $makexx or $makeall ){
      print XXOUT "$currentRad \t $meanxx[$k] \t $errxx[$k] \n";
    }
    if ( $makeXiplus or $makeall ){
      print XIPLUSOUT "$currentRad \t $meanXiplus[$k] \t $errXiplus[$k] \n";
    }
    if ( $makeXiminus or $makeall ){
      print XIMINUSOUT "$currentRad \t $meanXiminus[$k] \t $errXiminus[$k] \n";
    }
    if ( $makeXicross or $makeall ){
      print XICROSSOUT "$currentRad \t $meanXicross[$k] \t $errXicross[$k] \n";
    }

  }

}

# Tidy up and finish:

if ( $makett or $makeall ){
  close(TTOUT);
}
if ( $maketx or $makeall ){
  close(TXOUT);
}
if ( $makexx or $makeall ){
  close(XXOUT);
}
if ( $makeXiplus or $makeall ){
  close(XIPLUSOUT);
}
if ( $makeXiminus or $makeall ){
  close(XIMINUSOUT);
}
if ( $makeXicross or $makeall ){
  close(XICROSSOUT);
}

($vb) and print STDOUT "100% completed.  \n";

FINISH:
# ======================================================================
