#!/home/ciaran/anaconda3/bin/python

# Author Ciaran Robb
# Aberystwyth University

# -*- coding: utf-8 -*-
"""
Created on Tue May 29 16:20:58 2018

@author: ciaran

This scripts tiles large datsets for micmac and processes in parallel or sequnce depending 

This uses Malt which appear to be better for orthophoto generation

Gpu use is optional

GPU mem overload is dependent on a number of factors and does occur so will require a bit of testing
Probably best to stick to a max of no physical CPUs for nt arg

Usage: 
    
MaltBatch.py -folder $PWD -algo UrbanMNE -num 3,3 -zr 0.01 -g 1 -nt 3 

Here we are are using the UrbaMNE algorithm on a 3x3 grid of tiles, using the gpu,
processing 3 tiles in parallel

"""

#import pandas as pd
import argparse
from subprocess import call#, check_call, run
from glob2 import glob
from os import path, mkdir, remove
from shutil import rmtree, move
from joblib import Parallel, delayed#, parallel_backend

parser = argparse.ArgumentParser()

parser.add_argument("-folder", "--fld", type=str, required=True, 
                    help="path to wrkspace")

parser.add_argument("-algo", "--algotype", type=str, required=False, 
                    help="Micmac algo type eg Forest")

parser.add_argument("-num", "--noCh", type=str, required=False, 
                    help="number of chunks in grid form eg 2,2")

parser.add_argument("-zoom", "--zmF", type=str, required=False, 
                    help="Zoom level - eg 1=1 point per pixel, 2 = 1 point per  4 pixels")

parser.add_argument("-zr", "--zrg", type=str, required=False, 
                    help="z reg term context dependent")

parser.add_argument("-ori", "--oRI", type=str, required=False, 
                    help="ori folder if not the default name of Ground_UTM")

parser.add_argument("-g", "--gp", type=bool, required=False, 
                    help="gpu use yes or no")

parser.add_argument("-nt", "--noT", type=int, required=False, 
                    help="no of tiles at a time")
# Not sure this works
parser.add_argument("-max", "--mx", type=int, required=False, 
                    help="max no of chunks to do - this is for testing with a smaller subset")


args = parser.parse_args() 

if args.oRI is None:
   gOri= "Ground_UTM"
else:
    gOri = args.oRI

if args.algotype is None:
   algo= "UrbanMNE"
else:
    algo = args.algotype

if args.noCh is None:
    numChunks = '3,3'
else:       
    numChunks = args.noCh

if args.zrg is None:
   zregu='Regul=0.02'
else:
    zregu = 'Regul='+args.zrg
    
if args.zmF is None:
   zoomF='ZoomF=2'
else:
    zoomF = 'ZoomF='+args.zmF
    
if args.gp is None:
    mmgpu = 'mm3d'
    gP = '0'
else:
    mmgpu = '/home/ciaran/MicMacGPU/micmac/bin/mm3d'
    gP = '1'

if args.noT is None:
    mp = 4 
else:
    mp = args.noT




fld = args.fld


DMatch = path.join(fld, 'DMatch')
bFolder = path.join(fld, 'MaltBatch')


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
            numChunks]

call(tileIt)



#
txtList = glob(path.join(DMatch,'*.list'))
nameList = [path.split(i)[1] for i in txtList]
txtList.sort()
nameList .sort()
#list mania - I am crap at writing code
finalList = list(zip(txtList, nameList))

rejectList = []
# May revert to another way but lets see.....
def proc_malt(subList, subName, bFolder):
    # Yes all this string mucking about is not great but it is better than 
    # dealing with horrific xml, when the info is so simple
    flStr = open(subList).read()
    # first we need the box terrain line
    box = flStr.split('\n', 1)[0]
    # then the images
    imgs = flStr.split("\n", 1)[1]
    # If on a repeat run this should avoid problems
#    imgSeq = imgs.split()
    imgs.replace("\n", "|")
    sub = imgs.replace("\n", "|")
    print('the img subset is \n'+sub+'\n\n, the bounding box is '+box) 
    
    
    #This is getting messy....must find a way round this
#    for im in imgSeq:  
#        imNm = im+"_Ch3.tif"
#        imNmF = path.join("Tmp-MM-Dir", imNm)
#        imCmd = ["mm3d",  "MpDcraw",  imNmF, "Add16B8B=0",  "ConsCol=0",  
#                 "ExtensionAbs=None","16B=0",  "CB=1",  
#                 "NameOut=."+imNmF, "Gamma=2.2", "EpsLog=1.0"]
#        call(imCmd)
#        
    mm3d = [mmgpu, "Malt", algo,'"'+sub+'"', 'Ori-'+gOri, "DefCor=0", "DoOrtho=1",
            "SzW=1", "DirMEC="+subName,
            "UseGpu="+gP, zoomF, zregu, "NbProc=1", "EZA=1", box]
    ret = call(mm3d)
    if ret != 0:
        rejectList.append(subName)
        print(subName+" missed")
        pass
    else:       
        tawny = [mmgpu, 'Tawny', "Ortho-"+subName+'/', 'RadiomEgal=1', 
                 'Out=Orthophotomosaic.tif']
        call(tawny)
        mDir = path.join(fld, subName)
        oDir = path.join(fld, "Ortho-"+subName) 
        hd, tl = path.split(subList)
        subDir = path.join(bFolder, tl)
        mkdir(subDir)
        if path.exists(mDir):
            move(mDir, subDir)
        else:
            pass
        if path.exists(oDir):
            move(oDir, subDir)
        else:
            pass

if args.mx is None:
    Parallel(n_jobs=mp,verbose=5)(delayed(proc_malt)(i[0], 
         i[1], bFolder) for i in finalList) 
else:
    subFinal = finalList[0:args.mx]
    Parallel(n_jobs=mp,verbose=5)(delayed(proc_malt)(i[0], 
             i[1], bFolder) for i in subFinal) 

# This is here so we have some account of anything missed due to thread/gpu mem overload issues
print("Tiles missed for some reason were:")
[print(s) for s in rejectList]   
    
#
#
#def proc_tawny(file):
#    
#    tawny = ['mm3d', 'Tawny', file, 'RadiomEgal=1', 'DegRap=4',
#             'Out=Orthophotomosaic.tif']
#    call(tawny)


    


