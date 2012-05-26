#################
# utility functions
###############

from math import sqrt
from numpy import *

###############################

class Catalog(object):

    def __init__(self, x, y, id):

        self.nentries = len(x)
        self.pos = vstack([x,y]).transpose()
        self.id = id


    def filter(self, filt):

        return Catalog(self.pos[:,0][filt], self.pos[:,1][filt], self.id[filt])

    def __len__(self):
        return self.nentries

#########################

SPLIT=10

def buildTrie(cat):

    if len(x) > SPLIT:
        return Node(cat)
    else:
        return Leaf(cat)

########################

class Trie(object):

    def __init__(self, cat):

        self.range = ((min(cat.pos[:,0]), max(cat.pos[:,0])),
            (min(cat.pos[:,1]), max(cat.pos[:,1])))

    def findNeighbors(self, coord, within, neighbors = []):
        
        for pos, dim in zip(coord, self.range):
            if (pos + within) < dim[0] or \
                    (pos - within) > dim[1]:
                return neighbors
            return self._findNeighbors(coord, within, neighbors)
        
##########################



class Leaf(Trie):

    def __init__(self, cat):
        Trie.__init__(self, cat)
        self.cat = cat
        self.range = _getRange(cat)

    def _findNeighbors(self, coord, within, neighbors = []):

        ds = self.cat.pos - coord
        dist = numpy.sqrt((ds*ds).sum(axis=1))
    
        neighbors.extend(self.cat.id[dist < within].tolist())
        return neighbors


############################
        

class Node(Trie):

    def __init__(self,cat):

        Trie.__init__(self, cat)
        self.left = None
        self.right = None

        if (self.range[0][1] - self.range[0][0]) > \
                (self.range[1][1] - self.range[1][0]):
            splitaxis = cat.pos[:,0]
        else:
            splitaxis = cat.pos[:1]

        split = median(splitaxis)

        self.left = buildTrie(cat.filter(splitaxis <= split))
        self.right = buildTrie(cat.filter(splitaxis > split))


    def findNeighbors(self, coord, within, neighbors = []):

        neighbors.extend(self.left.findNeighbors(coord, within, neighbors))
        neighbors.extend(self.right.findNeighbors(coord, within, neighbors))
        return neighbors
        
################################


def matchCatalogs(catalog1,catalog2,dist):
    #lists of entry objects

    cat1Index = {}
    cat2Index = {}

    trie = buildKDTrie(cat2)

    for i in xrange(len(cat2)):
        cat2Index[cat2.id[i]] = []
    
    for i in xrange(len(cat1)):
        curId = cat1.id[i]
        neighbors = trie.findNeighbors(cat1.pos[i], tolerance)
        cat1Index[curId] = neighbors
        for id in neighbors:
            cat2Index[id].append(curId)

    return (cat1Index, cat2Index)
        




#############################


    
