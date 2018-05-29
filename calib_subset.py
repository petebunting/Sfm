#!/home/ciaran/anaconda3/bin/python
# -*- coding: utf-8 -*-
"""
Created on Tue May 29 16:20:58 2018

@author: ciaran
"""

import pandas as pd
import argparse
from subprocess import call

parser = argparse.ArgumentParser()

parser.add_argument("-csv", "--csv_fle", type=str, required=True, 
                    help="path to csv file")

parser.add_argument("-algo", "--algotype", type=str, required=False, 
                    help="Micmac algo type eg RadialBasic")

parser.add_argument("-no", "--noIm", type=int, required=False, 
                    help="no of images - this will be from the start of the images")

args = parser.parse_args() 

if args.algotype is None:
    args.algotype = "RadialBasic"
elif args.noIm is None:
    args.noIm = 25

dF = pd.read_table(args.csv_fle)

maxIm = args.noIm
subList = list(dF['#F=N'][0:maxIm])
                  
                 
subStr = str(subList)

sub2 = subStr.replace("[", "")
sub2 = sub2.replace("'", "") 
sub2 = sub2.replace(", ", "|")                 

mm3d = ["mm3d", "Tapas", args.algotype, sub2, "Out=Sample4Calib-Rel"]

call(mm3d)