#===============================================================================

sub hz_write_spectra_param_file{

  my $SEDtype = shift ;
  $hzdir = $ENV{'HYPERZ_DIR'};

  if($SEDtype=~ m/^Burst$/){
        $SEDfile= "$hzdir/templates/".$SEDtype.".ised  BC" ;
  }elsif($SEDtype=~ m/^E\.ised$/){
        $SEDfile= "$hzdir/templates/".$SEDtype.".ised  BC" ;
  }elsif($SEDtype=~ m/^S0$/){
        $SEDfile= "$hzdir/templates/".$SEDtype.".ised  BC" ;
  }elsif($SEDtype=~ m/^Sa$/){
        $SEDfile= "$hzdir/templates/".$SEDtype.".ised  BC" ;
  }elsif($SEDtype=~ m/^Sb$/){
        $SEDfile= "$hzdir/templates/".$SEDtype.".ised  BC" ;
  }elsif($SEDtype=~ m/^Sc$/){
        $SEDfile= "$hzdir/templates/".$SEDtype.".ised  BC" ;
  }elsif($SEDtype=~ m/^Sd$/){
        $SEDfile= "$hzdir/templates/".$SEDtype.".ised  BC" ;
  }elsif($SEDtype=~ m/^Im$/){
        $SEDfile= "$hzdir/templates/".$SEDtype.".ised  BC" ;
  }elsif($SEDtype=~ m/^CWW_E_ext$/){
        $SEDfile= "$hzdir/templates/".$SEDtype.".sed  AS" ;
  }elsif($SEDtype=~ m/^CWW_Sbc_ext$/){
        $SEDfile= "$hzdir/templates/".$SEDtype.".sed  AS" ;
  }elsif($SEDtype=~ m/^CWW_Scd_ext$/){
        $SEDfile= "$hzdir/templates/".$SEDtype.".sed  AS" ;
  }elsif($SEDtype=~ m/^CWW_Im_ext$/){
        $SEDfile= "$hzdir/templates/".$SEDtype.".sed  AS" ;
  }else{
        $SEDfile= "$hzdir/templates/".$SEDtype.".sed" ;
        open SED,"$SEDfile" or die "Could not open $SEDfile";
        close(SED);        
        $SEDfile= "$hzdir/templates/".$SEDtype.".sed  AS" ;
  }
  open FH,"> hz_spectra.param" or return 0;
  print FH "$SEDfile\n";
  close(FH);
  return 1;
}

#===============================================================================

sub hz_read_filter_res_file{

  my $filterresfile = shift;
  
  my @filternames;
  
  $#filternames=-1;
  open FH,"< $filterresfile" or return 0;
  while(<FH>){
     chomp ;
#     /^\#$/ or next ;
     @f = split ;
     $nlines = shift @f ;
# Take the 2nd element on the line to be the filter name:
#      push @filternames, $f[0] ;
# Take everything after the number of lines to be the filter name:
     $_ = join(" ",@f) ;
     s/\+/\\+/ ; 
     push @filternames, $_ ;
     for(my $i=0 ; $i<$nlines; $i++){ readline FH ;}   
  }
  close FH ;
  return (@filternames);
    
}

#===============================================================================
# BUG! Reddest and bluest filtercodes are hard-coded here!

sub hz_write_filters_param_file{

  my $filtercode = shift ;
  my $method = shift ;
  
  open FH,"> hz_filters.param" or return 0;
  if ($method){
# Use bluest and reddest filters, plus chosen one:
    print FH "10         0.00   1   35.0   0.5\n";
    print FH "$filtercode          0.00   1   35.0   0.5\n";
    print FH "1         0.00   1   35.0   0.5\n";
  } else {
# Use chosen one, twice to fool hyperz:
    print FH "$filtercode          0.00   1   35.0   0.5\n";
    print FH "$filtercode          0.00   1   35.0   0.5\n";
  }
  close(FH);
    
  return 1;
    
}

#===============================================================================

sub hz_write_photometry_catalogue_file{

    my $mag = shift ;
    my $method = shift ;
   
    open FH,"> hz_photometry.cat" or return 0;
    if ($method){
# Use bluest and reddest filters, plus chosen one:
      print FH "1  30.0  $mag  30.0  20.0  0.01  20.0\n";
    } else {
# Use chosen one, twice to fool hyperz - use this when calculating absmags:
      print FH "1  $mag  $mag  0.01  0.01\n";
    }
    close(FH);
       
    return 1;
    
}

#===============================================================================

sub hz_write_zphot_param_file{

    my $H0 = shift ;
    my $Om = shift ;
    my $OL = shift ;
    my $filterresfile = shift ;
    my $z = shift ;
    my $magtype = shift ;
    my $absmagfiltercode = shift ;
  
    $hzdir = $ENV{'HYPERZ_DIR'};
  
    my $dz = 0.0001;
    my $zmin = $z;
    my $zmax = $z + $dz;
 
    open FH,"> hz_zphot.param" or return 0;
    print FH "
A0VSED         $hzdir/filters/A0V_KUR_BB.SED  # Vega SED
FILTERS_RES    $filterresfile      # filters' transmission
FILTERS_FILE   hz_filters.param    # filters' file
TEMPLATES_FILE hz_spectra.param    # models file
FILT_M_ABS     $absmagfiltercode   # filter code for absolute magnitude
ERR_MAG_MIN                  0.001 # err_min
Z_MIN                        $zmin # minimum redshift
Z_MAX                        $zmax # maximum redshift
Z_STEP                       $dz   # step in redshift 
ZSTEP_TYPE                       0 # 0 step = Z_STEP
                                   # 1 step = Z_STEP*(1+z)
CATALOG_TYPE                     0 # cat.type
                                   # 0 z/cat 
                                   # 1 z/obj
CATALOG_FILE  hz_photometry.cat    # cat file
MAG_TYPE                  $magtype # 0 standard Vega mag, 1 AB mag 
REDDENING_LAW                   0 # reddening law 
                                  # 0 no reddening
                                  # 1 Allen (1976) MW
                                  # 2 Seaton (1979) MW
                                  # 3 Fitzpatrick (1983) LMC
                                  # 4 Prevot (1984) Bouchet (1985) SMC
                                  # 5 Calzetti (2000) 
AV_MIN                       0.00 # Av_min 
AV_MAX                       1.20 # Av_max 
AV_STEP                      0.20 # Av_err 
AGE_CHECK                       y # check age gal. < age universe
PROB_THRESH                 10.00 # prob. thresh. for second. max. (0,100) 
OUTPUT_FILE                    hz # name of output files (no extension)
OUTPUT_TYPE                     0 # 0 2.E-17 erg/cm^2/s/A, 1 microJy, 2 mag_AB 
SED_OBS_FILE                    y # file .obs_sed
SED_TEMP_FILE                   y # file .temp_sed
LOGPHOT_FILE                    n # file .log_phot
CATPHOT_FILE                    n # file .cat_phot
ZPHOT_FILE                      y # file .z_phot
H0                            $H0 # Hubble constant 
                                  # used to compute absolute magnitude and
                                  # ages if AGE_CHECK = y
OMEGA_M                       $Om # density parameter (matter)
                                  # used to compute absolute magnitude and
                                  # ages if AGE_CHECK = y
OMEGA_V                       $OL # density parameter (Lambda)
                                  # used to compute absolute magnitude and
                                  # ages if AGE_CHECK = y
################     cluster option    ####################
#Z_CLUSTER                      1. # redshift of cluster

################   optional parameters    ####################
M_ABS_MIN                    -38. # minimum absolute magnitude (bright)
M_ABS_MAX                     19. # maximum absolute magnitude (faint)
MATRIX                          n # file .m for each object
SPECTRUM                        y # file .spe for each object
EBV_MW                         0. # E(B-V) for galactic dereddening
   ";
   
    return 1;
    
}
#===============================================================================

sub hz_read_z_phot_file{

  my $ref_absmag = shift;
  
  open FH,"< hz.z_phot" or return 0;
  my $line = <FH> ; close FH ;
  my @f = split " ",$line,999 ;
  $$ref_absmag = $f[17] ;
  return 1;

}

#===============================================================================

sub hz_read_temp_sed_file{

  my $ref_flux = shift;
  
  open FH,"< hz.temp_sed" or return 0;
  my $line = <FH> ; close FH ;
  my @f = split " ",$line,999 ;
  $$ref_flux = $f[2] ;
  return 1;

}

#===============================================================================

sub hz_read_out_phot_file{

  my $ref_efflambda = shift;
  my $ref_AB2vega = shift;
  my $target = "wl_eff";
  
  open FH,"< hz.out_phot" or return 0;
  while(<FH>){
    chomp;
    my @f = split ;
    $f[2] =~ m/$target/ or next ;
    $_ = readline FH ;
    $_ = readline FH ;
    chomp;
    @f =  split;
    $$ref_efflambda = $f[1] ; 
    $$ref_AB2vega = $f[4] ; 
    last;
  }
  close FH ;

  return 1;

}

#===============================================================================

sub hz_get_absmag{

  my $H0 = shift ;
  my $Om = shift ;
  my $OL = shift ;
  my $SEDtype = shift;
  my $filter = shift;
  my $mag = shift;
  my $filterresfile = shift;
  my $z = shift;
  my $magtype = shift;
  my $absmag = shift;
  my $flux = shift;
  my $efflambda = shift;
  my $AB2vega = shift;
  my $absmagfilter = shift;
  my $method = shift;

# Uses filternames global variable returned by hz_read_filter_res_file

    ($vb and $method and $z1 < 0.34) and print "WARNING: outside method=1 trusted redshift range\n";

  # Procedure: 
  #   Make a "photometric catalogue" for our galaxy, with one flux entry:
  #     - the input apparent magnitude in the fA filter, with tiny error
  #   Run hyperz on this catalogue, with assumed spectral type,
  #     constraining the allowed redshift range to be zero width about z1
  #   The zphot catalogue *.z_phot contains the observed absolute magnitude 
  #     that we want, in column 17 (zero-indexed).

  # Write spectra.param file:

#   print "Calling hz_write_spectra_param_file with arguments $SEDtype\n";
  (&hz_write_spectra_param_file($SEDtype)) or die "Failed to write spectra.param file\n";
#   print "   returned with arguments $SEDtype\n";

  # Write filters.param file:

  ($#filternames) or die "No filter names are known\n";
#   print " $#filternames filter names: @filternames\n";
#   print " filter =  [$filter] cf. [$filternames[44]]\n";
  my $filtercode = 1;
  foreach my $filtername (@filternames){
    ($filter =~ m/$filtername/ ) and last ;
    $filtercode++;
  }
  ($filtercode > $#filternames) and die "Could not match filter name $filter $filtercode > $#filternames\n";
#   print "Calling hz_write_filters_param_file with arguments $filtercode,$method\n";
  (&hz_write_filters_param_file($filtercode,$method)) or die "Failed to write filters.param file\n";
#   print "   returned with arguments $filtercode,$method\n";

  # Write photometry.cat file:

  (&hz_write_photometry_catalogue_file($mag,$method)) or die "Failed to write photometry catalogue\n";

  # Write zphot.param file:

  my $absmagfiltercode = 1;
  foreach my $absmagfiltername (@filternames){
   ($absmagfilter =~ m/$absmagfiltername/ ) and last ;
    $absmagfiltercode++;
  }
  ($absmagfiltercode > $#filternames) and die "Could not match filter name $absmagfilter\n";
  (&hz_write_zphot_param_file($H0,$Om,$OL,$filterresfile,$z,$magtype,$absmagfiltercode)) or die "Failed to write zphot.param file\n";

  # And finally, run hyperz:

  # BUG! noclobber must be set to 0 in the shell...
  &esystem("echo hz_zphot.param | hyperz >& hz.log", $doproc, 0);
  my $logfilesize = -s "hz.log";
  ($logfilesize == 0) and die "\nERROR: aborting due to hyperz crash - debug with\n
    echo hz_zphot.param | hyperz\n\n";

  (&hz_read_z_phot_file(\$loc_absmag)) or die "Failed to read z_phot file\n";
  $$absmag = $loc_absmag ;

#   print "In hz_get_absmag, absmag = $$absmag\n";
  
  (&hz_read_temp_sed_file(\$loc_flux)) or die "Failed to read temp_sed file\n";
  $$flux = $loc_flux ;

  (&hz_read_out_phot_file(\$loc_efflambda,\$loc_AB2vega)) or die "Failed to read out_phot file\n";
  $$efflambda = $loc_efflambda ;
  $$AB2vega = $loc_AB2vega ;

  return 1;  

}

#===============================================================================

sub hz_plot{

   my $specfile1 = shift;
   my $z1 = shift;
   my $specfile2 = shift;
   my $z2 = shift;
   my $lambda1 = shift;
   my $mag1 = shift;
   my $flux1 = shift;
   my $lambda2 = shift;
   my $mag2 = shift;
   my $flux2 = shift;
   my $filter1 = shift;
   my $filter2 = shift;
   my $filterresfile = shift;
   my $quiet = shift;

# Aspect ratio of plot:
  $aspect = 0.707;

# General line width:
  $lw0 = 2;

# General line style:
  $ls0 = 1;

# General line colour index:
  $ci0 = 1;

# Plot labelling:
  $xlabel = "Wavelength \\gl / \\A";
  $ylabel = "Flux F\\d\\gl\\u / 2x10\\u-17\\d erg s\\u-1\\d cm\\u-2\\d \\A\\u-1\\d";
  $title = " ";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Open up each spectrum file, read in 2 columns, take logs:

  (&hz_read_specfile($specfile1,\@x1,\@y1)) 
                     or die "Failed to read $specfile1\n";    
  (&hz_read_specfile($specfile2,\@x2,\@y2)) 
                     or die "Failed to read $specfile1\n";    

# Set plotting limits - catch -99s!:
  $ignorelessthanthis = -98.0;

#   @x1limits = minmax($ignorelessthanthis,@x1);
#   @x2limits = minmax($ignorelessthanthis,@x2);
  @y1limits = minmax($ignorelessthanthis,@y1);
  @y2limits = minmax($ignorelessthanthis,@y2);
  
#   @xlimits = minmax($ignorelessthanthis,@x1limits,@x2limits);
  @xlimits = (log(1700.0)/log(10.0),log(29000.0)/log(10.0));

  @specylimits = minmax($ignorelessthanthis,@y1limits,@y2limits);
  $ylimits[0] = $specylimits[0] - 0.2 ;
  $ylimits[1] = $specylimits[1] + 0.15 ;

# Read in filter transmission curves:

  (&hz_get_filter_transmission_curve($filterresfile,$filter1,\@fx1,\@fy1)) 
                         or die "Failed to read $filter1 transmission curve\n"; 
  (&hz_get_filter_transmission_curve($filterresfile,$filter2,\@fx2,\@fy2)) 
                         or die "Failed to read $filter2 transmission curve\n"; 

# # And offset to lie underneath spectra - assumes they both have maxima 
# # close to 1.0:
#   $ignorelessthanthis = -100.0;
#   @flimits = minmax($ignorelessthanthis,@fy1,@fy2);
#   $offset = $flimits[1] - $specylimits[0] + 0.1;
#   for (my $k=0; $k<$#fy1; $k++){ $fy1[$k] -= $offset; }
#   for (my $k=0; $k<$#fy2; $k++){ $fy2[$k] -= $offset; }
  $ignorelessthanthis = -100.0;
  @flimits = minmax($ignorelessthanthis,@fy1,@fy2);
  $offset = $flimits[1] - $ylimits[1] + 0.1;
  for (my $k=0; $k<$#fy1; $k++){ $fy1[$k] -= $offset; }
  for (my $k=0; $k<$#fy2; $k++){ $fy2[$k] -= $offset; }

# Prepare points for plotting:

  $xpt1 = log($lambda1)/log(10.0);
  $ypt1 = log($flux1)/log(10.0);
  $xpt2 = log($lambda2)/log(10.0);
  $ypt2 = log($flux2)/log(10.0);
  
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Plot -  twice, once to screen and once to file:

  for (my $k=0; $k<2; $k++){

    if($k == 0){
      $device = "/xs";
      ($quiet) and $device = "/null";
    }
    else{
       $device = "mag2mag.ps/vcps";
    }

    pgbeg(0,$device,1,1);
    pgpap(0.0,$aspect);
  #   pgsvp(0.15,0.9,0.15,0.9);
    pgslw($lw0);

  # Order spectra by redshift, plot in blue(12) and red(2):
    if ($z1 < $z2){
      $ci1 = 11;
      $ci2 = 2;
    } else {
      $ci1 = 2;
      $ci2 = 11;
    }

# Set up plotting window:
    pgsci($ci0);
    pgsls($ls0);
    pgsch(1.0);
    pgsvp(0.12,0.9,0.15,0.9);
    pgswin($xlimits[0],$xlimits[1],$ylimits[0],$ylimits[1]);

# Plot filter transmission curves:

    pgsci(15);
    pgpoly($#fx1, \@fx1, \@fy1);
    pgpoly($#fx2, \@fx2, \@fy2);
    pgsci(14);
    pgsfs(2);
    pgpoly($#fx1, \@fx1, \@fy1);
    pgpoly($#fx2, \@fx2, \@fy2);
#     pgsch(0.75);
# This has to be really small
    pgsch(0.5);
    $texty = $ylimits[0] + 0.05;
    pgptxt($xpt1,$texty,0.0,0.5,$filter1);
    pgptxt($xpt2,$texty,0.0,0.5,$filter2);

# Now plot spectra and fluxes:
    pgsci($ci1);
    pgline($#x1, \@x1, \@y1);
    pgsch(2.0);
    pgpt(1,$xpt1,$ypt1,-17);
    pgsch(0.75);
    $textx = $xpt1 + 0.0051;
    $texty = $ypt1 - 0.07;
    $string1 = "m = $mag1";
    pgptxt($textx,$texty,90.0,1.0,$string1);

    pgsci($ci2);
    pgline($#x2, \@x2, \@y2);
    pgsch(2.0);
    pgpt(1,$xpt2,$ypt2,-17);
    pgsch(0.75);
    $textx = $xpt2 + 0.0051;
    if (($ypt1-$ypt2) > 0.5) {
      $texty = $ypt2 + 0.1;
      $textjust = 0.0
    } else {  
      $texty = $ypt2 - 0.07;
      $textjust = 1.0
    }
    $string2 = "m = $mag2";
    pgptxt($textx,$texty,90.0,$textjust,$string2);

    pgsci($ci0);
    pgsch(1.0);

# Plot axes and finish:
    pgsci($ci0);
    pgsch(1.0);
    pgbox("BCNLST",0.0,0,"BCNLST",0.0,0);
    pgsch(1.5);
    pglabel($xlabel,$ylabel,$title);
    
    pgend();
   
  }

  return 1;

}  
#===============================================================================

sub hz_read_specfile{
    
    my $specfile = shift;
    my $x = shift; 
    my $y = shift; 
    
    open (IN, $specfile) or return 0;
    my $i = 0;
    while (<IN>){
      next if (/^\#/ or /^$/);
      chomp;
      @cols = split;
      $$x[$i] = $cols[0];
      $$y[$i] = $cols[1];
      $$x[$i] = log($$x[$i]+1e-99)/log(10);
      $$y[$i] = log($$y[$i]+1e-99)/log(10);
      $i++;
     }
     close (IN);

  return 1;

}  

#===============================================================================

sub hz_get_filter_transmission_curve{

  my $filterresfile = shift;
  my $filter = shift;
  my $x = shift; 
  my $y = shift; 
  
# Uses filternames global variable returned by hz_read_filter_res_file

# First get filtercode corresponding to filter name:
  my $i=1 ;
  for (@filternames){
   ($filter =~ m/$_/ ) and last ;
   $i++ ;
  }
  ($i > $#filternames) and die "Could not match filter name $filter, $i > $#filternames\n";
  my $filtercode = $i;
  
# Now read filter.res file to get to the relevant filter, and grab x and y:

  open FH,"< $filterresfile" or return 0;
  $i = 0;
  while(<FH>){
     chomp ;
#     /^\#$/ or next ;
     @f = split ;
     $nlines = shift @f ;
     $i++;
     if ($i == $filtercode){
#        print "$i  $nlines  @f\n";
       for(my $j=0 ; $j<$nlines; $j++){ 
         $_ = readline FH ;
         chomp;
         @cols = split;
         ($cols[2] < 0.0) and $cols[2] = 0.0;
         $$x[$j] = log($cols[1]+1e-99)/log(10.0);
         $$y[$j] = log($cols[2]+1e-99)/log(10.0);
#          $$x[$j] = $cols[1];
#          $$y[$j] = $cols[2];
#          print "$$x[$j]  $$y[$j]\n";
       }
       close FH ;
       return 1;
     } else {     
       for(my $j=0 ; $j<$nlines; $j++){ readline FH ;}
     }     
  }
  close FH;
  return 0;
    
}

#===============================================================================

sub hz_convert{

  my $magtype = shift;
  my $convert = shift;
  my $oldmag = shift;
  my $AB2vega = shift;

  my $sign;
  my $newmag;

  if ($convert){
    if ($magtype){
      $sign = -1.0;
    } else {
      $sign =  1.0;
    }
    $newmag = $oldmag + ($sign * $AB2vega);
  } else {
    $newmag = $oldmag;
  }
  
  return ($newmag);
    
}

#===============================================================================

sub hz_get_distance_modulus{

  my $z = shift;
  my $H0 = shift ;
  my $Om = shift ;
  my $OL = shift ;
  my $filterresfile = shift;
  my $vb = shift;

  my $SEDtype = "CWW_E_ext";
  my $bolofilter = "Bolometric";
  my $mref = 25.0;
  my $magtype = 1;
  my $method = 0;
  my $z0 = 0.0;
  my $absmag = 0;
  my $flux = 0;
  my $efflambda = 0;
  my $AB2vega = 0;

  ($vb) and print "\t  z \t DM \t  D_L/Mpc \t\t  D_A/Mpc\n";
  (&hz_get_absmag($H0,$Om,$OL,$SEDtype,$bolofilter,$mref,$filterresfile,$z0,$magtype,
           \$absmag,\$flux,\$efflambda,\$AB2vega,$bolofilter,$method)) or die "Failed to calculate absolute magnitude\n";
  my $DM = $mref - $absmag;
  my $offset = 25.0 - $DM;
  $DM += $offset;
  my $DL = 10.0**(($DM - 25.0)/5.0);
  my $DA = $DL/(1.0+$z0)**2.0;
  ($vb) and print "\t '$z0' \t $DM \t  $DL \t\t\t  $DA\n";

  (&hz_get_absmag($H0,$Om,$OL,$SEDtype,$bolofilter,$mref,$filterresfile,$z,$magtype,
           \$absmag,\$flux,\$efflambda,\$AB2vega,$bolofilter,$method)) or die "Failed to calculate absolute magnitude\n";
  $DM = $mref - $absmag;
  $DM += $offset;
  $DL = 10.0**(($DM - 25.0)/5.0);
  $DA = $DL/(1.0+$z)**2.0;
  ($vb) and print "\t $z \t $DM \t  $DL \t  $DA\n";

  ($vb) and print "(after applying an offset in DM of $offset such that z=0 gives DM=25)\n";
  
  return $DM;  

}

#===============================================================================
# Perl modules that contain nothing but subroutines require this at the end:
1;
