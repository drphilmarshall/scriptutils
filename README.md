# ==============================================================================
#
# This is the KIPAC script utilities directory, containing short shell, perl and
# one day python programs written to make easy tasks easy.
#
# Contributors:
#     Phil Marshall     pjm at slac.stanford.edu
#     Marusa Bradac     marusa
#     Marissa Cevallos  marissa
#     Caius Howcroft    howcroft
#
# History:
#     Started 2005-08-12
#     Linked to SLAC website 2007-02-19
#     Uploaded to github 2012-05-25
#
# ==============================================================================
#
# The scripts are organised by language - hopefully we won't need more than
# this. I've tried to homogenise the headers so that the code is
# self-documenting: if you have cvs access, and make improvements and commit
# them, do make sure you document your changes.
#
# If you put the module in your home directory, you'll need these additions to
# your .login file:

setenv SCRIPTUTILS_DIR ${HOME}/scriptutils
setenv PATH ${PATH}:${SCRIPTUTILS_DIR}/perl
setenv PATH ${PATH}:${SCRIPTUTILS_DIR}/csh

# etc. You'll also need to have PGPLOT.pm on your path - at KIPAC that means setting

setenv GROUP_SOFT_DIR /afs/slac/g/ki/ki04/soft
setenv PERL5LIB $GROUP_SOFT_DIR/perl/lib/site_perl/5.8.4/i386_linux24

# This module is also checked out into the KIPAC group software space in case
# you don't want to edit the scripts, just to use them. In this case, you'd need

setenv SCRIPTUTILS_DIR ${GROUP_SOFT_DIR}/scriptutils

# instead of the definition above.
#
# If you want to share these scripts round the world on a readonly basis,
# point them at this weblink:

http://www.slac.stanford.edu/~pjm/scriptutils

# To get all the scripts you can do the following:

wget http://www.slac.stanford.edu/~pjm/scriptutils/csh/wgetdir
chmod a+x wgetdir 
./wgetdir -v  http://www.slac.stanford.edu/~pjm/scriptutils

# The repository is visible here (with the CVS details hidden). Anyone can
# contribute to the project by emailing me suggested changes (in the form of
# edited, documented, new versions) and I will check them in for you.
#
# At least for the csh scripts the --help option will print a helpful message;
# some of the perl scripts have -u (for usage) instead.
#
#
# PJM 2007-02-19
# ===============================================================================
