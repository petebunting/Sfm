#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Mar 27 17:06:04 2019

@author: ciaran
"""

from subprocess import call
import argparse

from glob2 import glob
from os import path, mkdir, remove
from shutil import rmtree, move
#from joblib import Parallel, delayed
parser = argparse.ArgumentParser()

parser.add_argument("-folder", "--fld", type=str, required=True, 
                    help="path to wrkspace")

parser.add_argument("-algo", "--algotype", type=str, required=False, 
                    help="Micmac algo type eg Forest")

parser.add_argument("-e", "--imex", type=str, required=False, 
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

parser.add_argument("-max", "--mx", type=int, required=False, 
                    help="max no of chunks to do - this is for testing with a smaller subset")

parser.add_argument("-ovLap", "--ov", type=str, required=False, default='50', 
                    help="tile overlap")

parser.add_argument("-bbox", "--bb", type=bool, required=False, default=True, 
                    help="whether or not to box terrain - default is True")

args = parser.parse_args() 

if args.oRI is None:
   gOri= "Ground_UTM"
else:
    gOri = args.oRI

if args.algotype is None:
   algo= "UrbanMNE"
else:
    algo = args.algotype
#
#if args.noCh is None:
#    numChunks = '3,3'
#else:       
#    numChunks = args.noCh

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

ext = args.imex

bFolder = args.fld

bndList = ['B', 'G', 'R', 'NIR', 'RE']

def proc_malt(bFolder, gP='1', bbox=False):
    # Yes all this string mucking about is not great but it is better than 
    # dealing with horrific xml, when the info is so simple
    tLog = path.join(bFolder, "TawnyLogs")
    mkdir(tLog)
    mLog = path.join(bFolder, "MaltLogs")
    mkdir(mLog)
#    flStr = open(subList).read()
#    # first we need the box terrain line
#    box = flStr.split('\n', 1)[0]
#    # then the images
#    imgs = flStr.split("\n", 1)[1]
#    # If on a repeat run this should avoid problems
##    imgSeq = imgs.split()
#    imgs.replace("\n", "|")
#    sub = imgs.replace("\n", "|")
#    print('the img subset is \n'+sub+'\n\n, the bounding box is '+box) 
    
    # Outputting mm3d output to txt as it is better to keep track of multi process log
    if bbox ==True:
        mm3d = [mmgpu, "Malt", algo, '".*'+ext+'"', 'Ori-'+gOri, "DefCor=0", "DoOrtho=1",
                "SzW=1", "UseGpu="+gP, zoomF, zregu, "NbProc=1", "EZA=1", box]
    else:
        mm3d = [mmgpu, "Malt", algo,'".*'+ext+'"', 'Ori-'+gOri, "DefCor=0", "DoOrtho=1",
                "SzW=1", "UseGpu="+gP, zoomF, zregu, "NbProc=1", "EZA=1"]
    mf = open(subName+'Mlog.txt', "w")            
    ret = call(mm3d, stdout=mf)
    if ret != 0:        
        print(subName+" missed, will pick it up later")
        pass
    else:       
        tawny = [mmgpu, 'Tawny', "Ortho-MEC-Malt/", 'RadiomEgal=1', 
                 'Out=Orthophotomosaic.tif']
        tf = open(subName+'Tawnylog.txt', "w")  
        call(tawny, stdout=tf)
        mDir = path.join(fld, subName)
        oDir = path.join(fld, "Ortho-"+subName) 
#        pDir= path.join(fld, subName+"pyram")
        hd, tl = path.split(subList)
        subDir = path.join(bFolder, tl)
        mkdir(subDir)
        if path.exists(mDir):
            move(mDir, subDir)
            print('subName done')
        else:
            pass            
        if path.exists(oDir):
            move(oDir, subDir)
            print('subName mosaic done')
        else:
            pass