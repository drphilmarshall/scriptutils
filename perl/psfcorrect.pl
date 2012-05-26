#!/usr/local/bin/perl -w
# ======================================================================
#+
$usage = "

NAME
        psfcorrect.pl

PURPOSE
        Correct ellipticities in object catalogue, given a stars 
        catalogue, using the KSB95 algorithm and imcat.

USAGE
        psfcorrect.pl [flags] [options] \$stars.cat \$project.cat 

FLAGS
        -u            print this message
        -clean        overwrite intermediate files
        -fitPg        use fitted Pg values rather than individuals

INPUTS
        \$stars.cat    Text catalogue of stars
        \$project.cat  Text catalogue of galaxies

OPTIONAL INPUTS
        -v verb       verbosity level (def=1)
        -o outfile    write output to \"outfile\" (def=file.*.gamma.cat)
        -p order      select order of polynomial for ellipticity fit (def=3)
        -q order      select order of polynomial for Pg fit (def=3)

OUTPUTS
        \$project.master.cat or some explicitly named catalogue

EXAMPLES

BUGS
        - THIS CODE IS MASSIVELY UNDER-COMMENTED
        - gen2dpolymodel always uses \"x\" not the coordinate specified... 

REVISION HISTORY:
        2003-05-?? Started Czoske (Bonn) and Marshall (MRAO)
        2005-08-24 Various upgrades by Bradac and Norte (KIPAC)
        2006-06-14 No FitPG code fixed Marshall (KIPAC)

\n";
#-
# ======================================================================

$sdir = $ENV{'SCRIPTUTILS_DIR'};
require($sdir."/perl/esystem.pl");
$doproc = 1;

use Getopt::Long;
GetOptions("o=s", \$outfile,
           "p=i", \$order,    
           "q=i", \$pgorder,    
	     "fitPg", \$fitPg,
	     "clean", \$clean,
	     "u", \$help
	    );

(defined($help)) and die "$usage\n";
$num=@ARGV;
($num>0) or die "$usage\n";

$dofit=0;
(defined($fitPg)) and ($dofit = 1);

$sensible=0;
(defined($outfile)) or ($sensible = 1);

(defined($verb)) or ($verb = 1);

(defined($order)) or ($order=3);
(defined($pgorder)) or ($pgorder=3);

#-----------------------------------------------------------------------

# Check for imcat environment:

(defined($ENV{"IMCATDIR"})) or die "Imcat environment undefined.\n"; 

# Check for existence of catalogues:

$starcat = shift @ARGV;
(-e $starcat) or die "psfcorrect: $starcat not found.\n";
$objcat = shift @ARGV;
(-e $objcat) or die "psfcorrect: $objcat not found.\n";

# Set up filename root and output filenames:

$objroot = $objcat;
$objroot =~ s/(.*)\..*/$1/;

$starroot = $starcat;
$starroot =~ s/(.*)\..*/$1/;

$epolycat = $starroot.".e.p".$order;
$psmpolycat = $starroot.".psm.p".$order;
$pshpolycat = $starroot.".psh.p".$order;
$corrstarcat = $starroot.".p".$order.".cat";

# $cutcat = $objroot.".cut.cat";
$corrobjcat = $objroot.".psfcorr.".$order.".cat";

if ($sensible == 1) {
  $outfile = $objroot.".psfcorr.".$order.".gamma.cat";
}

#-----------------------------------------------------------------------

# First part of process - fitting psf with stars:

if (-e $corrobjcat and -s $corrobjcat and not (defined($clean))){
  print STDERR "$corrobjcat exists, moving on to gamma calculation.\n";
} else {

# Fit polynomial to stellar ellipticities, psh and psm:
# Order of polynomial set by $order flag (-p).

&esystem("fit2Dpolymodel x 0 $order e < $starcat > $epolycat", $doproc, $verb);

# Apply polynomial to stars, refine using cursor, and fit psm and psh:
# Use all stars for simplicity:

&esystem("gen2Dpolymodel $epolycat < $starcat | 
lc -b +all 'ecorr = \%e \%emod vsub' > $corrstarcat", $doproc, $verb);

# Make model e, psm and psh values:

&esystem("fit2Dpolymodel x 0 $order e < $corrstarcat > $epolycat", $doproc, $verb);
&esystem("fit2Dpolymodel x 0 $order psm < $corrstarcat > $psmpolycat", $doproc, $verb);
&esystem("fit2Dpolymodel x 0 $order psh < $corrstarcat > $pshpolycat", $doproc, $verb);

# Cuts should be in separate routine...

# # Only make cuts on galaxies with bad pixels (at edges of field)
# &esystem("  lc -i '\%rg 1.25 > \%mag 27 < and \%d \%d dot sqrt 0.4 < and \%e \%e dot sqrt 0.7 < and \%nbad 0 == and' < $objcat > $cutcat", $doproc, $verb);
# &esystem("  lc -i '\%rg 1.25 > \%d \%d dot sqrt 0.4 < and \%e \%e dot sqrt 0.7 < and \%nbad 0 == and' < $objcat > $cutcat", $doproc, $verb);
# &esystem("  lc -i '\%d \%d dot sqrt 0.4 < \%e \%e dot sqrt 0.7 < and \%nbad 0 == and' < $objcat > $cutcat", $doproc, $verb);
# &esystem("  lc -i '\%e \%e dot sqrt 0.7 < \%nbad 0 == and' < $objcat > $cutcat", $doproc, $verb);

# # Make cuts on galaxies with bad pixels (at edges of field) 
# # and high ellipticities :
# &esystem("  lc -i '\%nbad 0 == \%e \%e dot sqrt 0.7 < and' < $objcat > $cutcat", $doproc, $verb);

#Apply correction to objects:

&esystem("gen2Dpolymodel $epolycat < $objcat | 
gen2Dpolymodel $psmpolycat | 
gen2Dpolymodel $pshpolycat | 
lc -b +all 'oe = \%e' 'e = \%e \%psm 1 \%psmmod[0][0] \%psmmod[1][1] + 2 / / mscale \%emod dot vsub' 'Pg = \%psh \%psm \%pshmod[0][0] \%pshmod[1][1] + \%psmmod[0][0] \%psmmod[1][1] + / mscale msub' > $corrobjcat", $doproc, $verb);
}

#-----------------------------------------------------------------------

# Second part of process - fitting pre-seeing polarizability:

if ($dofit == 1) {

# Fit nth order polynomial to Pg diagonal elements as fn of e_i and rg:
  print STDERR "Doing fitting, using actual Pg values, throwing out all objects with %Pg[0][0] < 0.0 and Pg[1][1] < 0.0\n";
 
&esystem("lc -b 'x1 = \%rg \%e[0] 2 vector' 'pg1 = \%Pg[0][0]' < $corrobjcat | lc -i '%pg1 0.0 >' | fit2Dpolymodel x1 0 $pgorder pg1 > pg1_$pgorder.fit", $doproc, $verb);
&esystem("lc -b 'x2 = \%rg \%e[1] 2 vector' 'pg2 = \%Pg[1][1]' < $corrobjcat | lc -i '%pg2 0.0 >' | fit2Dpolymodel x2 0 $pgorder pg2 > pg2_$pgorder.fit", $doproc, $verb);

# And use it to create gamma array:

#&esystem("lc -b -x +all 'xa = \%rg \%e[0] 2 vector' 'pg1 = \%Pg[0][0]' < $corrobjcat | 
#lc -i '%pg1 0.0 >' | 
#gen2Dpolymodel pg1_$pgorder.fit -x xa -s mod | 
#lc -b -x +all 'xb = \%rg \%e[1] 2 vector' 'pg2 = \%Pg[1][1]' |  
#lc -i '%pg2 0.0 >' |
#gen2Dpolymodel pg2_$pgorder.fit -x xb -s mod | 
#lc -x +all 'pgamma = \%pg1mod \%pg2mod 2 vector' | 
#lc +all 'gamma = \%e[0] \%pgamma[0] / \%e[1] \%pgamma[1] / 2 vector' > $outfile", $doproc, $verb);
#

&esystem("lc -b -x +all 'ox = %x' 'x = \%rg \%e[0] 2 vector' 'pg1 = \%Pg[0][0]' < $corrobjcat | 
lc -i '%pg1 0.0 >' | 
gen2Dpolymodel pg1_$pgorder.fit -s mod | 
lc -b -x +all 'x = \%rg \%e[1] 2 vector' 'pg2 = \%Pg[1][1]' |  
lc -i '%pg2 0.0 >' |
gen2Dpolymodel pg2_$pgorder.fit  -s mod | 
lc -x +all 'pgamma = \%pg1mod \%pg2mod 2 vector' | 
lc +all 'x = %ox' 'gamma = \%e[0] \%pgamma[0] / \%e[1] \%pgamma[1] / 2 vector' > $outfile", $doproc, $verb);


# # Fit to rg only:
# 
# # Fit 3rd order polynomial to Pg diagonal elements:
# &esystem("lc -b 'x1 = \%rg \%rg 2 vector' 'pg1 = \%Pg[0][0]' < $corrobjcat | 
# fit2Dpolymodel x1 0 $pgorder pg1 > pg1_$pgorder.fit", $doproc, $verb);
# &esystem("lc -b 'x2 = \%rg \%rg 2 vector' 'pg2 = \%Pg[1][1]' < $corrobjcat | 
# fit2Dpolymodel x2 0 $pgorder pg2 > pg2_$pgorder.fit", $doproc, $verb);
# 
# # And use it to create gamma array:
# &esystem("lc -b -x +all 'x1 = \%rg \%rg 2 vector' 'pg1 = \%Pg[0][0]' < $corrobjcat | 
# gen2Dpolymodel pg1_$pgorder.fit -x x1 | 
# lc -b -x +all 'x2 = \%rg \%rg 2 vector' 'pg2 = \%Pg[1][1]' | 
# gen2Dpolymodel pg2_$pgorder.fit -x x2 | 
# lc -x +all 'pgamma = \%pg1mod \%pg2mod 2 vector' | 
# lc +all 'gamma = \%e[0] \%pgamma[0] / \%e[1] \%pgamma[1] / 2 vector' > $outfile", $doproc, $verb);


# Clean up:
#&esystem("rm pg1_$pgorder.fit pg2_$pgorder.fit");

} else {

# Use Pg diagonal elements themselves - no cut on gamma:
    print STDERR "Not doing fitting, using actual Pg values, throwing out all objects with %Pg[0][0] < 0.0 and Pg[1][1] < 0.0\n";
    
    &esystem("lc -i '%Pg[0][0] 0.0 > %Pg[1][1] 0.0 > and' < $corrobjcat |
    lc +all 'gamma = \%e[0] \%Pg[0][0] / \%e[1] \%Pg[1][1] / 2 vector' > $outfile", $doproc, $verb);

}
#=======================================================================




