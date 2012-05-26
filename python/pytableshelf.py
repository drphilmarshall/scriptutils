'''
@file pytableshelf.py
@author Douglas Applegate
@date 10/23

Implements a shelf system using the Pytables implementation.

Note that this module requires the Pytables package (www.pytables.org), which in
turn depends on the HDF5 library (http://hdf.ncsa.uiuc.edu/products/hdf5/index.html).

The PytableShelf object acts like a normal dictionary object, except where noted
below:

        d = pytableshelf.open(filename) # open, -- no suffix

        d[key] = data   # store data at key (overwrites old data if
                        # using an existing key)
                        # 'key' must be a STRING
        data = d[key]   # retrieve a COPY of the data at key (raise
                        # KeyError if no such key) -- NOTE that this
                        # access returns a *copy* of the entry!
        del d[key]      # delete data stored at key (raises KeyError
                        # if no such key)
        flag = d.has_key(key)   # true if the key exists; same as "key in d"
        list = d.keys() # a list of all existing keys (slow!)

        d.close()       # close it


'''

__CVS_ID__ = "$Id: pytableshelf.py,v 1.1 2008-01-17 19:12:38 dapple Exp $"

####################################

import UserDict
import tables
import tables.scripts.ptrepack as repack

#####################################

def open(filename):
    return PytableShelf(filename)

######################################

class PytableShelf(UserDict.DictMixin):

    def __init__(self, filename, compression = 1):
        self.filter = tables.Filters(complevel=compression)
        self.filename = filename
        self.file = None
        self.fileKeys = None
        self.fileVals = None
        self.repack = False
        try:
            self.file = tables.openFile(filename,mode='a')
        except IOError:
            raise IOError, "Cannot Open File: %s" % filename

        self.formatFile()

    ###############################

    def __del__(self):
        
        self.close()

    ###############################

    def close(self):
        if self.file is not None:
            self.file.close()
            self.file = None
            if self.repack:
                tmpfile = self.filename + ".tmp"
                repack.copyChildren(srcfile = self.filename,
                                    dstfile = tmpfile,
                                    srcgroup = '/',
                                    dstgroup = '/',
                                    title = '',
                                    recursive = True,
                                    filters = self.filter,
                                    copyuserattrs = True,
                                    overwritefile = True,
                                    overwrtnodes = True,
                                    stats = {'groups': 0, 'leaves': 0,
                                             'bytes': 0},
                                    start = 0,
                                    stop = None,
                                    step = 1,
                                    upgradeflavors = False)
                os.rename(tmpfile, self.filename)
            
                                
            

    ###############################

    def formatFile(self):

        if '/keys' not in self.file:
            self.file.createVLArray("/", "keys", tables.VLStringAtom(),
                                    filters=self.filter)

        if '/vals' not in self.file:
            self.file.createVLArray("/", "vals", tables.ObjectAtom(),
                                    filters = self.filter)      

        try:
            self.fileKeys = self.file.getNode("/","keys",classname="VLArray")
            self.fileVals = self.file.getNode("/", "vals",classname="VLArray")
        except tables.NoSuchNodeError:
            raise AttributeError("Incorrect File Structure: %s" % \
                                     self.filename)

        if not isinstance(self.fileKeys.atom, tables.VLStringAtom) or \
                not isinstance(self.fileVals.atom, tables.ObjectAtom):
            raise AttributeError("Incorrect File Structure: %s" % \
                                     self.filename)
        self.constraints()

    ###############################

    def constraints(self):

        if self.fileKeys is None or self.fileVals is None:
            raise AttributeError("Incorrect File Structure: %s" %  \
                                 self.filename)

        if len(self.fileKeys) != len(self.fileVals):
            raise AttributeError("Internal Data Inconsistancy: %s" % \
                                 self.filename)
        

    ###############################

    _objectNotFound = -1
    def _findIndex(self,key):
        i=0;
        for entry in self.fileKeys.iterrows():
            if entry == key:
                return i
            i += 1
        return self._objectNotFound

    ###############################

    def __getitem__(self,key):
        index = self._findIndex(key)
        if index == self._objectNotFound:
            raise KeyError
        return self.fileVals[index]
        
    ################################

    def _removeStaleKeyVal(self, index):

        self.repack = True
        
        keys = self.fileKeys.read()
        vals = self.fileVals.read()

        self.file.removeNode("/keys")
        self.file.removeNode("/vals")

        self.file.flush()

        self.file.createVLArray("/", "keys", tables.VLStringAtom(),
                                filters = self.filter)
        self.file.createVLArray("/", "vals", tables.ObjectAtom(),
                                filters = self.filter)
        self.fileKeys = self.file.root.keys
        self.fileVals = self.file.root.vals
        for (curKey, curVal) in zip(keys[0:index],
                                    vals[0:index]):
            self.fileKeys.append(curKey)
            self.fileVals.append(curVal)
        for (curKey, curVal) in zip(keys[index+1:],
                                    vals[index+1:]):
            self.fileKeys.append(curKey)
            self.fileVals.append(curVal)

    #################################
    
    def __setitem__(self, key, val):

        if not type(key) == type(''):
            raise TypeError, "keys and values must be strings"
        index = self._findIndex(key)
        if index != self._objectNotFound:
            self._removeStaleKeyVal(index)
                        
        self.fileKeys.append(key)
        self.fileVals.append(val)

    #################################

    def __delitem__(self, key):

        index = self._findIndex(key)
        if index == self._objectNotFound:
            raise KeyError
        self._removeStaleKeyVal(index)

    ##################################

    def keys(self):
        return self.fileKeys.read()

    

#############################################
#TESTING
#############################################


import unittest
import os

    
class FileStructTestCase(unittest.TestCase):

    def testNoFile(self):
        
        mydict = PytableShelf("testNoFile.h5")
        self.failUnless(os.path.exists('testNoFile.h5'))
        mydict.close()
        os.remove('testNoFile.h5')

    ###############################

    def testPartialFile(self):
        
        h5file = tables.openFile("incorrectFile.h5", mode="w")
        h5file.createVLArray("/", "vals", tables.ObjectAtom(),
                             filters = tables.Filters(complevel=1))
        arr = h5file.root.vals
        arr.append([5,6,"7"])
        arr.append("1,2,3")
        h5file.close()
        
        self.expectException("incorrectFile.h5")
    ###################################

    def testWrongDims(self):

        h5file = tables.openFile("wrongDims.h5", mode="w")
        
        h5file.createVLArray("/", "keys", tables.VLStringAtom(),
                             filters = tables.Filters(complevel=1))
        keys = h5file.root.keys
        keys.append("key1")
        keys.append("key2")
        
        h5file.createVLArray("/", "vals", tables.ObjectAtom(),
                             filters = tables.Filters(complevel=1))
        vals = h5file.root.vals
        vals.append([1,2,3])

        h5file.close()
        
        self.expectException("wrongDims.h5")

    ########################################

    def testWrongTypes1(self):

        h5file = tables.openFile("wrongTypes1.h5", mode="w")

        h5file.createTable("/","keys", {"key" : tables.StringCol(itemsize=16)})
        row = h5file.root.keys.row
        row['key'] = 'key1'
        row.append()
        h5file.root.keys.flush()

        h5file.createVLArray("/", "vals", tables.ObjectAtom(),
                             filters=tables.Filters(complevel=1))
        vals = h5file.root.vals
        vals.append([1,2,3])

        h5file.close()
        
        self.expectException("wrongTypes1.h5")

    ###########################################

    def testWrongTypes2(self):
        
        h5file = tables.openFile("wrongTypes2.h5", mode="w")
        
        h5file.createVLArray("/", "keys", tables.VLStringAtom(),
                             filters=tables.Filters(complevel=1))
        keys = h5file.root.keys
        keys.append("key1")
        keys.append("key2")
        
        h5file.createVLArray("/", "vals", tables.VLStringAtom(),
                             filters=tables.Filters(complevel=1))
        vals = h5file.root.vals
        vals.append("5555")
        vals.append("aaaaaa")

        h5file.close()
        
        self.expectException("wrongTypes2.h5")
    #############################################

    def expectException(self,filename):
        mydict = None
        def testStmt():
            mydict = PytableShelf(filename)
        try:
            self.assertRaises(AttributeError, testStmt)
        finally:
            if mydict is not None:
                mydict.close()
            os.remove(filename)

###################################################

class MyObj(object):

    def __init__(self, str):
        self.str = str

    def __eq__(self,other):
        return self.str == other.str

class DictOpsTestCase(unittest.TestCase):

    def setUp(self):

        h5file = tables.openFile("test.h5", "w")

        h5file.createVLArray("/", "keys", tables.VLStringAtom(),
                             filters=tables.Filters(complevel=1))
        keys = h5file.root.keys

        h5file.createVLArray("/", "vals", tables.ObjectAtom(),
                             filters=tables.Filters(complevel=1))
        vals = h5file.root.vals
        
        keys.append('1')
        vals.append(MyObj('1'))

        keys.append('2')
        vals.append(MyObj('2'))

        keys.append('list')
        vals.append([1,2,3])

        h5file.close()

        self.shelf = PytableShelf('test.h5')

    ########################

    def tearDown(self):

        self.shelf.close()
        os.remove('test.h5')

    #######################

    def testGetItem(self):
        self.assertEqual([1,2,3], self.shelf['list'])
        self.assertEqual(MyObj('2'), self.shelf['2'])


    #####################

    def testGetNonexistItem(self):
        self.assertRaises(KeyError, lambda: self.shelf['fake'])

    ######################

    def testGetItemisCopy(self):
        l = self.shelf['list']
        l[1] = 4
        self.assertEqual([1,2,3], self.shelf['list'])

    ######################

    def testSetItem(self):
        item = [1,2,['gh','bc']]
        self.shelf['newitem'] = [1,2,['gh','bc']]
        self.assertEqual(item, self.shelf['newitem'])

    #######################

    def testResetItem(self):
        item = [1,2,['gh','bc']]
        self.shelf['list'] = [1,2,['gh','bc']]
        self.assertEqual(item, self.shelf['list'])

    #####################

    def testBadKey(self):
        def stmt():
            self.shelf[5] = "a"
        self.assertRaises(TypeError, stmt)

    #######################

    def testDelKey(self):
        del self.shelf['2']
        self.assertRaises(KeyError, lambda: self.shelf['2'])

    #######################

    def testDelNonexistantKey(self):
        def stmt():
            del self.shelf['10']
        self.assertRaises(KeyError, stmt)

    ########################

    def testKeys(self):
        self.assertEqual(['1','2','list'], self.shelf.keys())
    
    ########################

    def testHasKey(self):
        self.failUnless(self.shelf.has_key('2'))
        self.failIf(self.shelf.has_key('fake'))

    ########################

    def testWriteOut(self):
        self.shelf['add'] = MyObj('add')
        self.shelf['2'] = MyObj('~2')
        del self.shelf['1']
        self.shelf.close()
        self.shelf = PytableShelf('test.h5')
        
        self.assertEqual(MyObj('add'), self.shelf['add'])
        self.assertEqual(MyObj('~2'), self.shelf['2'])
        self.assertRaises(KeyError, lambda: self.shelf['1'])
        self.assertEqual([1,2,3], self.shelf['list'])
        
        


################################################
if __name__ == "__main__":    

    suites = []
    suites.append(unittest.TestLoader().loadTestsFromTestCase(FileStructTestCase))
    suites.append(unittest.TestLoader().loadTestsFromTestCase(DictOpsTestCase))
    unittest.TextTestRunner(verbosity=2).run(unittest.TestSuite(suites))
        

        
