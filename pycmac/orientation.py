#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Jun 12 13:54:55 2019

@author: Ciaran Robb

A module which calls Micmac dense matching commands

This is just for convenince  to keep everything in python - MicMac has an
excellent command line

https://github.com/Ciaran1981/Sfm

"""

from subprocess import call
from os import path, chdir
#import gdal
#import imageio
import sys
from glob2 import glob
#import osr
from PIL import Image
from pycmac.utilities import calib_subset, make_sys_utm, make_xml
from joblib import Parallel, delayed



def _imresize(image, width):
    
    img = Image.open(image)
    wpercent = (width / float(img.size[0]))
    hsize = int((float(img.size[1]) * float(wpercent)))
    
    img2 = img.resize((width, hsize), Image.ANTIALIAS)
    
    img2.save(image)

def _callit(cmd, log=None):
    ret = call(cmd, stdout=log)
    
    if ret !=0:
            print('A micmac error has occured - check the log file')
            sys.exit()

def feature_match(folder, csv=None, proj="30 +north", resize=None, ext="JPG", schnaps=True):
    
    """
    
    A function running the feature detection and matching with micmac 
            
    Notes
    -----------
    
    Purely for convenience within python - not  necessary - the mm3d cmd line
    is perfectly good
    
   
        
    Parameters
    -----------
    
    folder : string
           working directory
    proj : string
           a UTM zone eg "30 +north" 
        
    resize : string
             The long axis in pixels to optionally resize the imagery
        
    ext : string
                 image extention e.g JPG, tif

    
       
    """
    
    extFin = '.*'+ext   
    
    chdir(folder)
    
    projF = "+proj=utm +zone="+proj+"+ellps=WGS84 +datum=WGS84 +units=m +no_defs"
    make_sys_utm(folder, projF)
    
    make_xml(csv, folder)
    
    featlog = open(path.join(folder, 'Featlog.txt'), "w")
    
    if csv is None:
                     
        xif = ['mm3d', 'XifGps2Txt', extFin]
        
        _callit(xif, featlog)                            
        
        gpxml = ["mm3d", "XifGps2Xml", extFin, "RAWGNSS"]
        
        _callit(gpxml, featlog)
        
            
        oriCon = ["mm3d", "OriConvert", '"#F=N X Y Z"', 
                  "GpsCoordinatesFromExif.txt","RAWGNSS_N",
                  "ChSys=DegreeWGS84@RTLFromExif.xml", "MTD1=1",
                  "NameCple=FileImagesNeighbour.xml" "CalcV=1"]
        _callit(oriCon, featlog)
        

    else:
        oriCon= ["mm3d", "OriConvert", "OriTxtInFile", csv, "RAWGNSS_N",
                 "ChSys=DegreeWGS84@SysUTM.xml", "MTD1=1",  
                 "NameCple=FileImagesNeighbour.xml", "CalcV=1"]
        _callit(oriCon, featlog)
    
    imList = glob(path.join(folder, "*"+ext))
    

    
    Parallel(n_jobs=-1, verbose=5)(delayed(_imresize)(i, resize) for i in imList)
        
    tapi = ["mm3d", "Tapioca", "File", "FileImagesNeighbour.xml", "-1", "@SFS"]
    _callit(tapi)
    
    if schnaps is True:
        schnapi = ["mm3d", "Schnaps", extFin, "MoveBadImgs=1"]
        _callit(schnapi, featlog)
        
    
     
       

def bundle_adjust(folder, algo="Fraser", csv=None, proj="30 +north",
                  ext="JPG", calib=None, SH="_mini"):
    """
    
    A function running the relative orientation/bundle adjustment with micmac 
            
    Notes
    -----------
    
    Purely for convenience within python - not  necessary - the mm3d cmd line
    is perfectly good
    
    
        
    Parameters
    -----------
    
    folder : string
           working directory
    proj : string
           a UTM zone eg "30 +north" 
    csv : string
            a csv file of image coordinates in micmac format
    calib : string
            a calibration subset (optional)
    ext : string
                 image extention e.g JPG, tif
    SH : a reduced set of tie points (output of schnaps command)
                 image extention e.g JPG, tif
    
       
    """
    if SH is None:
        shFin=""
    else:
        shFin = "SH="+SH
    
    extFin = '.*'+ext  
    
    if calib != None:
        calib_subset(folder, csv, ext="JPG",  algo="Fraser")
    else: 
        tlog = open(path.join(folder, algo+'log.txt'), "w")
        tapas = ["mm3d", "Tapas", extFin, "Out=Arbitrary",  shFin]
        _callit(tapas, tlog)

