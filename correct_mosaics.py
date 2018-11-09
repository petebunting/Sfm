#!/home/ciaran/anaconda3/bin/python

"""
Created on Tue May 29 16:20:58 2018

@author: ciaran

This scripts corrects and renames mosaics that have tiles as part of the gpymicmac procedure


Usage: 
    
correct_mosaics.py -folder $PWD 

"""
from glob2 import glob
import subprocess
import os
import argparse


# This is a bit of a kludge just now but does the job...., why micmac doesn't have an overwrite for convertIm I dont know

wildCard = '*tile*/*Ortho-MEC-Malt/*tile*.tif'

#TODO add dsm tiling??
#wildCard2 = '*tile*/*MEC-Malt/*tile*.tif'

parser = argparse.ArgumentParser()

parser.add_argument("-folder", "--fld", type=str, required=True, 
                    help="path to wrkspace")

args = parser.parse_args() 

folder = args.fld

fileList = glob(os.path.join(folder,wildCard))
#fileList2 = glob(os.path.join(folder,wildCard2))
procList=[]

print('correcting orthomosaics')
for file in fileList:
    fld, fle = os.path.split(file)
    oPath = os.path.join(fld, 'Orthophotomosaic.tif')
    oPath2 = os.path.join(fld, 'OrthFinal.tif')
    cmd=['mm3d', 'ConvertIm', oPath, 'Out='+oPath2]
    subprocess.call(cmd)
    os.remove(oPath) 
    os.rename(oPath2, oPath)
    
#print('correcting DSMs')
#for file in fileList2:
#    fld, fle = os.path.split(file)
#    oPath = os.path.join(fld, 'Orthophotomosaic.tif')
#    oPath2 = os.path.join(fld, 'OrthFinal.tif')
#    cmd=['mm3d', 'ConvertIm', oPath, 'Out='+oPath2]
#    subprocess.call(cmd)
#    os.remove(oPath) 
#    os.rename(oPath2, oPath)