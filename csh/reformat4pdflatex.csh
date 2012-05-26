#!/bin/tcsh
# =======================================================================
#+
# NAME:
#   reformat4pdflatex
#
# PURPOSE:
#   Convert latex file and associated figures for pdflatex compatibility.
#
# COMMENTS:
#   Input file is overwritten unless otherwise specified.
#
# INPUTS:
#   file.tex              Latex file 
#
# OPTIONAL INPUTS:
#   -h --help             Online help [0]
#   -o --output $newfile  Save the output in a new file "$newfile"
#   
# OUTPUTS:
#   file*                 Now translated, overwritten files (unless -o)
#
# EXAMPLES:
#   reformat4pdflatex example.tex 
# 
# BUGS:
#
# REVISION HISTORY:
#   2005-03-14  started Marshall (KIPAC)
#   2007-04-30  reverse operation added Marshall (KIPAC)
#-
#=======================================================================

set help = 0
set overwrite = 1

set texfiles = ( )
set nfiles = 0

unset noclobber

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
   case -o:           #  output filename (or extension)
      shift argv
      set output = $argv[1]
      shift argv
      set overwrite = 0
      breaksw
   case --{output}:   
      shift argv
      set output = $argv[1]
      shift argv
      set overwrite = 0
      breaksw
   case *:            #  Files to be edited
      set texfiles = ( $texfiles $argv[1] )
      shift argv
      breaksw
   endsw
end

set nfiles = $#texfiles
if ( $help == 1 || $nfiles == 0 ) then
  print_script_header.csh $0
  goto FINISH
endif

# ------------------------------------------------------------------------------

# Welcome:

echo "${0:t}: Reformatting latex file (and associated figures) for pdflatex"
if ($overwrite) echo "${0:t}: WARNING: overwriting latex files"
echo "${0:t}: "

SETUP:


# ------------------------------------------------------------------------------

LOOP:

foreach texfile ( $texfiles )

  set backupfile = $texfile.old
  \cp -f $texfile $backupfile

# Set up output file:
  if ($overwrite) then
    set outfile = $texfile
  else  
    if ($nfiles == 1) then
      set outfile = $output
    else
      set outfile = ${texfile:r}.${output}.${texfile:e}
    endif
  endif      
  echo "${0:t}:    Input file: $texfile"
  echo "${0:t}:   Output file: $outfile"
  echo "${0:t}:   Backup file: $backupfile"

  if ($texfile != $outfile) \cp -f $texfile $outfile
  set tmpfile = $texfile.tmp ; \rm -f $tmpfile 
     
# Get list of figures:

  set psfiles = `grep epsfig $outfile | cut -d'=' -f2 | cut -d',' -f1`
  foreach psfile ( $psfiles )

# Make new figure file:
    set root1 = $psfile:r
    set root2 = `echo "$root1" | sed s/'\.'/'_'/g`
    set jpgfile1 = $root1.jpg
    set jpgfile2 = $root2.jpg
    if ($jpgfile2 == $psfile || -e $jpgfile2) then
      echo "${0:t}:     Unchanged figure: $jpgfile2"
    else if ( -e $jpgfile1 ) then
      echo "${0:t}:     Re-naming figure: $jpgfile1 -> $jpgfile2"
      \cp -i $jpgfile1 $jpgfile2
    else
      echo "${0:t}:    Converting figure: $psfile -> $jpgfile2"
      convert -q 95 $psfile $jpgfile2
    endif
    
# Re-write tex:      
    mv $outfile $tmpfile
    cat $tmpfile | sed s/"$psfile"/"$jpgfile2"/g > $outfile 
                     
  end     
     
  echo "${0:t}:   Written output file to disk"
  \rm $tmpfile
     
end # of loop over input files

# ==============================================================================
FINISH:
