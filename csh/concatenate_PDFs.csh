#!/bin/tcsh
#===============================================================================
#+
# NAME:
#   concatenate_PDFs.csh
#
# PURPOSE:
#   Given a list of PDFs, join them together into a single PDF file.
#
# COMMENTS:
#
#
# USAGE:
#         concatenate_PDFs.csh \
#             [-h --help] \
#             [-v --verbose] \
#             [-o --output all.pdf]
#             file1.pdf file2.pdf ..."
# INPUTS:
#   *.pdf         List of PDF files
#
# OPTIONAL INPUTS:
#    help         Print this header
#    verbose      Verbose output
#    output       Name of target PDF file
#
# OUTPUTS:
#   all.pdf       Combined PDF file [all.pdf]
#
# EXAMPLES:
#
# BUGS:
#
# REVISION HISTORY:
#   2021-11-23  started Marshall (SLAC)
#-
#===============================================================================

# Set defaults

set help = 0
set vb = 0
set output = "all.pdf"
set files = ()

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
      #  Be verbose
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
      # The rest of the command line:
   case *:
      set files = ( $files "${argv[1]}" )
      shift argv
      breaksw
   endsw
end

if ( $help ) then
  print_script_header.csh $0
  goto FINISH
endif

if ( $vb ) then
  echo "Concatenating $#files PDF files with pdftk as follows:"
  echo "  pdftk $files cat output $output"
endif

pdftk $files cat output $output

if ($vb) then
  echo "Concatenated PDF file is ${output}, size = "`du -h $output | cut -f1`
endif

FINISH:
#===============================================================================
