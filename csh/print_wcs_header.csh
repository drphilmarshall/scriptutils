#!/bin/tcsh
#=======================================================================
#+
# NAME:
#   print_wcs_header
#
# PURPOSE:
#   Print WCS information from FITS file headers
#
# COMMENTS:
#
# USAGE:
#     print_wcs_header  FITSfile \
#           [-l --linear]\
#           [--centroid ra0 dec0]\
#           [-f --fortran]\
#           [-h --help]
#
# INPUTS:
#   FITSfile               FITS file
#
# OPTIONAL INPUTS:
#   -l --linear            Work out linear form of WCS
#   --centroid ra0 dec0    Center (linear) WCS on ra0,dec0
#   -f --fortran           Write output as a fortran data statement
#   -h --help
#
# OUTPUTS:
#   stdout
#
# EXAMPLES:
#
#   pjm@dennis > print_wcs_header.csh $input
#   CTYPE1  = 'RA---TAN'
#   CTYPE2  = 'DEC--TAN'
#   CRPIX1  = 145.201
#   CRPIX2  = -2408.02
#   CRVAL1  = 214.612347283
#   CRVAL2  = 52.5890665126
#   CD1_1   = -5.49578036933E-06
#   CD1_2   = -6.26559628274E-06
#   CD2_1   = -6.26579776421E-06
#   CD2_2   = 5.49464180336E-06
#   PIXSCALE= 0.0300026
#   pjm@dennis > print_wcs_header.csh $input --linear
#   CTYPE1  = RA---TAN
#   CTYPE2  = DEC--TAN
#   CRPIX1  = 100
#   CRPIX2  = 100
#   CRVAL1  = 214.58688
#   CRVAL2  = 52.60313
#   CD1_1   = -5.46658e-06
#   CD1_2   = -6.30079e-06
#   CD2_1   = -6.30079e-06
#   CD2_2   = 5.46658e-06
#   PIXSCALE= 0.03003
#
# DEPENDENCIES:
#   
#   xy2sky, skycoor, imhead
#
# BUGS:
#   - skycoor angles are funny...
#
#  
# REVISION HISTORY:
#   2008-06-24 started Marshall (UCSB)
#-
#=======================================================================

# Options and arguments:

set narg = $#argv

# Set defaults:

set help = 0
set linear = 0
set fortran = 0
set centroid = 0
set fitsfile = 0

# Parse command line:

while ( $#argv > 0 )
   switch ($argv[1])
   case -h:           #  print help
      set help = 1
      shift argv
      breaksw
   case --{help}:  
      set help = 1
      shift argv
      breaksw
   case -l:        
      shift argv
      set linear = 1
      breaksw
   case --{linear}:        
      shift argv
      set linear = 1
      breaksw
   case -f:        
      shift argv
      set fortran = 1
      breaksw
   case --{fortran}:        
      shift argv
      set fortran = 1
      breaksw
   case --{centroid}:        
      shift argv
      set centroid = 1
      set CRVAL1 = $argv[1]
      shift argv
      set CRVAL2 = $argv[1]
      shift argv
      breaksw
   case *:        
      set fitsfile = $argv[1]
      shift argv
      breaksw
   endsw
end

#-----------------------------------------------------------------------
SETUP:

if ( $help || $narg < 1 ) then
  print_script_header.csh $0
  goto FINISH
endif

# Check for software availabity:

set noskycoor =  `which skycoor |& grep "not found" | wc -l` 
if ($noskycoor) then
  echo "${0:t:r}: ERROR: no skycoor program from WCStools"
  echo "${0:t:r}: You can download it from: \
  http://tdc-www.harvard.edu/software/wcstools/"
  goto FINISH
endif
set noxy2sky =  `which xy2sky |& grep "not found" | wc -l` 
if ($noxy2sky) then
  echo "${0:t:r}: ERROR: no xy2sky program from WCStools"
  echo "${0:t:r}: You can download it from: \
  http://tdc-www.harvard.edu/software/wcstools/"
  goto FINISH
endif
set noimhead =  `which imhead |& grep "not found" | wc -l` 
if ($noimhead) then
  echo "${0:t:r}: ERROR: no imhead program from WCStools"
  echo "${0:t:r}: You can download it from: \
  http://tdc-www.harvard.edu/software/wcstools/"
  goto FINISH
endif

# Parse inputs:

if ( ! -e $fitsfile ) then
  echo "${0:t:r}: input file $fitsfile:t not found"
  goto FINISH
endif
set isfits = `file $fitsfile | grep -e FITS -e 'symbolic link' | wc -l`
if ($isfits == 0 ) then
  echo "${0:t:r}: input file $fitsfile:t is not in FITS format"
  goto FINISH
endif

# Start reading header - first get reference pixel:

if ($linear) then
  if ($centroid) then
# Ra/Dec of reference pixel already decided:
    set line = `sky2xy -n 7 $fitsfile $CRVAL1 $CRVAL2`
    set CRPIX1 = $line[5]
    set CRPIX2 = $line[6]
  else
# Choose central pixel:
    set NAXIS1 = `imhead $fitsfile | grep NAXIS1 | awk '{print $3}'`
    set NAXIS2 = `imhead $fitsfile | grep NAXIS2 | awk '{print $3}'`
    set CRPIX1 = `echo $NAXIS1 | awk '{print 0.5*$1}'`
    set CRPIX2 = `echo $NAXIS2 | awk '{print 0.5*$1}'`
    set line = `xy2sky -n 7 -d $fitsfile $CRPIX1 $CRPIX2`
    set CRVAL1 = $line[1]
    set CRVAL2 = $line[2]
  endif
  set CTYPE1  = 'RA---TAN'
  set CTYPE2  = 'DEC--TAN'
else
  set CRPIX1 = `imhead $fitsfile | grep CRPIX1 | grep -v OC | grep -v NC | grep -v CC | awk '{print $3}'`
  set CRPIX2 = `imhead $fitsfile | grep CRPIX2 | grep -v OC | grep -v NC | grep -v CC | awk '{print $3}'`
  set CRVAL1 = `imhead $fitsfile | grep CRVAL1 | grep -v OC | grep -v NC | grep -v CC | awk '{print $3}'`
  set CRVAL2 = `imhead $fitsfile | grep CRVAL2 | grep -v OC | grep -v NC | grep -v CC | awk '{print $3}'`
  set CTYPE1 = `imhead $fitsfile | grep CTYPE1 | grep -v OC | grep -v NC | grep -v CC | awk '{print $3}'`
  set CTYPE2 = `imhead $fitsfile | grep CTYPE2 | grep -v OC | grep -v NC | grep -v CC | awk '{print $3}'`
endif

# Now get CD matrix:

if ($linear) then
# Use point on i axis to work out pixel scale and rotation angle:
  set OTHERPIX1 = `echo $CRPIX1 | awk '{print $1 + 100}'`
  set OTHERPIX2 = $CRPIX2
  set line = `xy2sky -n 7 -d $fitsfile $OTHERPIX1 $OTHERPIX2`
  set OTHERVAL1 = $line[1]
  set OTHERVAL2 = $line[2]
  set dr = `skycoor -n 5 -r $CRVAL1 $CRVAL2 $OTHERVAL1 $OTHERVAL2`
  set PIXSCALE = `echo $dr | awk '{print $1 / 100.0 / 3600.0}'`
  set pa = `skycoor -n 5 -a $CRVAL1 $CRVAL2 $OTHERVAL1 $OTHERVAL2 | awk '{print $1}'`
  # BUG in skycoor -a! Need to adjust PA...
  set test = `echo $OTHERVAL1 $CRVAL1 | awk '{if($1 > $2) print 1}'` 
  if ($#test == 1) then 
    set pa = `echo $pa | awk '{print $1 * -1}'`
  endif
  set pa = `echo $pa | awk '{print ($1 + 90.0) * 0.017453292}'` 
  # And construct CD matrix:
  set CD1_1 = `echo $pa | awk '{print -cos($1)*'$PIXSCALE'}'`
  set CD1_2 = `echo $pa | awk '{print  sin($1)*'$PIXSCALE'}'`
  set CD2_1 = `echo $pa | awk '{print  sin($1)*'$PIXSCALE'}'`
  set CD2_2 = `echo $pa | awk '{print  cos($1)*'$PIXSCALE'}'`
  set PIXSCALE = `echo $PIXSCALE | awk '{print 3600.0*$1}'`
else
  set CD1_1 = `imhead $fitsfile | grep CD1_1 | grep -v OC | grep -v NC | grep -v CC | awk '{print $3}'`
  set CD1_2 = `imhead $fitsfile | grep CD1_2 | grep -v OC | grep -v NC | grep -v CC | awk '{print $3}'`
  if ($#CD1_2 == 0) set CD1_2 = 0.0
  set CD2_1 = `imhead $fitsfile | grep CD2_1 | grep -v OC | grep -v NC | grep -v CC | awk '{print $3}'`
  if ($#CD2_1 == 0) set CD2_1 = 0.0
  set CD2_2 = `imhead $fitsfile | grep CD2_2 | grep -v OC | grep -v NC | grep -v CC | awk '{print $3}'`
  set PIXSCALE = `echo $CD1_1 $CD1_2 $CD2_1 $CD2_2 | awk '{print ($1*$4 - $2*$3)}'`
  set negative = `echo $PIXSCALE | cut -c1 | grep -e '-' | wc -l`
  if ($negative) set PIXSCALE = `echo $PIXSCALE | awk '{print $1 * -1.0}'`
  set PIXSCALE = `echo $PIXSCALE | awk '{print 3600.0*sqrt($1)}'`
endif

# Compute position angle of image, from North anticlockwise to pixel Y axis:
set PA = `echo $CD2_1 $CD2_2 | awk '{print -180.0*atan2(-$1,$2)/3.141592654}'`

# Print output to screen:

if ($fortran) then
# Comma-separated output:
  echo "      DATA WCS / $CRPIX1, $CRPIX2, $CRVAL1, $CRVAL2, $CD1_1, $CD1_2, $CD2_1, $CD2_2, $PIXSCALE /"
else
  echo "CTYPE1  = $CTYPE1" 
  echo "CTYPE2  = $CTYPE2" 
  echo "CRPIX1  = $CRPIX1" 
  echo "CRPIX2  = $CRPIX2" 
  echo "CRVAL1  = $CRVAL1" 
  echo "CRVAL2  = $CRVAL2" 
  echo "CD1_1   = $CD1_1"  
  echo "CD1_2   = $CD1_2"  
  echo "CD2_1   = $CD2_1"  
  echo "CD2_2   = $CD2_2"  
  echo "PIXSCALE= $PIXSCALE arcsec"
  echo "      PA= $PA degrees (of Y-axis, anticlockwise from North)"
endif

FINISH:

#=======================================================================
