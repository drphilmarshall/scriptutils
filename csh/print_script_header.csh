#!/bin/tcsh
#===============================================================================
#+
# NAME:
#   print_script_header.csh
#
# PURPOSE:
#   Given a list of scripts, print the script headers
#
# COMMENTS:
#
#
# USAGE:
#         print_script_header.csh \
#             [-h --help] \
#             [-v --verbose] \
#             script1 script2 ..."
# INPUTS:
#   scripti        The name of the script(s)
#
# OPTIONAL INPUTS:
#    help         Print this header
#    verbose      Verbose output (print script name first...)
#
# OUTPUTS:
#   stdout		Script header (between #+ and #-)
#
# EXAMPLES:
#
# BUGS:
#
# REVISION HISTORY:
#   2006-10-26  started Marshall (UCSB)
#-
#===============================================================================

# Set defaults

set help = 0
set vb = 0
set scripts = ()

# Parse the command line

if ( $#argv == 0 ) then
    set help = 1
endif

while ( $#argv > 0 )
   switch ($argv[1])
# Print help:
   case -h:           
      shift argv
      set help = 1
      breaksw
   case --help:        
      shift argv
      set help = 1
      breaksw
#  Be verbose
   case -v:        
      shift argv
      set vb = 1
      breaksw
   case --{verbose}:        
      shift argv
      set vb = 1
      breaksw
# The rest of the command line:
   case *:         
      set scripts = ( $scripts $argv[1] )
      shift argv
      breaksw
   endsw
end

# Loop over scripts:

if ( $help ) then
  shag_print_script_header.csh $0
endif 

foreach script ( $scripts )

   echo 
   
   if ($vb) \
echo "*************************************************************************"
   
   if ( ! -e $script ) then
     echo "\n File not found: $script"
     goto NEXT
   endif  
     
   
   set i = `grep -n '#+' $script | head -1 | cut -d':' -f1`  
   set j = `grep -n '#-' $script | head -1 | cut -d':' -f1`
   @ j --
   @ n = $j - $i
   echo "\n" ; head -$j $script | tail -$n | cut -c2- ; echo "\n"
  
NEXT:   
end   
   if ($vb) \
echo "*************************************************************************"

FINISH:
#===============================================================================
