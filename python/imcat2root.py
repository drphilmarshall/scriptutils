#!/usr/bin/env python
########################
# @file imcat2root.py
# @author Douglas Applegate
# @date 6/18/2006
#
# @brief Converts imcat catalogs to ROOT tree format
# Based on astrocat2root by Chris Roat
#
# Needs the PyROOT package installed in the system
#
# BUG: Will not write headers to ROOT files
########################
import re
from optparse import OptionParser
from ROOT import TFile, TTree, TMap, TObjString, TList, TDirectory

##############################

def dict2rootmap(dict):
    '''assumes keys are strings, and vals are lists of strings'''
    map = TMap()
    for (key,entries) in dict.iteritems():
        rootkey = TObjString(key)
        rootval = TList()
        for entry in entries:
            rootval.Add(TObjString(entry))
        map.Add(rootkey,rootval)
    return map
    
##############################

class Catalog:
    ####################
    def __init__(self, header = {}, data = TTree()):
        self.header = header
        self.data = data
        
    
    ####################

    def getHeader(self,header):
        return self.header.get(header)

    ####################

    def getCol(self,col):
        colVals = []

        if self.data is None:
            return colVals

        for i in xrange(self.data.GetEntries()):
            self.data.GetEvent(i)
            buffer = self.data.__getattr__(col)
            val = []
            for i in xrange(len(buffer)):
                val.append(buffer[i])
            colVals.append(val)

        return colVals

    ####################

    def addHeader(self,header, val):
        if header in self.header:
            self.header[header].append(val)
        else:
            self.header[header] = [val]

    ####################

    def write(self):
        self.data.Write()
       # header_name = self.data.GetName() + "_header"
       # header_dir = TDirectory(header_name,header_name)
       # header_dir.cd()
       # dict2rootmap(self.header).Write()
       # header_dir.GetMotherDir().cd()

    ####################


##########################


def parse_args():

    parser = OptionParser(usage="%prog [options] infile")
    parser.add_option('-o', '--outfile',dest='output_name',help="ROOT file name")
    parser.add_option('-t', '--tree',dest='tree_name',action='append',
                      help="ROOT tree name")
    parser.add_option('-f', '--file',dest='file_name',action='append',
                      help="Input file name")

    (options,args) = parser.parse_args()

    if options.file_name is None:
        options.file_name = []
        
    options.file_name.extend(args);

    #different behavior for one file versus many files

    if len(options.file_name) == 1:
        if options.tree_name is None:
            options.tree_name = re.match('(.+)\.cat',
                                         options.file_name[0]).group(1)
        if options.output_name is None:
            options.output_name = \
                re.match('(.+)\.cat',options.file_name[0]).group(1) + ".root"

    else:
        if len(options.file_name) != len(options.tree_name):
            parser.error("Mismatched number of file and tree names")

        if options.output_name is None:
            option.output_name = "default.root";


    return options
    
#############################

def read_preamble(input_name):
    
    vars = []
    header = {}
    header['comment'] = []
    
    reVar = re.compile('^# (?P<type>\w+)\s+(?P<dim>[0-9 ]+)\s+(?P<name>\w+)(?P<val>.*)')
    
    vars_left = -1
    ###########
    
    def read_line(line):
        match = reVar.match(line)
        if match is None:
            raise Exception, "Catalog Format Error"
        return match
    
    ##########
    
    def parse_dimensions(dim_str):
        dimensions = re.findall('(\d+)\s*', dim_str)[1:]
            #first num is irrelevant
        return map(int,dimensions)
    
    #########
    
    def parse_header(descriptor):
        
        match = re.match('#\s+comment:(.+)',descriptor)
        if match is not None:
            header['comment'].append(match.group(1))
        else:
            match = read_line(descriptor)
            data = re.findall('\S+',match.group('val'))
            name = match.group('name')
            if name not in header:
                header[name] = data
            else:
                header[name].extend(data)
                
    ###########
                
                
    def parse_variable(descriptor):
        match = read_line(descriptor)
        dimensions = parse_dimensions(match.group('dim'))
        vars.append((match.group('name'),dimensions,match.group('type')))

    #############    
    
    def parse_none(descriptor):
        pass

    #############
    parse = parse_none
    input = open(input_name)
    if input is None:
        print "Error opening catalog\n"
        assert(False)
        
    for line in input:
        if vars_left == 0:
            break;
        match = re.match('#\s+(?P<section>\w+):\s*(?P<nvars>\d+)?\s*$',line)
        if match is None:
            #not a section header, parse it
            parse(line)
            vars_left -= 1   #yes this is ugly
        else: #section header
            section = match.group('section')
            if section == 'header':
                parse = parse_header
            elif section == "contents":
                vars_left = int(match.group('nvars'))
                parse = parse_variable
            else:
                print "Unrecognized Preample Section: " + section
                parse = parse_none

                
    input.close()

    return (header,vars)

#############################

def format_descriptor(var_list):

    ###########
    def format_array_size(dim):

        if len(dim) == 1 and dim[0] == 1:
            return ''
        dim_string = ""
        for d in dim:
            dim_string += '[' + str(d) + ']'

        return dim_string
    ##########

    ##########
    def format_type(type):

        if type == "text":
            return "/C"
        elif type == "number":
            return "/D"
    ##########
    
    descriptor = ""
    numVar = 0
    for (name,dim,type) in var_list:
        if numVar > 0:
            descriptor += ':'

        descriptor += name + format_array_size(dim) + format_type(type)
        numVar += 1
        
    return descriptor

#############################

def build_tree(tree_name, tree_descriptor, input_file):

    if tree_name is None:
        tree_name = re.match('(.*)\.cat',input_file).group(1)

    tree = TTree(tree_name, tree_name)
    tree.ReadFile(input_file, tree_descriptor)
    
    return tree

#############################

def write_root_output(output_name, catalogs):

    output = TFile.Open(output_name, "RECREATE")
    if output is None or output.IsZombie():
        print "Error Writing ROOT File\n"
        assert(False)
        
    output.cd()
    for catalog in catalogs:
        catalog.write()

    output.Close()
    

#############################

def open_catalog(file_name, tree_name=None):

    (header,var_list) = read_preamble(file_name)

    tree_descriptor = format_descriptor(var_list)

    print tree_descriptor

    tree = build_tree(tree_name, tree_descriptor, file_name)

    catalog = Catalog(header,tree)

    return catalog

#############################

def main():
    options = parse_args()

    tree_file_pairs = zip(options.file_name, options.tree_name)
    catalogs = []
    for (file,tree) in tree_file_pairs:
        
        catalog = open_catalog(file, tree)

        print "Number of Variables Detected: ",catalog.data.GetNbranches()
    
        print "Length of Tree: ",catalog.data.GetEntries()

        catalogs.append(catalog)

    write_root_output(options.output_name, catalogs)

###############################    

if __name__ == "__main__":
    main()
