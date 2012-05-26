############################
# @file plotting.py
# @author Douglas Applegate
# @date 10/12/07
#
# Provides convienient wrappers around common plotting tasks
#  using numpy and pylab
############################

__cvs_id__ = "$Id: plotting.py,v 1.1 2008-01-17 19:12:38 dapple Exp $"

############################

import matplotlib.pylab as pylab
import numpy

############################

def doFormating(**formating):
    if 'title' in formating:
        pylab.title(formating['title'])
    if 'xlabel' in formating:
        pylab.xlabel(formating['xlabel'])
    if 'ylabel' in formating:
        pylab.ylabel(formating['ylabel'])

############################

def histogram(a, bins=10, range=None, log = False, normed = False,
              filename = None,
              **formating):

    hist, bins = numpy.histogram(a, bins, range, normed)

    width = bins[1] - bins[0]

    pylab.bar(bins[:-1], hist[:-1], width=width, log=log)
    doFormating(**formating)
    pylab.show()
    if filename is not None:
        pylab.savefig(filename)
        pylab.clf()

#############################

def histogram2d(x, y, bins=10, range=None, normed=False, weights=None,
                log = False,
                filename = None,
                **formating):
    
    hist, x, y = numpy.histogram2d(x, y, bins, range, normed, weights)

    if log is True:
        hist = numpy.log(hist)
    
    X, Y = pylab.meshgrid(x,y)
    pylab.pcolor(X, Y,hist.transpose())
    pylab.colorbar()
    doFormating(**formating)
    pylab.show()
    if filename is not None:
        pylab.savefig(filename)
        pylab.clf()
