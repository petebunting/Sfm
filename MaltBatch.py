#!/home/ciaran/anaconda3/bin/python
# -*- coding: utf-8 -*-
"""
Created on Tue May 29 16:20:58 2018

@author: ciaran

This scripts tiles large datsets for micmac and processes in parallel or sequnce depending 

This uses Malt which appear to be better for orthophoto generation

Gpu use is optional

Tends to overload 11gb GPU with around 30 images+

Usage: 
    
MaltBatch.py -folder $PWD -algo UrbanMNE -num 3,3 -zr 0.01 -g 1 -nt 3 -p 4

Here we are are using yhe UrbaMNE algorithm on a 3x3 grid of tiles, using the gpu,
processing 3 tiles in parallel, with four threads allocated to each

"""

#import pandas as pd
import argparse
from subprocess import call
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

parser.add_argument("-p", "--prc", type=bool, required=False, 
                   help="no of threads per chunk")

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
   zregu='Regul=0.01'
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

if args.prc is None:
# joblib is prettt srtict on the thread front so thread cannot even be allocated externally    
    proc = 1
else:
    proc = args.prc
                        

fld = args.fld


DMatch = path.join(fld, 'DMatch')
bFolder = path.join(fld, 'MaltBatch')
distMatch = path.join(fld, 'DistributedMatching.xml')

binList = [DMatch, bFolder]


# Some funcs for use later tile one from pymicmac

# folders to bin
for crap in binList:
    try:       
        rmtree(crap)
        
    except OSError:
        pass
# files to bin
try:
    remove(distMatch)
except OSError:
        pass

mkdir(bFolder)
# run tiling

pk = str(proc)

pymicmac = ['tile.py', '-i', 'Ori-'+gOri, '-e',
            'JPG', '-o', 'DistributedMatching.xml', '-f', 'DMatch', '-n',
            numChunks]

call(pymicmac)



#
txtList = glob(path.join(DMatch,'*.list'))
nameList = [path.split(i)[1] for i in txtList]
txtList.sort()
nameList .sort()
#list mania - I am crap at writing code
finalList = list(zip(txtList, nameList))


# May revert to another way but lets see.....
def proc_malt(subList, subName, bFolder):
    
    flStr = open(subList).read()
    flStr.replace("\n", "|")
    sub = flStr.replace("\n", "|")
    print('the img subset is \n'+sub+'\n\n')    
            
    mm3d = [mmgpu, "Malt", algo,'"'+sub+'"', gOri, "DefCor=0", "DoOrtho=1",
            "SzW=1", "DirMEC="+subName,
            "UseGpu="+gP, zoomF, zregu, "NbProc="+pk] #, 'SH=_mini']
    call(mm3d)
    tawny = ['mm3d', 'Tawny', "Ortho-"+subName+'/', 'RadiomEgal=1', 'DegRap=4',
             'Out=Orthophotomosaic.tif']
    call(tawny)
    mDir = path.join(fld, subName)
    oDir = path.join(fld, "Ortho-"+subName) 
    hd, tl = path.split(subList)
    subDir = path.join(bFolder, tl)
    mkdir(subDir)
    move(mDir, subDir)
    move(oDir, subDir)



Parallel(n_jobs=mp,verbose=5)(delayed(proc_malt)(i[0], 
         i[1], bFolder) for i in finalList)    
    
#

def proc_tawny(file):
    
    tawny = ['mm3d', 'Tawny', file, 'RadiomEgal=1', 'DegRap=4',
             'Out=Orthophotomosaic.tif']
    call(tawny)


    


