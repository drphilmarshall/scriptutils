
script utilities: short shell, perl and python programs written to make easy
tasks faster and less tedious.

Contributors:
    Phil Marshall     pjm at slac.stanford.edu
    Marusa Bradac     marusa
    Doug Applegate    dapple

History:
    Started 2005-08-12
    Uploaded to github 2012-05-25


The scripts are organised by language - hopefully we won't need more than
this. I've tried to homogenise the headers so that the code is
self-documenting: if you have cvs access, and make improvements and commit
them, do make sure you document your changes.

If you put the module in your home directory, you'll need these additions to
your .login file:

> setenv SCRIPTUTILS_DIR ${HOME}/scriptutils
> setenv PATH ${PATH}:${SCRIPTUTILS_DIR}/perl
> setenv PATH ${PATH}:${SCRIPTUTILS_DIR}/csh

etc. You'll also need to have PGPLOT.pm on your path - at KIPAC that means setting

> setenv GROUP_SOFT_DIR /afs/slac/g/ki/ki04/soft
> setenv PERL5LIB $GROUP_SOFT_DIR/perl/lib/site_perl/5.8.4/i386_linux24

This module is also checked out into the KIPAC group software space in case
you don't want to edit the scripts, just to use them. In this case, you'd need

> setenv SCRIPTUTILS_DIR ${GROUP_SOFT_DIR}/scriptutils

instead of the definition above.


Anyone can contribute to the project by forking the code, editing it and then
submitting a pull request.

At least for the csh scripts the --help option will print a helpful message;
some of the perl scripts have -u (for usage) instead.
