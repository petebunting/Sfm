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
from os import path

parser = argparse.ArgumentParser()

parser.add_argument("-folder", "--fld", type=str, required=True, 
                    help="path to wrkspace")

parser.add_argument("-algo", "--algotype", type=str, required=False, 
                    help="Micmac algo type eg Forest")

parser.add_argument("-num", "--noCh", type=int, required=False, 
                    help="number of images per chunk")
#
parser.add_argument("-zoom", "--zmF", type=int, required=False, 
                    help="Zoom level - eg 1=1 point per pixel, 2 = 1 point per  4 pixels")

args = parser.parse_args() 

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

if args.zmF is None:
   zoomF=2
else:
    zoomF = args.zmF
              

numChunks = args.noCh
#maxIm = args.noIm2

fld = args.fld

imList = glob(path.join(fld, '*.JPG'))

imList.sort()

sections = chunkIt(imList, numChunks)
#subList = imList[minIm:maxIm]

mm3dpth = '/home/ciaran/MicMacGPU/micmac/bin/mm3d'

zm = "ZoomF="+str(zoomF)
for index, subList in enumerate(sections):
    subList = [path.split(item)[1] for item in subList]
    subStr = str(subList)
    sub2 = subStr.replace("[", "")
    sub2 = sub2.replace("]", "")
    sub2 = sub2.replace("'", "") 
    sub2 = sub2.replace(", ", "|")
    
    
                     
    mm3d = [mm3dpth, "PIMs", algo, sub2, "Ground_UTM", "DefCor=0",
            "SzW=1",
            "UseGpu=1", zm]
    print('the img subset is '+sub2+'\n\n')  
    call(mm3d)
    print(str(index)+' is done\n\n')
