#!/bin/tcsh
#=============================================================================
#+
# NAME:
#   getttstar
#
# PURPOSE:
#   Query SDSS website for star list, and identify suitable tip tilt 
#   stars for AO observation.
#
# COMMENTS:
#  Only works for targets in SDSS!
#
# USAGE:
#       getttstar [-h][-r radius -m maglimit -n IAUname] ra dec
#
# INPUTS:
#   ra dec                 position of object in degrees
#
# OPTIONAL INPUTS:
#   -h --help
#   -n --name  string      provide parsable IAU-style name instead of ra/dec
#   -r --search-radius  r  search radius for stars / arcsec
#   -m --mag-limit      m  magnitude limit (R-band Vega, unless -V)
#   -V --use-V-mag         Use Vega V band mag for star list, not R
#   --hms                  coords supplied in hms dms not degrees
#
# OUTPUTS:
#
# EXAMPLES:
#
#   SDSSJ0737+3216:
#
#     getttstar -r 60 -m 18 --hms 07:37:28.45  +32:16:18.6
# 
#
# DEPENDENCIES:
#   
#   skycoor, getttstar -> wget
#
# BUGS:
#  
# REVISION HISTORY:
#   2008-11-07  started Marshall (KIPAC)
#-
#=============================================================================

# Options and arguments:

set narg = $#argv

# Set defaults:

unset ra0
unset dec0

set usename = 0
set name = 0

set maglimit = 18
set maxsep = 60
set useV = 0
set hms = 0

set help = 0

# Escape shell defaults
unset noclobber
unalias rm

set starlist = 0
set csvfile = 0
set catfile = 0

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
   case -r:        #  maximum object-star separation
      shift argv
      set maxsep = $argv[1]
      shift argv
      breaksw
   case --{radius-limit}:
      shift argv
      set maxsep = $argv[1]
      shift argv
      breaksw
   case -m:        #  maximum acceptable tt-star magnitude
      shift argv
      set maglimit = $argv[1]
      shift argv
      breaksw
   case --{mag-limit}:
      shift argv
      set maglimit = $argv[1]
      shift argv
      breaksw
   case -V:        #  Use Vega V mag for star selection?       
      shift argv
      set useV = 1
      breaksw
   case --{use-V-mag}:           
      shift argv
      set useV = 1
      breaksw
   case --{hms}:   #  Coords input in hms dms?       
      shift argv
      set hms = 1
      breaksw
   case -n:  # Input is name, not ra/dec!      
      shift argv
      set usename = 1
      set name = $argv[1]
      shift argv
      set ra0 = -99
      set dec0 = -99
      breaksw
   case --{name}:  
      shift argv
      set usename = 1
      set name = $argv[1]
      shift argv
      set ra0 = -99
      set dec0 = -99
      breaksw
   case *:         #  ra and dec!
      if ($usename == 0) then
        set ra0 = $argv[1]
        shift argv
        set dec0 = $argv[1]
        shift argv
      else
        shift argv
      endif  
      breaksw
   endsw
end

#-----------------------------------------------------------------------
SETUP:

if ( $help || $narg < 2 ) then
  print_script_header.csh $0
  goto FINISH
endif

echo "getttstar: find suitable tip-tilt stars for AO observations"

# Check for software availabity:

set noskycoor =  `which skycoor |& grep "not found" | wc -l` 
if ($noskycoor) then
  echo "${0:t:r}: ERROR: no skycoor program for translating coordinates"
  echo "${0:t:r}: You can download it from: \
  http://tdc-www.harvard.edu/software/wcstools/skycoor.html"
  goto FINISH
endif

# Parse inputs:

if ( ! $?ra0 ) then
  echo "getttstar: no RA specified"
  goto FINISH
endif
if ( ! $?dec0 ) then
  echo "getttstar: no dec specified"
  goto FINISH
endif

# Expand radius and mag limits a little bit to be more inclusive in the first
# pass:

set rmax = `echo $maxsep | awk '{print $1*1.33}'`
set field = `echo $rmax | awk '{printf "%.2f", 2*$1/60.0}'`
set magmax = `echo $maglimit | awk '{print $1+1.5}'`

echo "getttstar: searching for bright stars (mag < $magmax)"
echo "getttstar:   within $rmax arcsec of target, ie within a "
echo "getttstar:   square field of regard $field arcmin on a side"
echo "getttstar: tip-tilt stars with R < $maglimit and sep < $maxsep"
echo "getttstar:   will then be selected"

# Set up options to askSDSS script:

set inputs = " -f -w $field -s -r $rmax -m $magmax"
if ($useV) set inputs = "$inputs -V"
if ($usename) then 
  set inputs = "$inputs -n $name"
else
  if ($hms)  set inputs = "$inputs --hms"
  set inputs = "$inputs $ra0 $dec0"
endif  
  
# OK, now pull out coordinates and make catalogues and finding charts

set logfile = askSDSS.log ; touch $logfile ; \rm $logfile

askSDSS $inputs >>& $logfile

echo "getttstar: askSDSS returned, log:"
cat $logfile

# Check for starlist:

set starlist = `grep stars.txt askSDSS.log`

if ($#starlist == 0) then
  echo "ERROR: no starlist made, exiting"
  goto FINISH 
else if (! -e $starlist || -z $starlist) then
  echo "ERROR: starlist $starlist not made properly, exiting"
  goto FINISH 
endif

set csvfile = `grep '\.csv' askSDSS.log`
set catfile = `grep '\.cat' askSDSS.log`
set jpgfile = `grep '\.jpg' askSDSS.log`
echo "getttstar: colour jpg image of field stored in "
echo "  $jpgfile"

# Rename log file:
set askSDSSlogfile = $starlist:r.askSDSS.log
mv askSDSS.log $askSDSSlogfile


# Good, got starlist - now make target list:

set rahms = `grep 'ra (J2000)' $askSDSSlogfile | cut -c22-`
set decdms = `grep 'dec (J2000)' $askSDSSlogfile | cut -c23-`
set target = "SDSSJ${rahms[1]}${rahms[2]}${decdms[1]}${decdms[2]}"

set targetlist = $target.tel; \rm -f $targetlist
echo "getttstar: processing askSDSS star list into target list:"

# First get zmag of lens galaxy:
set seps = `tail -n +2 $starlist | awk '{ print $2}'`
set k=0
while ( $k < $#seps )
  @ k ++
  if ( $seps[$k]:r == 0 ) goto GRABZLINE
end
GRABZLINE:
@ k ++
set zinfo = `tail -n +$k $starlist | head -1`
set zmag = $zinfo[6]

# Print target line to stdout:  
echo "$target   $rahms  $decdms  2000.00  lgs=1 zmag=$zmag"   >> $targetlist

# Now search for tip tilt stars:
set start = 2
set end = `cat $starlist | wc -l`
GRABTTLINE:
if ($start > $end) goto CONTINUE
set ttinfo = `tail -n +$start $starlist | head -1`
set sep = $ttinfo[2]
# Check for star = target:
if ( $sep:r == 0 ) then
  @ start ++
  goto GRABTTLINE
endif
# Check separation of star:
set fail = `echo $sep $maxsep | awk '{if ($1 > $2) print 1; else print 0}'`
if ($fail) then 
  @ start ++
  goto GRABTTLINE
endif
# Check magnitude of star:
set rmag = $ttinfo[1]   
set fail = `echo $rmag $maglimit | awk '{if ($1 > $2) print 1; else print 0}'`
if ($fail) then 
  @ start ++
  goto GRABTTLINE
endif
set dx = $ttinfo[3]   
set dy = $ttinfo[4]   
set colour = $ttinfo[5] 
# Convert deg to hms for star coords:    
set sra = $ttinfo[7]
set sdec = $ttinfo[8]
set line = `skycoor -n 2 $sra $sdec`
set srahms = ( `echo "$line[1]" | sed s/:/\ /g` )
set sdecdms = ( `echo "$line[2]" | sed s/:/\ /g` )
set starname = "${srahms[1]}${srahms[2]}${srahms[3]:r}${sdecdms[1]}${sdecdms[2]}${sdecdms[3]:r}"

# Print star info to file:  
echo "  $starname  $srahms  $sdecdms  2000.00  rmag=$rmag sep=$sep dx=$dx dy=$dy g-r=$colour"  >> $targetlist

# Get all suitable stars!
@ start ++
goto GRABTTLINE

CONTINUE:
echo "  $targetlist"
echo "getttstar: targetlist contents are:"
cat $targetlist


# Ok, read off best one and write out Best line:

set best = `tail -n +2 $targetlist | head -1`
if ($#best == 0) then
  set ttname = '---'
  set ttra   = 0
  set ttdec  = 0
  set ttmag  = 99
  set ttsep  = 99
  set ttdx   = 99
  set ttdy   = 99
  set AO = 0
else
  set ttname = $best[1]
  set x = `skycoor -d ${best[2]}:${best[3]}:${best[4]}  ${best[5]}:${best[6]}:${best[7]}`
  set ttra   = $x[1]
  set ttdec  = $x[2]
  set ttmag  = `echo $best[9] | sed s/'rmag='//g`
  set ttsep  = `echo $best[10] | sed s/'sep='//g`
  set ttdx   = `echo $best[11] | sed s/'dx='//g`
  set ttdy   = `echo $best[12] | sed s/'dy='//g`
  set AO = 1
endif  
set ttpa   = 0

echo "Best tip-tilt star data:"
echo "# AO  ttname         ttRA       ttDEC     ttmag  ttsep  ttdx  ttdy   ttpa"
echo "  $AO   $ttname  $ttra  $ttdec  $ttmag  $ttsep  $ttdx  $ttdy  $ttpa"

#=============================================================================
FINISH:

\rm -f $csvfile $catfile $askSDSSlogfile $starlist
