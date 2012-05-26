#!/usr/bin/env python
###############
# @file geometry2D.py
# @author Douglas Appleegate
# @date 1/24/08
#
# @brief Some basic geometry tools
###############

__cvs_id__ = "$Id: geometry2D.py,v 1.3 2008-01-25 00:21:53 dapple Exp $"

###############

import numpy
from math import sqrt
import unittest

#####################################
#Geometry
#
# Note that this is only working for 2D geometry!
#
# Note that isOverlap function returns:
#       2 if reg is contained completely within self
#       1 if reg overlaps with self partially
#       0 if there is no overlap

class Region(object):

    def isOverlap(self, reg):
        if isinstance(reg, Circle):
            return self.isOverlapWithCircle(reg)
        if isinstance(reg, Polygon):
            return self.isOverlapWithPolygon(reg)
        raise TypeError('Unsupported Type')

################        

class Circle(Region):
    def __init__(self, center, radius):
        if not isinstance(center, numpy.ndarray):
            center = numpy.array(center)
        self.center = center
        self.radius = radius

    def containsPoint(self, point):
        dS = self.center - point
        return sqrt(numpy.dot(dS, dS)) <= self.radius

    def isOverlapWithCircle(self, circ):
        dCenter = self.center - circ.center
        centerDist = sqrt(numpy.dot(dCenter, dCenter))
        if centerDist >= (self.radius + circ.radius):
            return 0
        if (centerDist + circ.radius) <= self.radius:
            return 2
        return 1
    
    def isOverlapWithPolygon(self, poly):
            
        overlap = testPolygonCircleOverlap(poly = poly, circ = self)
        if overlap == -2:
            overlap = 1

        return overlap

#########

class Polygon(Region):
    '''An arbitrary polygon.
       Note that the polygon vertex list doesn't repeat points
    '''
    def __init__(self, points):
        self.points = points

    def containsPoint(self, point):
        '''Based on the Jordan Curve Theorem. See
           http://tog.acm.org/editors/erich/ptinpoly/ and
           http://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html
           for more details.
        '''

        inside = False
        for i in xrange(len(self.points)):
            j = i-1
            if ((self.points[i][1] <= point[1] < self.points[j][1]) or \
                    (self.points[j][1] <= point[1] < self.points[i][1])) and \
                    (point[0] < ((self.points[j][0] - self.points[i][0]) * \
                                     (point[1] - self.points[i][1]) / \
                                     (self.points[j][1] - self.points[i][1]) + \
                                     self.points[i][0])):
                inside =  not inside

        return inside

    def isOverlapWithCircle(self, circ):

        overlap = testPolygonCircleOverlap(poly = self, circ = circ)
        if overlap == 2:
            overlap = 1
        if overlap == -2:
            overlap = 2
        return overlap

    def isOverlapWithPolygon(self, poly):

        numPointsInside = 0
        for point in poly.points:
            if self.containsPoint(point):
                numPointsInside += 1
        if numPointsInside == len(poly.points):
            return 2

        numPointsInsideOther = 0
        for point in self.points:
            if poly.containsPoint(point):
                numPointsInsideOther += 1
        if numPointsInsideOther == len(self.points):
            return 1

        def linesIntersect(line1, line2):
            p1 = numpy.zeros(3)
            p2 = numpy.zeros(3)
            p3 = numpy.zeros(3)
            p4 = numpy.zeros(3)
            p1[0:2] = line1[0]
            p2[0:2] = line1[1]
            p3[0:2] = line2[0]
            p4[0:2] = line2[1]

            if ((p1 == p3).all() and (p2 == p4).all()) or \
                    ((p1 == p4).all() and (p2 == p3).all()):
                return False


            vec1 = p2 - p1
            vec2 = p4 - p3

            if numpy.cross(vec1,p3-p1)[2] * numpy.cross(vec1,p4-p1)[2] < 0 and \
                    numpy.cross(vec2,p2-p3)[2] * numpy.cross(vec2,p1-p3)[2] < 0:
                return True
            return False

        for i in xrange(len(self.points)):
            j = i-1
            for k in xrange(len(poly.points)):
                l = k-1
                if linesIntersect((self.points[i], self.points[j]),
                                  (poly.points[k], poly.points[l])):
                    return 1
        return 0
            

#######

def _edgeFormsChord(point1, point2, circ):
    vert1 = numpy.array([point1[0], point1[1], 0])
    vert2 = numpy.array([point2[0], point2[1], 0])
    center = numpy.array([circ.center[0], circ.center[1], 0])
    vec1 = vert2 - vert1
    vec2 = center - vert1
    vec3 = center - vert2
    d1 = sqrt(numpy.dot(vec1, vec1))
    dist2Line = numpy.cross(vec1,vec2)[2]/d1
    if abs(dist2Line) > circ.radius:
        return False
    if numpy.dot(vec1, vec2) * numpy.dot(vec1, vec3) < 0:
        return True
    return False

def testPolygonCircleOverlap(poly, circ):
    ''' returns:  2 if polygon is in circ
                  1 if overlap
                  0 for no overlap
                  -2 if circ in polygon
    '''
        
    numVertexsInside = 0
    for point in poly.points:
        if circ.containsPoint(point):
            numVertexsInside += 1

    if numVertexsInside == len(poly.points):
        return 2
    if numVertexsInside > 0:
        return 1
    if numVertexsInside == 0 and poly.containsPoint(circ.center):
        return -2
            
    for i in xrange(len(poly.points)):
        j = i-1
        if _edgeFormsChord(poly.points[i], poly.points[j], circ):
            return 1
    return 0
    

##########

class Rectangle(Polygon):
    def __init__(self, coord):
        self.coord = coord
        vertexList = numpy.zeros((4,2))
        vertexList[0][0] = vertexList[3][0] = self.coord[0][0]
        vertexList[1][0] = vertexList[2][0] = self.coord[0][1]
        vertexList[0][1] = vertexList[1][1] = self.coord[1][0]
        vertexList[2][1] = vertexList[3][1] = self.coord[1][1]
        Polygon.__init__(self, vertexList)

    def containsPoint(self, point):
        for i in xrange(len(self.coord)):
            if point[i] < self.coord[i][0] or point[i] > self.coord[i][1]:
                return False
        return True

#########

class TestIsOverlapCircle(unittest.TestCase):

    def setUp(self):
        self.c1 = Circle(numpy.zeros(2), 1)

    def testNoOverlapCircle(self):
        c2 = Circle(numpy.array([5,5]), 1)
        self.assertEqual(self.c1.isOverlap(c2), 0)

    def testSomeOverlapCircle(self):
        c2 = Circle(numpy.array([1.2, 0]), .4)
        self.assertEqual(self.c1.isOverlap(c2), 1)

    def testContainsCircle(self):
        c2 = Circle(numpy.array([.3,0]), .1)
        self.assertEqual(self.c1.isOverlap(c2), 2)

    def testNoOverlapPolygon(self):
        poly = Polygon(numpy.array([[5,5],[6,6],[7,0]]))
        self.assertEqual(self.c1.isOverlap(poly), 0)

    def testSomeOverlapPolygon(self):
        poly = Polygon(numpy.array([[.5,3],[.5,-3],[5,-4],[5,4]]))
        self.assertEqual(self.c1.isOverlap(poly), 1)

    def testContainsPolygon(self):
        poly = Polygon(numpy.array([[.2,0],[0,.2],[-.1,-.1]]))
        self.assertEqual(self.c1.isOverlap(poly), 2)

    def testNoOverlapPolygonCornerCase1(self):
        poly = Polygon(numpy.array([[0,5],[5,5],[0,4]]))
        self.assertEqual(self.c1.isOverlap(poly), 0)

    def testIsContainedInPolygon(self):
        poly = Polygon(numpy.array([[10,10], [-10,10], [-10,-10], [10,-10]]))
        self.assertEqual(self.c1.isOverlap(poly), 1)


###########

class TestIsOverlapSimplePolygon(unittest.TestCase):

    def setUp(self):
        self.poly = Polygon(numpy.array([[0,1],[1,-1],[-1,-1]]))

    def testNoOverlapCircle(self):
        circ = Circle(numpy.array([5,0]), 2)
        self.assertEqual(self.poly.isOverlap(circ), 0)

    def testContainsCircle(self):
        circ = Circle(numpy.array([.1,0]), .1)
        self.assertEqual(self.poly.isOverlap(circ), 2)

    def testSomeOverlapCircle1(self):
        circ = Circle(numpy.array([0,1.2]), .5)
        self.assertEqual(self.poly.isOverlap(circ), 1)
        
    def testSomeOverlapCircle2(self):
        circ = Circle(numpy.array([0,-1.2]), .5)
        self.assertEqual(self.poly.isOverlap(circ), 1)

    def testIsContainedInCircle(self):
        circ = Circle(numpy.array([.1, 0]), 6)
        self.assertEqual(self.poly.isOverlap(circ), 1)

    def testNoOverlapPolygon(self):
        poly = Polygon(numpy.array([[0,1],[1,-1],[2,2]]))
        self.assertEqual(self.poly.isOverlap(poly), 0)

    def testContainsPolygon(self):
        poly = Polygon(numpy.array([[0,.5],[.15,0],[-.15,0]]))
        self.assertEqual(self.poly.isOverlap(poly), 2)

    def testIsContainedInPolygon(self):
        poly = Polygon(numpy.array([[0,10],[5,-3],[-5,-3]]))
        self.assertEqual(self.poly.isOverlap(poly), 1)

    def testSomeOverlapPolygon1(self):
        poly = Polygon(numpy.array([[0,0], [5,0], [5,1]]))
        self.assertEqual(self.poly.isOverlap(poly), 1)

    def testSomeOverlapPolygon2(self):
        poly = Polygon(numpy.array([[1,1], [0,-1.5], [-1,1]]))
        self.assertEqual(self.poly.isOverlap(poly), 1)

class TestIsOverlapConcavePolygon(unittest.TestCase):

    def setUp(self):
        self.poly = Polygon(numpy.array([[0,0], [1,-1],[1,1],[-1,1],[-1,-1]]))

    def testNoOverlapCircle(self):
        circ = Circle(numpy.array([0,-.1]),.05)
        self.assertEqual(self.poly.isOverlap(circ), 0)

    def testContainsCircle(self):
        circ = Circle(numpy.array([.5, -.5]), .05)
        self.assertEqual(self.poly.isOverlap(circ), 2)

    def testSomeOverlapCircle1(self):
        circ = Circle(numpy.array([1,-1.1]), .3)
        self.assertEqual(self.poly.isOverlap(circ), 1)

    def testSomeOverlapCircle2(self):
        circ = Circle(numpy.array([-.5, -.6]), .15)
        self.assertEqual(self.poly.isOverlap(circ), 1)

    def testNoOverlapPolygon(self):
        poly = Polygon(numpy.array([[0,-.05], [.9,-1], [-.9,-1]]))
        self.assertEqual(self.poly.isOverlap(poly), 0)


###########

if __name__ == '__main__':
    suites = []
    suites.append(unittest.TestLoader().loadTestsFromTestCase( \
            TestIsOverlapCircle))
    suites.append(unittest.TestLoader().loadTestsFromTestCase( \
            TestIsOverlapSimplePolygon))
    suites.append(unittest.TestLoader().loadTestsFromTestCase( \
            TestIsOverlapConcavePolygon))
    masterSuite = unittest.TestSuite(suites)
    unittest.TextTestRunner(verbosity=2).run(masterSuite)
