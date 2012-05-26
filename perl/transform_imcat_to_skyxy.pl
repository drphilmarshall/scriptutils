#!/usr/local/bin/perl -w
# ======================================================================
#+
$usage = "

NAME
        transform_imcat_to_skyxy.pl

PURPOSE        
        Rotate imcat catalogue and calculate xy2sky or sky2xy using fits file.

FLAGS
        -u      Print this message
        -v      Verbose output

INPUTS
        file.cat        imcat catalogue

OPTIONAL INPUTS
        -o outfile	write output to \"outfile\" (def=file.WCS.cat)
        -f fitsfile     specify the fitsfile to use for input
        -xcol   i       Use ith column for x positions (def=1)
        -ycol   i       Use ith column for y positions (def=2)
        -option i       converting options: 0 sky2xy 1 xy2sky 2 sky2sexag (def=0)

OPTIONAL OUTPUTS

COMMENTS

EXAMPLES
        transform_imcat_to_skyxy.pl file.cat
        USE WITH CAUTION; DOUBLE CHECK THE REGION FILES

BUGS


REVISION HISTORY:


\n";
#-
# ======================================================================


$sdir = $ENV{'SCRIPTUTILS_DIR'};
require($sdir."/perl/esystem.pl");
$doproc = $vb =1;
                                                 
use Getopt::Long;
GetOptions("o=s", \$outfile,
           "f=s", \$fitsfile,    
	   "v", \$verbose,
	   "xcol=i", \$xcol,
           "ycol=i", \$ycol,
	   "option=i",\$option,
	   "u", \$help
	   );

(defined($help)) and die "$usage\n";
(defined($xcol)) or ($xcol = 1);
(defined($ycol)) or ($ycol = 2);
(defined($option)) or ($option = 0);
$num=@ARGV;
($num>0) or die "$usage\n";

$vb = 0;
(defined($verbose)) and $vb = 1;

$sensible=0;
(defined($outfile)) or ($sensible = 1);

# Check for imcat environment:

(defined($ENV{"IMCATDIR"})) or die "TRANSFORM_CAT_TO_WCS: Imcat environment undefined.\n"; 
# $dir = '/u/ki/pjm/imcat/bin/linux/';
$dir = $ENV{"IMCATDIR"}."bin/Linux/";

# Check for existence of catalogue:

$catfile = shift @ARGV;
(-e $catfile) or die "TRANSFORM_CAT_TO_WCS: Catalogue $catfile not found.\n";

# Check for existence of FITS image associated with catalogue:
(defined ($fitsfile) and $option != 2) or chomp($fitsfile = `${dir}/lc -p fits_name < $catfile | cut -b2-100`);
print STDERR "FITS file = $fitsfile\n";
(($fitsfile eq "") and ($option != 2)) and die "TRANSFORM_CAT_TO_WCS: No FITS image associated with catalogue.\n";
((-e $fitsfile) or ($option == 2)) or die "TRANSFORM_CAT_TO_WCS: $fitsfile not found.\n";

# Output filename:

if ($sensible == 1) {
  $root = $catfile;
  $root =~ s/(.*)\..*/$1/;
  $outfile = $root.".WCS.cat";
}

# Now read in file:
#we create two extra columns, which we will later overwrite with real stuff
$catfiletmp = $catfile.".tmp";
if ($option == 0){
    &esystem("${dir}/lc +all 'pixnew = 1.0 1.0 2 vector' < $catfile > $catfiletmp",$doproc,$vb);      
}
elsif ($option == 1){
    &esystem("${dir}/lc +all 'ranew = 1.0 1.0 2 vector' < $catfile > $catfiletmp",$doproc,$vb);  
}
elsif ($option == 2){
    &esystem("${dir}/lc +all 'ranew = {a} {a} 2 vector' < $catfile > $catfiletmp",$doproc,$vb);  
}
    


open (IN, $catfiletmp) or die "$catfiletmp: $!";
print STDERR "\nReading data from $catfiletmp ...\n"; 
open (OUT, ">$outfile") or die "Couldn't open $outfile: $!";

$progress = 0;
# Step through lines of catalogue,
while (<IN>){
    chomp;
# dealing with header lines,      
      if (/^\#/ or /^$/){
	  print OUT "$_\n";
	  next;        
      } else {
	  
	  @line = split;
	  $ra = $line[$xcol];
	  $dec = $line[$ycol];
	  if ($option == 0){
	      chomp($wcsout=`sky2xy -n 8 ${fitsfile} $ra $dec | cut -d ">" -f 2 | cut -d "(" -f 1`); 
	  }
	  elsif ($option == 1){
	      chomp($wcsout=`xy2sky -n 8 -d ${fitsfile} $ra $dec |  cut -d "J" -f 1 `); 
	  }
          elsif ($option == 2){
	      chomp($wcsout1=`decimaltohms  $ra`);  
	      chomp($wcsout2=`decimaltodms $dec`); 
	      $wcsout = $wcsout1." ".$wcsout2;
	       print "$wcsout\n"
	  }
	  @wcscoord = split(' ',$wcsout);
	 # print "$wcscoord[0] $wcscoord[1]\n";
	  $line[-2] = $wcscoord[0];
	  $line[-1] = $wcscoord[1];
	  print OUT "@line\n";
	  $progress++;
	  if ($progress % 100 == 0) {print STDERR "Done $progress objects\r";}
      }
}
close(IN);
print STDERR "\nWrote $outfile\n";
close(OUT);    

#=======================================================================

sub acos { atan2( sqrt(1.0 - $_[0] * $_[0]), $_[0] ) }
sub asin { atan2($_[0], sqrt(1.0 - $_[0] * $_[0] ) ) } 

#=======================================================================














