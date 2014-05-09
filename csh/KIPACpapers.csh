#!/bin/tcsh
#=======================================================================
#+
# NAME:
#   KIPACpapers.csh
#
# PURPOSE:
#   Query ADS2.0 website for KIPAC publications.
#
# COMMENTS:
#
# USAGE:
#       KIPACpapers.csh [--recent --email]
#
# INPUTS:
#
# OPTIONAL INPUTS:
#   -h --help
#   --recent               Just get the last month's publications
#   --email                Compose and send a summary email to everyone@kipac
#   --dry-run              Do everything except send the email
#
# OUTPUTS:
#
# EXAMPLES:
#
#   KIPACpapers.csh --email 
#
# DEPENDENCIES:
#   
#   wget, lynx
#
# BUGS:
#  
# REVISION HISTORY:
#   2014-05-09  started Marshall (KIPAC)
#-
#=======================================================================

# Options and arguments:

set help = 0

# Set defaults:

set email = 0
set dryrun = 0
set recent = 0

# Escape shell defaults
unset noclobber
unalias rm

# Parse command line:

while ( $#argv > 0 )
   switch ($argv[1])
   case -h:
      set help = 1
      shift argv
      breaksw
   case --{help}:  
      set help = 1
      shift argv
      breaksw
   case --{email}:  
      set email = 1
      set recent = 1
      shift argv
      breaksw
   case --{dry-run}:  
      set dryrun = 1
      shift argv
      breaksw
   case --{recent}:  
      set recent = 1
      shift argv
      breaksw
   case *:
      shift argv
      breaksw
   endsw
end

#-----------------------------------------------------------------------

SETUP:

if ( $help ) then
  more `which $0`
  goto FINISH
endif

echo "${0:t:r}: Querying the ADS2.0 website for KIPAC publications"

# Check for software availabity:

set nowget = `which wget |& grep "not found" | wc -l`
if ($nowget) then
  echo "${0:t:r}: ERROR: no wget for downloading ADS results"
  goto FINISH
endif
set nolynx = `which lynx |& grep "not found" | wc -l`
if ($nolynx) then
  echo "${0:t:r}: ERROR: no lynx for downloading ADS results"
  goto FINISH
endif

set stem = "KIPACpapers"
set htmlfile = "${stem}.html"
set txtfile = "${stem}.txt"
set titles = "${stem}.titles"
set adsurls = "${stem}.adsurls"
set authors = "${stem}.authors"
\rm -f $htmlfile $txtfile $titles $adsurls $authors

#-----------------------------------------------------------------------

# The following search returns publications in journals (not arxiv only)
# by searching by affiliation for KIPAC or "Kavli Institute for Particle
# Astrophysics and Cosmology"
# 
# set url = "http://labs.adsabs.harvard.edu/adsabs/search/?q=+aff%3A%22KIPAC%22+OR+aff%3A%22Kavli+Institute+for+Particle+Astrophysics+and+Cosmology%22&month_from=&year_from=&month_to=&year_to=&db_f=%28astronomy+OR+physics%29&nr=50&article=1&bigquery="
# 
# This is aliased to http://tinyurl.com/KIPAConADS

if ($recent) then
    set endmonth = `date +'%m'`
    set startmonth = `echo $endmonth | awk '{if ($1 == 1) print 12; else print $1-1}'`
    set endyear = `date +'%Y'`
    set startyear = `echo $endmonth $endyear | \
                      awk '{if ($1 == 12) print $2-1; else print $2}'`
    echo "${0:t:r}: Fetching recent publications (from ${startmonth}/${startyear} to ${endmonth}/${endyear})"              
else
    set startmonth = ''
    set startyear = ''
    set endmonth = ''
    set endyear = ''
    echo "${0:t:r}: Fetching all publications"              
endif

# Compose URL:

set url = "http://labs.adsabs.harvard.edu/adsabs/search/?q=+aff%3A%22KIPAC%22+OR+aff%3A%22Kavli+Institute+for+Particle+Astrophysics+and+Cosmology%22&month_from=${startmonth}&year_from=${startyear}&month_to=${endmonth}&year_to=${endyear}&db_f=%28astronomy+OR+physics%29&nr=50&article=1&bigquery="
# open "$url"

# Read some information from this html:

lynx --dump --nolist "$url" > $txtfile
set Npapers = `grep Previous $txtfile | grep Next | cut -d'|' -f2 | awk '{print $5}'`
set Ncitations = `grep Cited $txtfile | awk '{sum+=$3} END {print sum}'`

wget -O $htmlfile "$url" >& /dev/null
grep '<div class="span12 title">' $htmlfile | cut -d'>' -f3 | cut -d'<' -f1 > $titles
grep '<div class="span12 title">' $htmlfile | cut -d'"' -f4 > $adsurls
# set index = `grep -n "Published in" $txtfile | cut -d':' -f1`
# echo $index
# foreach i ( $index )
#   @ j = $i - 1
#   tail -n +$j $txtfile | head -1 >> $authors
#   echo $i $j $txtfile
#   tail -n +$j $txtfile | head -1
# end
    
set Ntitles = `cat $titles | wc -l`
set Nadsurls = `cat $adsurls | wc -l`
# set Nauthors = `cat $authors | wc -l`

if ($Ntitles != $Npapers) then
    echo "ERROR: found $Npapers papers but only $Ntitles titles..."
    goto FAIL
endif

if ($Nadsurls != $Npapers) then
    echo "ERROR: found $Npapers papers but only $Ntitles titles..."
    goto FAIL
endif

# if ($Nauthors != $Nauthors) then
#     echo "ERROR: found $Npapers papers but only $Nauthors authorlists..."
#     goto FAIL
# endif

# Loop over papers, adding titles and links:

foreach k ( `seq $Npapers` )

    echo " "
    tail -n +$k $titles | head -1
#     tail -n +$k $authors | head -1
    set extension = `tail -n +$k $adsurls | head -1`
    echo "http://${extension}"
    
end 
echo " "
    
# Clean up:

\rm -f $htmlfile $txtfile $titles $adsurls $authors

goto FINISH

#-----------------------------------------------------------------------

FAIL:

echo "Check the following files for problems:"
\ls ${stem}*

FINISH:

#=======================================================================
