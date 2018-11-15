#!/home/ciaran/anaconda3/bin/python
# -*- coding: utf-8 -*-
"""
Created on Tue May 29 16:20:58 2018

@author: ciaran

This scripts calls the MicMac PIMs function in chunks to ensure GPU memory is not overloaded

Tends to overload 11gb GPU with around 30 images+

This takes advantage of the fact it all gets written to the PIMs folder without overwrite

Usage: 
    
pims_subset.py -folder $PWD -algo MicMac -num 20

"""

#import pandas as pd
import argparse
from subprocess import call
from glob2 import glob
from os import path, mkdir, remove
import shutil
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
                    help="z reg term context dependent")


args = parser.parse_args() 

if args.algotype is None:
   algo= "Ground_UTM"
else:
    gOri = args.oRI


def chunkIt(seq, num):
    avg = len(seq) / float(num)
    out = []
    last = 0.0

    while last < len(seq):
        out.append(seq[int(last):int(last + avg)])
        last += avg
    return out


if args.algotype is None:
   algo= "MicMac"
else:
    algo = args.algotype

if args.zrg is None:
   zregu='ZReg=0.01'
else:
    zregu = 'ZReg='+args.zrg
if args.zmF is None:
   zoomF='ZoomF=2'
else:
    zoomF = 'ZoomF='+args.zmF
                            
numChunks = args.noCh
#maxIm = args.noIm2

#fld = args.fld

#imList = glob(path.join(fld, '*.JPG'))

#imList.sort()

#sections = chunkIt(imList, numChunks)
#subList = imList[minIm:maxIm]

#mm3dpth = '/home/ciaran/MicMacGPU/micmac/bin/mm3d'

# Use pymicmac tiling to define the pims groups
# first get rid of previous
DMatch = path.join(args.fld, 'DMatch')
bFolder = path.join(args.fld, 'PIMsBatch')
distMatch = path.join(args.fld, 'DistributedMatching.xml')

try:
    remove(DMatch)
    remove(distMatch)
    remove(bFolder)
except OSError:
    pass

mkdir(bFolder)
# run tiling
pymicmac = ['micmac-distmatching-create-config', '-i', 'Ori-Ground_UTM', '-e',
            'JPG', '-o', 'DistributedMatching.xml', '-f', 'DMatch', '-n',
            numChunks, '--maltOptions', 
            "DefCor=0 DoOrtho=1 UseGpu=1 SzW=1 NbProc=8 ZoomF=2"]

call(pymicmac)



#
txtList = glob(path.join(DMatch,'*.list'))


for index, subList in enumerate(txtList):
    flStr = open(subList).read()
    flStr.replace("\n", "|")
    sub = flStr.replace("\n", "|")
                   
    mm3d = ['mm3d', "PIMs", algo,'"'+sub+'"', gOri, "DefCor=0",
            "SzW=1",
            "UseGpu=1", zoomF, zregu, 'SH=_mini']
    call(mm3d)
    shutil.move('PIMsForest', path.join(bFolder, subList))
    mnt = ['mm3d', 'PIMs2MNT', subList, 'DoOrtho=1', zregu]
    call(mnt)
    
    tawny = ['mm3d', 'Tawny', subList+'/PIMs-ORTHO/', 'RadiomEgal=1',
             'Out=Orthophotomosaic.tif']
    print('the img subset is \n'+sub+'\n\n')  
    
    call(tawny)

