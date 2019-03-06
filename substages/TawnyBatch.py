#!/home/ciaran/anaconda3/bin/python

# Author Ciaran Robb
# Aberystwyth University

# -*- coding: utf-8 -*-
"""
Created on Tue May 29 16:20:58 2018

@author: Ciaran Robb

https://github.com/Ciaran1981/Sfm

This script produces tiled orthomosaics for merging with ossim to produce near
seampless large scale mosaics


Usage: 
    
TawnyBatch.py -folder $PWD -num 3,3 -nt 3 

Here we are are using the UrbaMNE algorithm on a 3x3 grid of tiles, using the gpu,
processing 3 tiles in parallel

"""

#import pandas as pd
import argparse
from subprocess import call#, check_call, run
from glob2 import glob
from os import path, mkdir#, remove
from shutil import rmtree, move, copy
from joblib import Parallel, delayed#, parallel_backend
#import gdal

parser = argparse.ArgumentParser()

parser.add_argument("-folder", "--fld", type=str, required=True, 
                    help="path to wrkspace")


parser.add_argument("-num", "--noCh", type=str, required=False, 
                    help="number of chunks in grid form eg 2,2")


parser.add_argument("-nt", "--noT", type=int, required=False, 
                    help="no of tiles at a time")
# Not sure this works
parser.add_argument("-max", "--mx", type=int, required=False, 
                    help="max no of chunks to do - this is for testing with a smaller subset")


args = parser.parse_args() 


gOri= "Ground_UTM"

if args.noCh is None:
    numChunks = '3,3'
else:       
    numChunks = args.noCh


#if args.gp is None:
#    mmgpu = 'mm3d'
#    gP = '0'
#else:
#    mmgpu = '/home/ciaran/MicMacGPU/micmac/bin/mm3d'
#    gP = '1'

if args.noT is None:
    mp = 4 
else:
    mp = args.noT


fld = args.fld


DMatch = path.join(fld, 'DMatch')
bFolder = path.join(fld, 'TawnyBatch')


binList = [DMatch, bFolder]


# Some funcs for use later tile one from pymicmac

# folders to bin
for crap in binList:
    try:       
        rmtree(crap)
        
    except OSError:
        pass


mkdir(bFolder)
# run tiling


tileIt = ['tile.py', '-i', 'Ori-'+gOri, '-e',
            'JPG', '-f', 'DMatch', '-n', 
            numChunks]#, '--neighbours', '9']

call(tileIt)

# To avoid the inevitable problems with pyramids not being read
# This is a sub step in PIMs, so it is assumed the simalr(ish) principle here,
# it will solve the problem
#
txtList = glob(path.join(DMatch,'*.list'))
nameList = [path.split(i)[1] for i in txtList]
txtList.sort()
nameList .sort()
#list mania - I am crap at writing code
finalList = list(zip(txtList, nameList))


#rejectListB = []

# May revert to another way but lets see.....
def proc_tawny(subList, subName, bFolder):#), gP='1', bbox=True):
    # Yes all this string mucking about is not great but it is better than 
    # dealing with horrific xml, when the info is so simple
    flStr = open(subList).read()

    # then the images
    imList = flStr.split()
    imList.pop(0)
    oDir = path.join(fld, "Ortho-"+subName) 
    mkdir(oDir)
    for im in imList:
        imWCard = im[:-4] 
        imWfin = path.join(fld, 'PIMs-ORTHO','*'+imWCard+'*')
        mvList = glob(imWfin)
        if len(mvList) == 0:
            pass
        pass
        
        for f in mvList:
            hd, tl = path.split(f)
            copy(f, path.join(oDir, tl))
    inMsk = path.join('PIMs-ORTHO',  'MTDMaskOrtho.xml')
    outMsk = path.join(oDir,  'MTDMaskOrtho.xml')
    copy(inMsk , outMsk) 
    inMtd = path.join('PIMs-ORTHO', 'MTDOrtho.xml')
    outMtd = path.join(oDir,'MTDOrtho.xml')        
    copy(inMtd, outMtd) 
    tawny = ['mm3d', 'Tawny', oDir+'/', 'RadiomEgal=1',# 'DegRap=4',
             'Out=Orthophotomosaic.tif']
    ret = call(tawny)
    if ret != 0:        
        print(subName+" missed, will pick it up later")
        pass
    subDir = path.join(bFolder,  path.split(oDir)[1])
    if path.exists(oDir):
        move(oDir, subDir)
        print('subName mosaic done')
    

#if args.mx is None:
todoList = Parallel(n_jobs=mp,verbose=5)(delayed(proc_tawny)(i[0], 
     i[1], bFolder) for i in finalList) 
#else:
#    subFinal = finalList[0:args.mx]
#    todoList = Parallel(n_jobs=mp,verbose=5)(delayed(proc_malt)(i[0], 
#             i[1], bFolder, bbox=args.bb) for i in subFinal) 





    


