# ======================================================================
#+
#
# NAME
#         trimwhitespace.pl
#
# PURPOSE
#         Remove whitespace from a string
#
# USAGE
#         \&trimwhitespace(\$string);
#
# FLAGS
#
#
# INPUTS
#         \$string      s      Spaced out string
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
#   \&trimwhitespace(\$stupidwindowsfilename);
#
# BUGS
#
# REVISION HISTORY:
#   2006-06-29  Started Bradac (KIPAC) in sex2imcat.pl
#   2007-04-06  Achieves independent subroutine status under Marshall (UCSB)
#
#-
# ======================================================================

sub trimwhitespace($)
{
        my $string = shift;
        $string =~ s/^\s+//;
        $string =~ s/\s+$//;
        return $string;
}
1;

#=======================================================================
