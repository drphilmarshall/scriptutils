# ======================================================================
#+
#
# NAME
#         esystem.pl
#
# PURPOSE
#         Easy system calling
#
# USAGE
#         \&esystem(\$command,\$doproc,\$vb);
#
# FLAGS
#
#
# INPUTS
#         \$command      s      Unix command, in double quotes
#         \$doproc       i      0 = dummy run, >0 = execute command
#         \$vb           i      0 = silent execution, >0 = echo command
#
#
# OPTIONAL INPUTS
#
#
# OUTPUTS
#
#
# OPTIONAL OUTPUTS
#
#
# COMMENTS
#
#
# EXAMPLES
#   \&esystem(\"rm junk\", 1, \$vb);
#
# BUGS
#   - No useful output to the screen
#
# REVISION HISTORY:
#   2005-08-15  Started Marshall (KIPAC)
#
#-
# ======================================================================

sub esystem{
    my ($command, $doproc, $vb) = @_;
    ($vb > 0) and print STDERR "$command\n";
    if ($doproc) {
       system($command);
    }
}
1;
#=======================================================================
