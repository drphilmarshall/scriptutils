#!/bin/tcsh
#=======================================================================
#+
# NAME:
#   findclusters.csh
#
# PURPOSE:
#   Read in a catalogue of coordinates and looks for clusters near them, using NED and askNED
#
# COMMENTS:
#
#
# INPUTS:
#   cat1                   A catalog of coordinates, in degrees
#
# OPTIONAL INPUTS:
#   -h --help              print this header
#   -v --verbose           verbose operation
#   -o --output  outfile   output filename
#
# OUTPUTS:
#   outfile
#
# EXAMPLES:
#   pastecats.csh old.cat new.txt 
#
# BUGS:
#   - incomplete header documentation
#   - if input is plain text and contains text format fields (not numbers)
#     then the output imcat will be corrupted
#  
# REVISION HISTORY:
#   2008-04-04  Started TT (UCSB)
#-
#=======================================================================

# Options and arguments:

set help = 0
set vb = 0
set imcat = 0
set asciisex = 0
set asciisexin = 0
set output = 0
set writeheader = 0
set specialname = 0
set guesscolumnames = 0
set maxsep = 10
set input = ""

# Parse command line:

while ( $#argv > 0 )
   switch ($argv[1])
   case -h:       
      shift argv
      set help = 1
      breaksw
   case --{help}:   
      shift argv
      set help = 1
      breaksw
   case -v:       
      shift argv
      set vb = 1
      breaksw
   case --{verbose}:   
      shift argv
      set vb = 1
      breaksw
   case -r:       
      shift argv
      set maxsep = $argv[1]
      shift argv
      breaksw
   case --{radius}:
      shift argv
      set maxsep = $argv[1]
      shift argv
      breaksw
   case -o:       
      shift argv
      set output = $argv[1]
      shift argv
      breaksw
   case --{output}:
      shift argv
      set output = $argv[1]
      shift argv
      breaksw
   case *:         
      set input = $argv[1]
      shift argv
      breaksw
   endsw
end

if ($help) then
  print_script_header.csh $0
  goto FINISH
endif


#-----------------------------------------------------------------------
LOOPS:

set obj = `cat $input | awk '{print $1}'`
set ra = `cat $input | awk '{print $2}'`
set dec = `cat $input | awk '{print $3}'`

\rm $output
echo $output
echo '#Clusters matched to catalog' $input >& $output
set nobj = `cat $input | wc -l`
echo $nobj
foreach ii ( `seq $nobj`  )
     askNED -r $maxsep $ra[$ii] $dec[$ii]
#finds file name
    set line = `skycoor $ra[$ii] $dec[$ii]`
    set rahms = `echo "$line[1]" | sed s/:/\ /g`
    set rah = $rahms[1]
    set ram = $rahms[2] 
    set ras = `echo "$rahms[3]" | cut -c 1-5`
    set dechms = `echo "$line[2]" | sed s/:/\ /g`
    set decd = $dechms[1]
    set decm = $dechms[2] 
    set decs = `echo "$dechms[3]" | cut -c 1-4`
    set decsign = ''
 
    set name = "J$rah$ram$ras$decsign$decd$decm$decs"

     set fileroot = ${name}_${maxsep}arcmin
     set filename = $fileroot.txt
#     set filename = `ls -tr *arcmin.txt | tail -1`
     set nclusters = `cat $filename | wc -l`     
     echo $filename,$nclusters
     foreach jj ( `seq $nclusters`  )
	set clusterentry = `cat $filename | head -$jj | tail -1` 	
	echo $jj,$clusterentry
	echo $obj[$ii] $ra[$ii] $dec[$ii] $nclusters $clusterentry >>& $output
     end
     set jj = 1
end

FINISH:

#=======================================================================
