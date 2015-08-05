
# script utilities

Short shell, perl and python programs written to make easy tasks faster and less tedious.

### Contributors, License etc

* Phil Marshall (KIPAC)
* Marusa Bradac (UC Davis)
* Doug Applegate (Bonn)

Pull requests welcome! I've tried to homogenise the headers so that the code is self-documenting: if you make improvements, do make sure you document your changes to help us understand what is going on. All scripts are Copyright 2005-2012 The Authors, and are distributed under the MIT Licence. 

### Installation

If you put the module in your home directory, you'll need these additions to
your .login file:

    setenv SCRIPTUTILS_DIR ${HOME}/scriptutils
    setenv PATH ${PATH}:${SCRIPTUTILS_DIR}/perl
    setenv PATH ${PATH}:${SCRIPTUTILS_DIR}/csh

etc. You'll also need to have PGPLOT.pm on your path - at KIPAC that means setting

    setenv GROUP_SOFT_DIR /afs/slac/g/ki/ki04/soft
    setenv PERL5LIB $GROUP_SOFT_DIR/perl/lib/site_perl/5.8.4/i386_linux24

This module is also checked out into the KIPAC group software space in case you don't want to edit the scripts, just to use them. In this case, you'd need

> setenv SCRIPTUTILS_DIR ${GROUP_SOFT_DIR}/scriptutils

instead of the definition above.

At least for the csh scripts the --help option will print a helpful message;
some of the perl scripts have -u (for usage) instead.
