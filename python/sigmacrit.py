#!/usr/bin/env python
#####################
# @file sigmacrit.py
# @author Douglas Applegate
#
# @brief Calculates Sigma_crit for a lensing object
# Assumes lamdaCDM with omega_k = 0
#
# Needs the scipy package installed
# 
# @date 6/26/07 - Started - Applegate (KIPAC)
#####################

import sys
import numpy
from scipy import integrate
from math import pi
from optparse import OptionParser

#####################
#assumed cosmology
hubble_length = 2.84e9  #pc/h
omega_matter = 0.27     #lambdaCDM parameter
omega_lambda = .73      #lambdaCDM parameter
C = 9.72e-9             #pc/s
G = 4.52e-30          #pc^3/ Msun s^2
####################

####################
# Scipy assumes a vectorized function, so we need to prep for that
def autovectorize(f):
    def wrapper(input):
        if type(input) == numpy.ndarray:
            return numpy.vectorize(f)(input)
        return f(input)
    return wrapper

def doIntegration(func, min, max):
    '''uses a compiled library for integration'''
    return integrate.quad(autovectorize(func),min, max)[0]

#####################

def calcComovingDist(z):

    def integrand(z):
        return ( omega_matter*((1+z)**3) + omega_lambda )**(-.5)
    
    return hubble_length*doIntegration(integrand,0,z)

#####################

def calcAngularDist(far, near = None):
    
    far_Dm = calcComovingDist(far)
    if near is not None:
        near_Dm = calcComovingDist(near)
    else:
        near_Dm = 0

    return (far_Dm - near_Dm)/(1+far)

#####################

def calcSigmaCrit(z_source, z_lens):

    Ds = calcAngularDist(z_source)
    Dd = calcAngularDist(z_lens)
    Dds = calcAngularDist(z_source, z_lens)

    return (C**2/(4*pi*G))*(Ds/(Dd*Dds))

#####################

def main():
    
    parser = OptionParser(usage="%prog [options] z_lens z_source",
                          description="Calculates sigma_critical for given lens and source redshifts.")

    (options, args) = parser.parse_args()

    if len(args) != 2:
        parser.error("Must provide redshifts for the lens AND source!")

    z_lens = float(args[0])
    z_source = float(args[1])
    
    print "Sigma_Crit [h M_sun/pc^2]: %e" % calcSigmaCrit(z_source,z_lens)

    sys.exit(0)

####################

if __name__ == "__main__":
    main()
