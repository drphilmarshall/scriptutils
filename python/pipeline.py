'''
   @file pipeline.py
   @author Douglas Applegate
   @date 9/26/07

   Provides a framework for autorecovery, and rerunning, of parts of the 
   pipeline
'''

__cvs_id__ = "$Id: pipeline.py,v 1.1 2008-01-17 19:12:38 dapple Exp $"

################

import logging
from decorator import decorator

log = logging.getLogger('shearpipeline.pipeline')


#################################################################

class Pipeline(object):

    def __init__(self):
        self.storage = None
        self.resume = None

    #########################

    def __getitem__(self,key):
        return self.storage[key]

    ##########################

    def __setitem__(self,key,value):
        self.storage[key] = value

    ##########################

    def run(self, storage = None, resume = None,
                    *args, **keywords):

        if storage is not None:
            self.storage = storage
        elif self.storage is None:
            self.storage = {}
        self.resume = resume
        return self._run(*args, **keywords)


#########################################

@decorator
def branchingsavepoint(f, *args, **kw):
    
    self = args[0]
    f_name = f.__name__
    if self.resume == f_name:
        self.resume = None

    log.log(20, 'Entering %s...' % f_name)

    isTrue = f(*args,**kw)
    
    log.log(20, 'Returning %s' % str(isTrue))
    
    return isTrue
    

#########################################

@decorator
def savepoint(f, *args, **kw):
    '''To be applied to instance methods of a class.'''

    self = args[0]
    f_name = f.__name__
    if self.resume is None or \
            self.resume == f_name:
        self.resume = None

        log.log(20, 'Entering %s...' % f_name)
        
        f(*args,**kw)
            
        log.log(20,'Done.')

    else:
        log.log(20, '%s already complete. Skipping.' % f_name)


#########################################
        

def runPipeline(pipeline, storage = None, resume = None, method = 'run',
                **keywords):

    storage.update(keywords)

    pipeline.storage = storage
    pipeline.resume = resume
    
    getattr(pipeline, method)()

    
###############################################################
##############################################################
#TESTING
#################



import unittest

class TestPipeline(Pipeline):

    def visit(self,method):
        self.storage.append(method)
        
    @savepoint
    def alpha(self):
        self.visit('alpha')
        
    @savepoint
    def beta(self):
        self.visit('beta')

    @savepoint
    def delta(self):
        self.visit('delta')
        
    @branchingsavepoint
    def isGamma(self):
        self.visit('gamma')
        return True

    @savepoint
    def zeta(self):
        self.visit('zeta')

    def run(self):
        self.alpha()
        self.beta()
        if self.isGamma():
            self.delta()
        self.zeta()

    run2 = run

    #################

class PipelineTestCase(unittest.TestCase):
    
    def setUp(self):
        self.pipeline = TestPipeline()
        self.storage = []

    def testNormalRun(self):
        runPipeline(pipeline=self.pipeline, storage=self.storage)
        self.assertEqual(self.storage,
                                 "alpha beta gamma delta zeta".split())

    def testAltMethod(self):
        runPipeline(pipeline=self.pipeline, storage=self.storage,
                    method='run2')
        self.assertEqual(self.storage,
                             "alpha beta gamma delta zeta".split())

    def testPartialRun(self):
        runPipeline(pipeline=self.pipeline, storage=self.storage, 
                    resume='beta')
        self.assertEqual(self.storage,
                             "beta gamma delta zeta".split())

    def testStartAtBranch(self):
        runPipeline(pipeline=self.pipeline, storage=self.storage,
                    resume='isGamma')
        self.assertEqual(self.storage,
                             "gamma delta zeta".split())

    def testStartInBranch(self):
        runPipeline(pipeline=self.pipeline, storage=self.storage,
                    resume='delta')
        self.assertEqual(self.storage,
                             "gamma delta zeta".split())

    def testAfterBranch(self):
        runPipeline(pipeline=self.pipeline, storage=self.storage,
                    resume='zeta')
        self.assertEqual(self.storage, "gamma zeta".split())

    def testNonexistant(self):            
        runPipeline(pipeline=self.pipeline, storage=self.storage,
                    resume='fake')
        self.assertEqual(self.storage, "gamma".split())


if __name__ == '__main__':

    suite = unittest.TestLoader().loadTestsFromTestCase(PipelineTestCase)
    unittest.TextTestRunner(verbosity=2).run(suite)
        
            
