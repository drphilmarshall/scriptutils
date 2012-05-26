#!/usr/local/bin/perl -w
# ======================================================================
#+
$usage = "\n
NAME
        template.pl

PURPOSE
        Provide template file structure for self-documenting code

USAGE
        template.pl [flags] [options]

FLAGS
        -u               Print this message

INPUTS


OPTIONAL INPUTS
        -v      i        Verbosity (0, 1 or 2, default=0)

OUTPUTS


OPTIONAL OUTPUTS


COMMENTS


EXAMPLES


BUGS
  - No useful output to the screen

REVISION HISTORY:
  20XX-XX-XX  Started XX and YY (KIPAC)

\n";
#-
# ======================================================================

# Easy system commands:
$sdir = $ENV{'SCRIPTUTILS_DIR'};
require($sdir."/perl/esystem.pl");
$doproc = 1;

# Parse options:

use Getopt::Long;
GetOptions("v=i", \$verb,
           "u", \$help
           );

(defined($help)) and die "$usage\n";
$num=@ARGV;
($num==1) or die "$usage\n";

(defined($verb)) or ($verb = 0);

# ----------------------------------------------------------------------

# Begin code statements:

END:

# ======================================================================

