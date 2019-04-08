#!/home/ciaran/anaconda3/bin/python
# -*- coding: utf-8 -*-
"""
Created on Tue May 29 16:20:58 2018

@author: ciaran

calib_subset.py -folder mydir -algo Fraser  -csv mycsv.csv

"""

#import pandas as pd
import argparse
from subprocess import call
#from glob2 import glob
#from os import path
import pandas as pd

parser = argparse.ArgumentParser()

parser.add_argument("-folder", "--fld", type=str, required=True, 
                    help="working folder with imagery")

parser.add_argument("-algo", "--algotype", type=str, required=False, 
                    help="Micmac algo type eg Fraser, RadialBasic")

parser.add_argument("-ext", "--extension", type=str, required=False, 
                    help="image extention .tif, .jpg")

helpMecsv = ("csv of subset - you should have produced this from main dataset\n"
             "This must be formatted in micmac convention #F=N X Y Z K W P"
             " with spaces as delimiter\n Hint: \n Save a selection of the csv"
             "in QGIS remembering to make the delimiter TAB")
             
parser.add_argument("-csv", "--csV", type=str, required=False, 
                    help=helpMecsv)
#
#parser.add_argument("-end", "--noIm2", type=int, required=False, 
#                    help="index of last image")

args = parser.parse_args() 

if args.algotype is None:
   algo= "Fraser"
else:
    algo = args.algotype
       

fld = args.fld

dF = pd.read_table(args.csV)

imList = list(dF['#F=N'])
imList.sort()


#subList = [path.split(item)[1] for item in imList]

subStr = str(imList)

sub2 = subStr.replace("[", "")
sub2 = sub2.replace("]", "")
sub2 = sub2.replace("'", "") 
sub2 = sub2.replace(", ", "|")                 

mm3d = ["mm3d", "Tapas", "Fraser", sub2,  "Out=Calib", "SH=_mini"]

mm3dFinal = ["mm3d", "Tapas", "Fraser", args.extenstion, "Out=Arbitrary", "InCal=Calib", "SH=_mini"]

call(mm3d)

call(mm3dFinal)
