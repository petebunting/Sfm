#!/home/ciaran/anaconda3/bin/python
# -*- coding: utf-8 -*-
"""
Created on Tue May 29 16:20:58 2018

@author: ciaran
"""

#import pandas as pd
import argparse
from subprocess import call
from glob2 import glob
from os import path

parser = argparse.ArgumentParser()

parser.add_argument("-folder", "--fld", type=str, required=True, 
                    help="path to csv file")

parser.add_argument("-algo", "--algotype", type=str, required=False, 
                    help="Micmac algo type eg RadialBasic")

parser.add_argument("-start", "--noIm", type=int, required=False, 
                    help="index of first image")

parser.add_argument("-end", "--noIm2", type=int, required=False, 
                    help="index of last image")

args = parser.parse_args() 

if args.algotype is None:
   algo= "Fraser"
else:
    algo = args.algotype
       

minIm = args.noIm
maxIm = args.noIm2

fld = args.fld

imList = glob(path.join(fld, '*.JPG'))

imList.sort()


subList = imList[minIm:maxIm]

subList = [path.split(item)[1] for item in subList]

subStr = str(subList)

sub2 = subStr.replace("[", "")
sub2 = sub2.replace("]", "")
sub2 = sub2.replace("'", "") 
sub2 = sub2.replace(", ", "|")                 

mm3d = ["mm3d", "Tapas", algo, sub2, "Out=Sample4Calib-Rel"]
#'SH=_mini', 

call(mm3d)