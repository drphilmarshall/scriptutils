#!/usr/bin/env python

############################
# @file galaxycountprofile.py
# @author Douglas Applegate
# 
# @brief plots galaxy_density as function of radius using histogram.py
#############################

from math import sqrt
from optparse import OptionParser
import imcat2root
from ROOT import TH1D, TFile
import os
import re

####################################

def parse_args():
    
    usage = '''\n
NAME
        galaxycountprofile.py

PURPOSE
        Histograms galaxy density as a function of radius from cluster center

USAGE
        galaxycountprofile.py [flags] [options] project.cat

        ******Use -h for list of options******

INPUTS
        project.cat      Catalog of galaxies

OUTPUTS
        Histogram of galaxy density in lc format  (STDOUT)

BUGS
        Assumes mask file has one include region ONLY

REVISION HISTORY:
  2007-06-27 Started - Applegate (KIPAC)

\n'''
    parser = OptionParser(usage = usage)
    parser.add_option("-a", "--rmin", dest="rmin", type="int",
                      help="Minimum radius", default=0)
    parser.add_option("-b", "--rmax", dest="rmax", type="int",
                      help="Maximum radius", default=5000)
    parser.add_option("-n", "--nbins", dest="nbins", type="int",
                      help="Number of bins in histogram", default=10)
    parser.add_option("-x", "--centerx", dest="cx", default=0, type="int",
                      help="Position of cluster center - X")
    parser.add_option("-y", "--xentery", dest="cy", default=0, type="int",
                      help="Position of cluster center - Y")
    parser.add_option("-c", "--col", dest="col", default="x",
                      help="Position Column in catalog")
    parser.add_option("-p", "--pscale", dest="pscale", default=1., type="float",
                      help="Physical size of one pixel")
    parser.add_option("-m","--mask", dest="mask", 
                      help="Image mask to delineate border in FITS file")
    parser.add_option("-o", "--outfile", dest="outfile", default = None,
                      help="Save output to a file")

    (options,args) = parser.parse_args()
    if len(args) != 1:
        parser.error("Specify catalog of galaxies")

    options.cluster = (options.cx,options.cy)
    options.catalog = args[0]
    if options.outfile is None:
        options.outfile = \
            re.match('(.+)\.cat',options.catalog).group(1) + ".profile.root"

    return options


###################################

def parse_catalog(catalog_name, col):

    catalog = imcat2root.open_catalog(catalog_name)

    galaxies = catalog.getCol(col)

    fits_name = catalog.getHeader('fits_name')[0]
    if fits_name is None:
        raise Exception, 'FITS file not specified in catalog!'

    return (galaxies, fits_name)


###################################

def read_mask_file(mask_name):
    '''Takes the last region in specified region file as included region'''
    
    if mask_name == None:
        return None
   
    mask_file = open(mask_name)
    for line in mask_file:

        if re.match('^#',line) is not None or  \
                re.match('^global',line) is not None:
            continue

        match = re.match('^(\w+;)?(\S+)',line)
        if match is not None:
            region = match.group(2)

    mask_file.close()
    return region
            

###################################

def calc_area(center, min, max, fits_name, mask):
    #use dmstat program to calculate area...too bad its not very easy, or fast
    
    (cx,cy) = center
    
    region = "annulus(" + str(cx) + "," + \
        str(cy) + "," + str(min) + "," + str(max) + ")"
    if mask is not None:
        region += "*" + mask 
    
    command = "dmstat \"" + fits_name +"[(x,y)="+region +"]\" centroid=no "+ \
        "median=no sigma=no"
    stat_output = os.popen(command,'r')
    
    for line in stat_output:
        match =  re.search('good:\s+(\d+)',line)
        if match is not None:
            area =  match.group(1)
            break

    stat_output.close()
    return float(area)

####################################
            

def compute_densities(galaxies, cluster, rmin, rmax, nbins,
                      fits_name, mask_name, pscale):

    

    def radius(x):
        return pscale*sqrt((x[0] - cluster[0])**2 + (x[1] - cluster[1])**2)
    galaxy_radii = map(radius, galaxies)

    hdensity = TH1D("galaxy_density","galaxy_density",nbins,
                    rmin*pscale,rmax*pscale)
    for r in galaxy_radii:
        hdensity.Fill(r)

    mask = read_mask_file(mask_name)

    num_bins = hdensity.GetNbinsX()
    for bin in xrange(1,num_bins+1):  #bins 1 <= x <= num_bins
        print "Bin " + str(bin) + " of " + str(num_bins) + "..."
        
        #need to compute areas in pixels, so divide back out pscale
        min = hdensity.GetXaxis().GetBinLowEdge(bin)/pscale
        max = hdensity.GetXaxis().GetBinUpEdge(bin)/pscale
        area = (pscale**2)*calc_area(center=cluster, min=min, max=max,
                         fits_name = fits_name,
                         mask = mask)
        hdensity.SetBinContent(bin,hdensity.GetBinContent(bin)/area)

    return hdensity

###################################

def output_histo(histo, filename):

    file = TFile(filename,"RECREATE")
    histo.SetDirectory(file)
    file.Write()
    file.Close()


###################################
        

def main():

    options = parse_args()

    (galaxies, fits_name) = parse_catalog(catalog_name = options.catalog,
                                          col = options.col)

    
    galaxy_densities = compute_densities(galaxies = galaxies,
                                         cluster = options.cluster,
                                         rmin = options.rmin,
                                         rmax = options.rmax,
                                         nbins = options.nbins,
                                         fits_name = fits_name,
                                         mask_name = options.mask,
                                         pscale = options.pscale)

    output_histo(galaxy_densities, options.outfile)



    
    




#####################################

if __name__ == "__main__":
    main()
