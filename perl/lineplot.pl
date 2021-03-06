#!/usr/local/bin/perl -w
# ======================================================================
#+
$usage = "\n
NAME
        lineplot.pl

PURPOSE
        Plot two or three column plain text files as connected points
        with error bars.

USAGE
        lineplot.pl [flags] [options] \$project.txt \$other.txt ...

FLAGS
        -u        Print this message
        -l        Connect points with a line
        -b        Fill in polygon (blocks) defined by connected points
        -p        Plot data points
        -e        Plot error bars in y direction [x y ey]
        -e2       Plot 2-sided error bars in y direction [x y ey+ ey-]
        -exy      Plot error bars in both x and y direction [x y ex ey]
        -e2xy     Plot 2-sided error bars in both x and y direction [x y ey+ ey- ex+ ex-]
        -logx     Logarithmic x axis
        -logy     Logarithmic y axis
        -t        Time (hh mm ss) x axis
        -q        Plot quietly (no X display)

INPUTS
        \$project.txt       3 column text file (x, y, error)

OPTIONAL INPUTS
        -v        i         Verbosity (0, 1 or 2)
        -aspect   f         aspect ratio of plot
        -xmin     f         Window xmin
        -xmax     f         xmax
        -ymin     f         ymin
        -ymax     f         ymax
        -color    i         PGPLOT color index
        -axcolor  i         PGPLOT axis and label color index
        -fillcolor  i       PGPLOT block color index
        -lw       i         PGPLOT line width
        -ls       i         PGPLOT line style
        -fs       i         PGPLOT fill style for blocks
        -ch       f         PGPLOT character height
        -ch0      f         PGPLOT axis label character height
        -ps       i         PGPLOT point style
        -m        f         Straight line reference gradient
        -c        f         Straight line reference intercept
        -x0       f         Reference point x coord
        -y0       f         Reference point y coord
        -xoffset  f         Offset traces by dx
        -yoffset  f         Offset traces by dy
        -legend   s         File with legend text (one line per file!)
        -style    s         File with style parameters (one line per file!)
        -format   s         File format (gif or [def=] eps)
        -o        \$project Postscript output file

        \$other.txt         Additional text file

OUTPUTS
        \$project.ps        Postscript plot

COMMENTS
  - PGPLOT module requires /usr/local/bin/perl at KIPAC
  - style file lines should be of the form:
      ci lw ls       for -l option (lines)
      ci lw ls cb fs for -l -b option (lines and blocks)
      ci lw ls ch ps for -p -l option (lines and points)
      ci ch ps       for -p option (points)
    where
      ci = PGPLOT colour index (1=black,2=red,3=green,4=blue, etc)   
      lw = PGPLOT line width    
      ls = PGPLOT line style (1=solid,2=dashed,3=dot-dashed,4=dotted)    
      ch = PGPLOT character height    
      ps = PGPLOT character style (1=small points,17=filled circles, etc)   

EXAMPLES

BUGS

REVISION HISTORY:
  2005-08-02  Started Marshall and Cevallos (KIPAC)
  2008-07-18  Legends and styles in files Marshall (UCSB)

\n";

#-
# ======================================================================

$sdir = $ENV{'SCRIPTUTILS_DIR'};
require($sdir."/perl/minmax.pl");

use PGPLOT;

# Parse options:

use Getopt::Long;
GetOptions("o=s", \$plotfile,
           "v=i", \$verb,
           "aspect=f", \$aspect,
           "xmin=f", \$xmin,
           "xmax=f", \$xmax,
           "ymin=f", \$ymin,
           "ymax=f", \$ymax,
           "color=i", \$color,
           "axcolor=i", \$axcolor,
           "fillcolor=i", \$fillcolor,
           "ls=i", \$linestyle,
           "ch=f", \$ch,
           "ch0=f", \$ch0,
           "lw=i", \$lw,
           "axlw=i", \$axlw,
           "ps=i", \$pointstyle,
           "fs=i", \$fillstyle,
           "m=f", \$m,
           "c=f", \$c,
           "x0=f", \$x0,
           "y0=f", \$y0,
           "xoffset=f", \$xoffset,
           "yoffset=f", \$yoffset,
           "p", \$points,
           "l", \$line,
           "b", \$block,
           "e", \$errors,
           "e2", \$doubleerrors,
           "exy", \$xyerrors,
           "e2xy", \$doublexyerrors,
           "logx", \$logx,
           "logy", \$logy,
           "logmin=f",\$log10tiny,
           "t", \$time,
           "q", \$quiet,
           "xlabel=s", \$xlabel,
           "ylabel=s", \$ylabel,
           "title=s", \$title,
           "legend=s", \$legendfile,
           "style=s", \$stylefile,
           "format=s", \$fileformat,
           "u", \$help
           );

(defined($help)) and die "$usage\n";

(defined($verb)) or ($verb = 0);

# If -e is selected, term is the relative length of error bar terminals
(defined($errors)) and ($points = 1);
(defined($doubleerrors)) and ($points = 1);
(defined($xyerrors)) and ($points = 1);
(defined($doublexyerrors)) and ($points = 1);
$term = 0.3;

# Aspect ratio of plot:
(defined($aspect)) or $aspect = 0.707;

# General character height:
(defined($ch0)) or $ch0 = 1.5;
(defined($ch)) or $ch = $ch0;

# General axis and label colour:
(defined($axcolor)) and $c0 = $axcolor;
(defined($axcolor)) or $c0 = 1;

# General line width:
(defined($axlw)) and $lw0 = $axlw;
(defined($axlw)) or $lw0 = 2;

# Plot line width:
(defined($lw)) or $lw = 3;

# General line style:
$ls0 = 1;
$ls = 1;
(defined($linestyle)) and $ls = $linestyle;

# General line/point colour:
(defined($color)) and $ci = $color;
(defined($color)) or $ci = 1;

# General fill colour:
(defined($fillcolor)) and $cb = $fillcolor;
(defined($fillcolor)) or $cb = $color;

# General point style:
$ps = 17;
(defined($pointstyle)) and $ps = $pointstyle;

# General fill style:
$fs = 1;
(defined($fillstyle)) and $fs = $fillstyle;

# Plot labelling:
(defined($xlabel)) or $xlabel = " ";
(defined($ylabel)) or $ylabel = " ";
(defined($title)) or $title = " ";

# Offset traces:
(defined($xoffset)) or $xoffset = 0.0;
(defined($yoffset)) or $yoffset = 0.0;

# # Reference straight line:
# $ref = 0;
# (defined($m)) and $ref = 1;
# (defined($c)) or $c = 0.0;
# if ($ref) {
#   $x1 = $xmin;
#   $y1 = $m * $x1 + $c;
#   $x2 = $xmax;
#   $y2 = $m * $x2 + $c;
#   (defined($logx)) and $x1 = log($x1)/log(10);
#   (defined($logx)) and $x2 = log($x2)/log(10);
#   (defined($logy)) and $y1 = log($y1)/log(10);
#   (defined($logy)) and $y2 = log($y2)/log(10);
#  }

# Plot limits - need to take logs if required:
(defined($xmin) and defined($logx)) and $xmin = log($xmin)/log(10);
(defined($xmax) and defined($logx)) and $xmax = log($xmax)/log(10);
(defined($ymin) and defined($logy)) and $ymin = log($ymin)/log(10);
(defined($ymax) and defined($logy)) and $ymax = log($ymax)/log(10);

# Grab files from command line, and set up other file names:
$k = 0;
while (defined($infile = shift)){
  open (IN, $infile) or die "$infile: $!";
  close (IN);
  $file[$k] = $infile;
  $k++;
}
$nfiles = $k;

(defined($plotfile)) or ($sensible = 1);
(defined($fileformat)) or ($fileformat = "eps");

(defined($sensible) and $nfiles > 1) and die "Must specify output filename with more than one file.";

if (defined($sensible)) {
   $plotfile = $file[0];
   $plotfile =~ s/(.*)\..*/$1/;
   if($fileformat == "gif"){
     $plotfile = $plotfile.".gif";
   }else{
     $plotfile = $plotfile.".eps";
   }  
}

$legend = 0;
(defined($legendfile)) and ($legend = 1);
$style = 0;
(defined($stylefile)) and ($style = 1);

# Minimum limts:
$ignorelessthanthis = -1e32;
(defined($log10tiny)) or $log10tiny = -32.0;

# ----------------------------------------------------------------------

# Plot twice, once to screen and once to file:

for($k=0; $k<2; $k++){

  if($k == 0){
    $device = "/xs";
    defined($quiet) and $device = "/null";
  }
  else{
     if($fileformat =~ "gif"){
       $device = "$plotfile/gif";
     }else{
       $device = "$plotfile/vcps";
     }  
  }
  ($verb == 2) and print "Device set to $device\n";

  pgbeg(0,$device,1,1);
  pgpap(0.0,$aspect);
  pgsvp(0.18,0.9,0.18,0.9);
  pgsch($ch0);
  pgslw($lw0);
  pgsci($c0);

# If legend file supplied, open here:
  if ($legend){
    open (LEGEND, $legendfile);
    @legdata = <LEGEND>;
    $nlegendlines = $#legdata + 1;
#     print STDERR "no of legend lines = $nlegendlines\n";
    $legendline = 0;
  }
# If style file supplied, open here:
  if ($style){
    open (STYLE, $stylefile);
  }

# Open up file, read in 2 or 3 columns, and add to plot:

  for($j=0; $j<$nfiles; $j++){

    (($verb > 0) and $k == 0) and print "Reading data from $file[$j]\n";
    open (IN, $file[$j]);

    (($verb > 1) and $k == 0) and print "Contents are: \n";
    $i = 0;
    while (<IN>){

      next if (/^\#/ or /^$/);
      chomp;
      @cols = split;

      $x[$i] = $cols[0] + $j*$xoffset;
      $y[$i] = $cols[1] + $j*$yoffset;
      $ey[$i] = $cols[2];
      $ey2[$i] = $cols[3];
      $ex[$i] = $cols[4];
      $ex2[$i] = $cols[5];

      if (($verb > 1) and $k == 0){
        if (defined($errors)){
          print "$x[$i] $y[$i] $ey[$i] \n";
        } elsif (defined($doubleerrors)){
          print "$x[$i] $y[$i] $ey[$i] $ey2[$i] \n";
        } elsif (defined($xyerrors)){
          print "$x[$i] $y[$i] $ey[$i] $ey2[$i] \n";
        } elsif (defined($doublexyerrors)){
          print "$x[$i] $y[$i] $ey[$i] $ey2[$i] $ex[$i] $ex2[$i] \n";
        } else {
          print "$x[$i] $y[$i] \n";
        }
      }

      if(defined($errors)){
        $ylower[$i] = $y[$i] - $ey[$i];
        $yupper[$i] = $y[$i] + $ey[$i];
      } elsif(defined($doubleerrors)){ 
        $ylower[$i] = $y[$i] - $ey2[$i];
        $yupper[$i] = $y[$i] + $ey[$i];
      } elsif(defined($xyerrors)){ 
#         $ylower[$i] = $y[$i] - $ey[$i];
#         $yupper[$i] = $y[$i] + $ey[$i];
#         $ex = $ey2;
#         $xlower[$i] = $x[$i] - $ex[$i];
#         $xupper[$i] = $x[$i] + $ex[$i];
        $ylower[$i] = $y[$i] - $ey2[$i];
        $yupper[$i] = $y[$i] + $ey2[$i];
        $xlower[$i] = $x[$i] - $ey[$i];
        $xupper[$i] = $x[$i] + $ey[$i];
     } elsif(defined($doublexyerrors)){ 
        $ylower[$i] = $y[$i] - $ey2[$i];
        $yupper[$i] = $y[$i] + $ey[$i];
        $xlower[$i] = $x[$i] - $ex2[$i];
        $xupper[$i] = $x[$i] + $ex[$i];
      }
      
# Take logs!
      if (defined($logx)) {
        if ($x[$i] == 0.0){
          $x[$i] = $log10tiny;
        } else {
          $x[$i] = log($x[$i])/log(10);
        }
        if(defined($xyerrors) or defined($doublexyerrors)){
          if ($xlower[$i] <= 0.0){
            $xlower[$i] = $log10tiny;
          } else {
            $xlower[$i] = log($xlower[$i])/log(10);
          }
          if ($xupper[$i] <= 0.0){
            $xupper[$i] = $log10tiny;
          } else {
            $xupper[$i] = log($xupper[$i])/log(10);
          }
        }
      }
      if (defined($logy)) {
        if ($y[$i] <= 0.0){
          $y[$i] = $log10tiny;
        } else {
          $y[$i] = log($y[$i])/log(10);
        }
        if(defined($errors) or defined($doubleerrors) or defined($xyerrors) or defined($doublexyerrors)){
          if ($ylower[$i] <= 0.0){
            $ylower[$i] = $log10tiny;
          } else {
            $ylower[$i] = log($ylower[$i])/log(10);
          }
          if ($yupper[$i] <= 0.0){
            $yupper[$i] = $log10tiny;
          } else {
            $yupper[$i] = log($yupper[$i])/log(10);
          }
        }
      }

      $i++;
     }
     $nlines = $i;
     (($verb > 0) and $k == 0) and print "$nlines lines read\n";

     close (IN);

     if($j == 0 and $k ==0){
        @temp = minmax($ignorelessthanthis,@x);
        if (not defined($xmin)){
          $xmin = $temp[0];
          $xmin = $xmin - 0.1*abs($xmin);
        }  
        if (not defined($xmax)){
          $xmax = $temp[1];
          $xmax = $xmax + 0.1*abs($xmax);
        }  
        @temp = minmax($ignorelessthanthis,@y);
        if (not defined($ymin)){
          $ymin = $temp[0];
          $ymin = $ymin - 0.1*abs($ymin);
        }  
        if (not defined($ymax)){
          $ymax = $temp[1];
          $ymax = $ymax + 0.1*abs($ymax);
        }  
        ($verb>0) and print "Window limits set to $xmin $xmax $ymin $ymax\n";
#         (defined($logx)) and $xmin = log($xmin)/log(10);
#         (defined($logx)) and $xmax = log($xmax)/log(10);
#         (defined($logy)) and $ymin = log($ymin)/log(10);
#         (defined($logy)) and $ymax = log($ymax)/log(10);
     }
     if($j == 0){
       pgsci($c0);
       pgsch($ch0);
       pgwindow($xmin,$xmax,$ymin,$ymax);
       if (defined($time)){
         printf STDERR "calling pgtbox\n";
         pgtbox("BCNSTHYFO",0.0,0,"BCNST",0.0,0);
       } else {
         if (defined($logx) and defined($logy)){
  #          pgenv($xmin,$xmax,$ymin,$ymax,0,30);
           pgbox("BCNSTL",0.0,0,"BCNSTL",0.0,0);
         } elsif (defined($logx) and ! defined($logy)){
  #          pgenv($xmin,$xmax,$ymin,$ymax,0,10);
           pgbox("BCNSTL",0.0,0,"BCNST",0.0,0);
         } elsif (! defined($logx) and defined($logy)){
  #          pgenv($xmin,$xmax,$ymin,$ymax,0,20);
           pgbox("BCNST",0.0,0,"BCNSTL",0.0,0);
         } else {
  #          pgenv($xmin,$xmax,$ymin,$ymax,0,1);
           pgbox("BCNST",0.0,0,"BCNST",0.0,0);
         }
       }
       pglab("$xlabel","$ylabel","$title");
       if ($legend){
         if ($k == 0){
           printf STDERR "  Use cursor to select legend position...\n";
           $char = "x";
           $lx0 = 0.5*($xmin+$xmax);
           $ly0 = 0.5*($ymin+$ymax);
           pgcurs($lx0,$ly0,$char);
           pgqcs(4,$dx,$dy);
         }
         $lx = $lx0;
         $ly = $ly0;
       }
     } else {
        if ($legend){
          $ly = $ly - 1.3*$dy;
        }
     }

# Set up plotting style for this dataset:
     
     if ($style){

#    Read in parameters from style file:
       $_ = readline STYLE;
       chomp;
       @pars = split;
       $ci = shift(@pars);
       if (defined($line)) {
         $lw = shift(@pars);
         $ls = shift(@pars);
       }
       if (defined($block)) {
         $cb = shift(@pars);
         $fs = shift(@pars);
       } elsif (defined($points)) {
         $ch = shift(@pars);
         $ps = shift(@pars);
       }

     }else{
     
#    Set colour index:
       # white = 1, red = 2, green =3, blue =4 etc etc
       (defined($color)) or $ci = $j + 1;
#        # String paper scheme (green, red, blue, ...)!
#        @colourindex = (3,2,4,1,5,6,7,8,9,10,11,12);
#        (defined($color)) or $ci = $colourindex[$j];
#        # Nice scheme (grey, red, blue...)!
#        @colourindex = (14,2,11,3);
#        (defined($color)) or $ci = $colourindex[$j];
#        # Filters and spectra (grey, grey, red, blue...)!
#        @colourindex = (14,14,8,11);
#        (defined($color)) or $ci = $colourindex[$j];

#    Set line style:
       # String paper scheme (green, red, blue, ...)!
       @linestyleindex = (1,2,4,3);
#        # Nice scheme!
#        @linestyleindex = (4,2,1,3);
#        # Filters and spectra (grey, grey, red, blue...)!
#        @linestyleindex = (4,4,1,1);
       (defined($linestyle)) or $ls = $linestyleindex[$j];

#    Character style, size, line width are already set from command line.

     }

# Draw block:
     if (defined($block)) {
       ($verb > 0) and print "Dataset $j: block fill style set to $fs\n";
       pgsfs($fs);
       ($verb > 0) and print "Dataset $j: block colour set to $cb\n";
       pgsci($cb);
       pgpoly($nlines, \@x, \@y);
     }

# Draw line:
     if (defined($line)) {
       ($verb > 0) and print "Dataset $j: line color index set to $ci\n";
       pgsci($ci);
       ($verb > 0) and print "Dataset $j: line style set to $ls\n";
       pgsls($ls);
       ($verb > 0) and print "Dataset $j: line width set to $lw\n";
       if ($lw > 0) {
         pgslw($lw);
         pgline($nlines, \@x, \@y);
       }  
       pgslw($lw0);
       pgsls($ls0);
     }

# Plot points:
     if (defined($points)) {
       ($verb > 0) and print "Dataset $j: point color index set to $ci\n";
       pgsci($ci);
       ($verb > 0) and print "Dataset $j: character height set to $ch\n";
       if ($ch > 0) {
         pgsch($ch);
         ($verb > 0) and print "Dataset $j: character style set to $ps\n";
         pgpt($nlines,\@x,\@y,-$ps);
       }  
       pgsch($ch0);
     }

# Plot error bars:
     (defined($errors) or defined($doubleerrors) or defined($xyerrors) or defined($doublexyerrors)) and pgerry($nlines, \@x, \@ylower, \@yupper, $term);
     (defined($xyerrors) or defined($doublexyerrors)) and pgerrx($nlines, \@xlower, \@xupper, \@y, $term);

# Add legend if required:

     if ($legend){
       next if ($legendline == $nlegendlines);
#        $text = readline LEGEND;
       $text = $legdata[$legendline];
       $legendline ++;
       chomp($text);
       
       if (defined($line)) {
         $x1 = $lx;
         $y1 = $ly + 0.3*$dy;
         pgmove($x1,$y1);
         $x2 = $lx + 3*$dx;
         $y2 = $y1;
         if ($lw > 0){
           pgslw($lw);
           pgsls($ls);
           pgdraw($x2,$y2);
         }
       }
       if (defined($points)) {
         $x1 = $lx + 1.5*$dx;
         $y1 = $ly + 0.3*$dy;
         if ($lw > 0){
           pgsch($ch);
           pgpt1($x1,$y1,-$ps);
         }  
       }
       pgsci($c0);
       pgslw($lw0);
       pgsls($ls0);
       pgsch($ch0);
       $x3 = $lx + 4*$dx;
       $y3 = $ly;
       pgtext($x3,$y3,$text);
     }

# End of dataset loop
  }
  
# Close legend and style files:  
  ($legend) and close (LEGEND);
  ($style) and close (STYLE);


# Draw reference straight line (dotted):

  $ref = 0;
  (defined($m)) and $ref = 1;
  (defined($c)) or $c = 0.0;
  if ($ref) {
    $x1 = $xmin;
#     (defined($logx)) and $x1 = exp($x1*log(10));
    $x2 = $xmax;
#     (defined($logx)) and $x2 = exp($x2*log(10));
#     (defined($logy)) and $c = exp($c*log(10));
    $y1 = $m * $x1 + $c;
    $y2 = $m * $x2 + $c;
#     (defined($logx)) and $x1 = log($x1)/log(10);
#     (defined($logx)) and $x2 = log($x2)/log(10);
#     (defined($logy)) and $y1 = log($y1)/log(10);
#     (defined($logy)) and $y2 = log($y2)/log(10);
#     printf STDERR "Plotting straight line of gradient $m and intercept $c\n";
#     printf STDERR "  between ($x1,$y1) and ($x2,$y2)\n";
  }

# Draw reference point (star):

  $refpt = 0;
  (defined($x0)) and $refpt = 1;
  (defined($y0)) or $y0 = $x0;
  if ($refpt) {
    (defined($logx)) and $x0 = exp($x0*log(10));
    (defined($logy)) and $y0 = exp($y0*log(10));
  }

  pgsci(1);
  if ($ref) {
    pgsls(4);
    pgmove($x1,$y1);
    pgdraw($x2,$y2);
    pgsls(1);
  }

  pgsci($c0);
  if ($refpt) {
    pgsch(2.0);
    pgpt1($x0,$y0,12);
    pgsch($ch0);
  }

  pglab("$xlabel","$ylabel","$title");
  pgend();
# End of device loop
}

# ======================================================================
