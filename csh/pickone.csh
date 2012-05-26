#!/bin/tcsh
#=============================================================================
#+
# NAME:
#   pickone
#
# PURPOSE:
#   From a list of things, pick one
#
# COMMENTS:
#   Started with "nearest" option in mind. Probably there are other
#   applications.
#
# USAGE:
#       pickone [-n --nearest $thing] $things
#
# INPUTS:
#   $thing                  List of things
#
# OPTIONAL INPUTS:
#   -n --nearest $thing     Thing to pick nearest one to   
#   -l --last               Pick last one (in a numerically sorted sense)  
#   -f --first              Pick first one (in a numerically sorted sense)  
#   -i --index              Return index of thing, not thing  
#   -h --help
#
# OUTPUTS:
#   stdout
#
# EXAMPLES:
#
#   pickone.csh -n 2.0  1.1 1.3 1.9 2.11 2.2 2.4
#    1.9
# 
# DEPENDENCIES:
#
# BUGS:
#  
# REVISION HISTORY:
#   2008-08-25 started Marshall (UCSB)
#-
#=======================================================================

unset noclobber

# Set defaults:

set help = 0
set things = ()
set thing = 0
set answer = 0
set first = 0
set last = 0
set nearest = 0
set index = 0

# Parse command line, putting every thing into a file:
set tmpfile = /tmp/pickone`date +%H%M%S.%N`
\rm -f $tmpfile ; touch $tmpfile

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
   case -f:
      set first = 1
      shift argv
      breaksw
   case --{first}:
      set first = 1
      shift argv
      breaksw
   case -l:
      set last = 1
      shift argv
      breaksw
   case --{last}:
      set last = 1
      shift argv
      breaksw
   case -n:           #  pick the nearest one
      shift argv
      set nearest = 1
      set thing = "$argv[1]"
      shift argv
      breaksw
   case --{nearest}:  
      shift argv
      set nearest = 1
      set thing = "$argv[1]"
      shift argv
      breaksw
   case -i:
      set index = 1
      shift argv
      breaksw
   case --{index}:
      set index = 1
      shift argv
      breaksw
   case *:            #  list of things to be picked from
#       set things = ( $things $argv[1] )
      echo " $argv[1] " >> $tmpfile
      shift argv
      breaksw
   endsw
end

#-----------------------------------------------------------------------

set nthings = `cat $tmpfile | wc -l`

if ($help || $nthings == 0) then
  print_script_header.csh $0
  goto FINISH
endif

# Now sort etc to pick the right one:
if ($first) then
  set answer = `sort -n $tmpfile | head -1`
else if ($last) then
  set answer = `sort -n $tmpfile | tail -1`
else if ($nearest) then
  set lower = `awk '{if ($1 <= '$thing') print $1}' $tmpfile | sort -n | tail -1`
  set upper = `awk '{if ($1 >= '$thing') print $1}' $tmpfile | sort -n | head -1`
  set answer = `echo $thing $lower $upper | \
    awk '{if (($1-$2) < ($3-$1)) print $2; else print $3}'`
endif  

if ($index) then
  set i = `grep -n " $answer " $tmpfile | cut -d':' -f1`
  echo "$i"
else
  echo "$answer"
endif

FINISH:

#=======================================================================
