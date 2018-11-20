#!/home/ciaran/anaconda3/bin/python
# -*- coding: utf-8 -*-
"""
Created on Tue May 29 16:20:58 2018

@author: ciaran

This scripts calls the MicMac PIMs function in chunks for large datasets - gpu use is optional

Tends to overload 11gb GPU with around 30 images+

This uses pymicmac functionality to tile the datset into a grid then processes in sequence

Usage: 
    
pims_subset.py -folder $PWD -algo Forest -num 3,3 -zr 0.02 -g 1 

"""

#import pandas as pd
import argparse
from subprocess import call
from glob2 import glob
from os import path, mkdir, remove
from shutil import rmtree, move
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

args = parser.parse_args() 

if args.oRI is None:
   gOri= "Ground_UTM"
else:
    gOri = args.oRI

if args.algotype is None:
   algo= "BigMac"
else:
    algo = args.algotype

if args.noCh is None:
    numChunks = '3,3'
else:       
    numChunks = args.noCh

if args.zrg is None:
   zregu='ZReg=0.01'
else:
    zregu = 'ZReg='+args.zrg
    
if args.zmF is None:
   zoomF='ZoomF=2'
else:
    zoomF = 'ZoomF='+args.zmF
    
if args.gp is None:
    mmgpu = 'mm3d'
else:
    mmgpu = '/home/ciaran/MicMacGPU/micmac/bin/mm3d'

                        
#maxIm = args.noIm2

fld = args.fld

#imList = glob(path.join(fld, '*.JPG'))

#imList.sort()

#sections = chunkIt(imList, numChunks)
#subList = imList[minIm:maxIm]

DMatch = path.join(args.fld, 'DMatch')
bFolder = path.join(args.fld, 'PIMsBatch')
distMatch = path.join(args.fld, 'DistributedMatching.xml')

binList = [DMatch, bFolder]

for crap in binList:
    try:       
        rmtree(crap)
        
    except OSError:
        pass

try:
    remove(distMatch)
except OSError:
        pass

mkdir(bFolder)
# run tiling
pymicmac = ['micmac-distmatching-create-config', '-i', 'Ori-'+gOri, '-e',
            'JPG', '-o', 'DistributedMatching.xml', '-f', 'DMatch', '-n',
            numChunks, '--maltOptions', 
            "DefCor=0 DoOrtho=1 UseGpu=1 SzW=1 NbProc=8 ZoomF=2"]

call(pymicmac)


origList = [path.join(fld, 'PIMs-'+algo), 
            path.join(fld, 'PIMs-TmpBasc'),
            path.join(fld, 'PIMs-ORTHO'),
            path.join(fld, 'PIMs-TmpMnt'),
            path.join(fld, 'PIMs-TmpMntOrtho')]
#
txtList = glob(path.join(DMatch,'*.list'))


# Some very ugly stuff going on in here
for subList in txtList:
    flStr = open(subList).read()
    flStr.replace("\n", "|")
    sub = flStr.replace("\n", "|")
    print('the img subset is \n'+sub+'\n\n')                 
    mm3d = [mmgpu, "PIMs", algo,'"'+sub+'"', gOri, "DefCor=0",
            "SzW=1",
            "UseGpu=1", zoomF, zregu, 'SH=_mini']
    call(mm3d)
    pmsDir = path.join(fld,'PIMs-Forest')
    
    hd, tl = path.split(subList)
    subDir = path.join(bFolder, tl)
    mkdir(subDir)
    mnt = ['mm3d', 'PIMs2MNT', algo, 'DoOrtho=1', zregu]
    call(mnt)
  
    tawny = ['mm3d', 'Tawny', 'PIMs-ORTHO/', 'RadiomEgal=1', 'DegRap=4',
             'Out=Orthophotomosaic.tif']
    call(tawny)
    
    # sooooo ugly I am getting very lazy
    newPIMs = path.join(subDir, 'PIMs-Forest')
    newBasc = path.join(subDir, 'PIMs-TmpBasc')
    newOrtho = path.join(subDir, 'PIMs-ORTHO')
    newTmpM = path.join(subDir, 'PIMs-TmpMnt')
    newTmpMO = path.join(subDir, 'PIMs-TmpMntOrtho')
    mvList = [newPIMs, newBasc, newOrtho, newTmpM, newTmpMO]
    toGo = list(zip(origList, mvList))
    [move(f[0], f[1]) for f in toGo] 
    print(mvList+'moved')
    
    


