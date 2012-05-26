#!/usr/bin/python
######################################
# @file histogram.py
# @author Douglas Applegate
# @date 5/29/07
# @brief outputs a histogram in lc format given input lc format & bin structure
######################################

from optparse import OptionParser
import os
import re
import sys

########################
#command line arguments
########################
parser = OptionParser(description="Creates a histogram by reading & writing in lc format. Default read in and read out is via STDIN and STDOUT. If using STDIN, us lc to strip headers (-o option) and select only the column of interest.")

parser.add_option("-c", "--col", dest="col", help="Histogram variable", metavar="COL")
parser.add_option("-a", "--min", dest="min", help="Minimum value", metavar="VAL")
parser.add_option("-b", "--max", dest="max", help="Maximum value", metavar="VAL")
parser.add_option("-n", "--nbins", dest="nbins", help="Num Bins", metavar="VAL")
parser.add_option("-s", "--suppress", action="store_false", dest="display", help="Prevent histogram from being displayed", default=True)
parser.add_option("-d", "--device", dest="image_file", help="Output graph to this file (PS)", metavar="FILE")
parser.add_option("-i", "--infile", dest="infile", help="Input Catalog", metavar="FILE", default="STDIN")
parser.add_option("-o", "--outfile", dest="outfile", help="Output file", metavar="FILE", default="STDOUT")


(options, args) = parser.parse_args()

if (options.min == None or
    options.max == None or
    options.nbins == None):

    parser.print_help()
    sys.exit("Required options not specified")

min = float(options.min)
max = float(options.max)
nbins = int(options.nbins)
use_outfile = (options.outfile != "STDOUT")

######################
#open pipes
######################
if options.infile == "STDIN":
    input = sys.stdin
else:
    input_command = "lc -o " + options.col + " < " + options.infile
    input = os.popen(input_command, 'r')

if options.display:
    plot_command = "plotcat x num -h"
    if options.col is not None:
        plot_command += " -l " + options.col + " num"
    if options.image_file != None:
        plot_command += " -d '" + options.image_file + "/ps'"
    print plot_command
    plot = os.popen(plot_command, 'w')

output_command = "lc -C -n x -n num -n min -n max "
(output,feedback) = os.popen2(output_command,'t')
if use_outfile:
    outfile = open(options.outfile, 'w')

#####################
#create histo
#####################
step = float(max - min)/nbins
divPoints = []
cur = min
for i in range(nbins):
    divPoints.append(cur)            
    cur += step
divPoints.append(cur)
       
xaxis = []
histo = {}
for i in range(nbins):
    xaxis.append( (divPoints[i] + divPoints[i+1])/2 )
    histo[(divPoints[i],divPoints[i+1])] = 0

bins = histo.keys()
for curline in input:

    if curline[0] == "#":
        continue
    d = float(curline)
    def inBin(bin):
        (min,max) = bin
        return min <= d < max
    pos = filter(inBin, bins)
    assert len(pos) <=1
    if len(pos) == 1:
        histo[pos[0]] += 1

bins.sort()
counts = [histo[bin] for bin in bins]


#####################
#Output histogram
#####################

for i in range(nbins):
    (min,max) = bins[i]
    output.write( str(xaxis[i]) + '\t' + str(counts[i]) + '\t' + str(min) +
                  '\t' + str(max) + '\n')


######################
# Cleanup
######################
input.close()
output.close()

lc_histogram = feedback.read()
feedback.close()

if options.display:
    plot.write(lc_histogram)
    plot.close()

if use_outfile:
    outfile.write(lc_histogram)
    outfile.close()
else:
    sys.stdout.write(lc_histogram)
