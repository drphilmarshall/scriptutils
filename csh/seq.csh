#!/bin/tcsh
#=============================================================================
#+
# NAME:
#   seq.csh
#
# PURPOSE:
#   Emulate unix seq command (not available in leopard)
#
# COMMENTS:
#
# USAGE:
#       seq  n
#
# INPUTS:
#   n                      Integer (or array of 2, or 3 integers)
#
# OPTIONAL INPUTS:
#   -w                     Equalize widths of output (zero-pad)
#   -h --help
#
# OUTPUTS:
#
# EXAMPLES:
#
#   seq 10
#     1 2 3 4 5 6 7 8 9 10
#   seq -w 10
#     01 02 03 04 05 06 07 08 09 10
#   seq -3 5
#     -3 -2 -1 0 1 2 3 4 5
#   seq 1 41 286
#     1 42 83 124 165 206 247 
#
# DEPENDENCIES:
#
# BUGS:
#  
# REVISION HISTORY:
#   2008-03-10  started Marshall (UCSB)
#   2008-09-17  added -w option, variable step length Marshall (UCSB)
#-
#=======================================================================

unset noclobber

# Set defaults:

set help = 0
set pad = 0
set n = ()

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
   case -w:           #  pad with zeros to equal width output
      set pad = 1
      shift argv
      breaksw
   case *:
      set n = ( $n $argv[1] )
      shift argv
      breaksw
   endsw
end

#-----------------------------------------------------------------------

if ($help || $#n == 0 || $#n > 3) then
  print_script_header.csh $0
  goto FINISH
endif

set sequence = ()

if ($#n == 2) then
  @ i = $n[1]
  set di = 1
else if ($#n == 3) then
  @ i = $n[1]
  set di = $n[2]
else
  set i = 1
  set di = 1
endif
while ( $i <= $n[$#n] )
  set sequence = ( $sequence $i )  
  @ i = $i + $di
end

if ($pad) then
# Add zeros to equalize widths:
  @ width = `echo $sequence[$#sequence] | wc -c` - 1
  set padding = ''
  set x = ()
  set j = 0
  while ( $j < $width )
    @ j ++
    set padding = "0$padding"
    set x = ( $x $padding )
  end
  set i = 0
  while ($i < $#sequence)
    @ i ++ 
    @ thiswidth = `echo $sequence[$i] | wc -c` - 1
    @ diff = $width - $thiswidth
    if ($diff > 0) then
      set sequence[$i] = "$x[$diff]$sequence[$i]"
    endif
  end
endif
    
echo $sequence

FINISH:

#=======================================================================
