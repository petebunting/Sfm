#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Jun  5 15:04:58 2018

@author: ciaran robb

A script to georeference the tif tiles resulting from MicMac Tawny

"""



from glob2 import glob
import gdal, osr
from os import path
import numpy as np
from tqdm import tqdm
import argparse
import re
from math import sqrt

parser = argparse.ArgumentParser()

parser.add_argument("-folder", "--fld", type=str, required=True, 
                    help="path to folder - the micmac work dir")

parser.add_argument("-espg", "--esp", type=int, required=True, 
                    help="the code to project the tile to")


#parser.add_argument("-fmt", "--format", type=int, required=False, 
#                    help="index of first image")

#parser.add_argument("-dtype", "--data", type=int, required=False, 
#                    help="index of last image")




args = parser.parse_args() 

espg = args.esp

folder = args.fld

wildcard =  path.join("Ortho-MEC-Malt", '*Orthophotomosaic_Tile*.tif')

folderFinal = path.join(folder, wildcard)


wildcard2  = path.join("Ortho-MEC-Malt", "Orthophotomosaic.tfw")

tfwPth = path.join(folder, wildcard2)

tfw = np.loadtxt(tfwPth)


fileList = glob(folderFinal)

fileList.sort()

#Tile 0_1 is same x,  and y = [origen y ] - (20480 x 0.028)
#Tile 1_0 is same y,  and x = [origen x ] + (20480 x 0.028)
#Tile 1_1 x = [origen x ] + (20480 x 0.028) , y like tile 0_1
#... etc

inRas = gdal.Open(fileList[0])

xor, pish, yipe,  yor, shite,  pixy  = inRas.GetGeoTransform()

X = inRas.RasterXSize
Y = inRas.RasterYSize


for file in tqdm(fileList):
    
    fileStr = path.split(file)[1]
#    code = fileStr[:+4]
    
    code = re.findall('\d+', fileStr)
    
    cde =str(code)
    cde = cde.replace("[", "")
    cde = cde.replace("]", "")
    cde = cde.replace("'", "")
    
    outDataset = gdal.Open(file, gdal.GA_Update)
    
    pix = tfw[0]
    pixneg = tfw[3]
    x_min = tfw[4] 
    y_max = tfw[5]
    
    srs = osr.SpatialReference()
    
    srs.ImportFromEPSG(espg)
    
    #Tile 0_1 is same x,  and y = [origen y ] - (20480 x 0.028)
    #Tile 1_0 is same y,  and x = [origen x ] + (20480 x 0.028)
    #Tile 1_1 x = [origen x ] + (20480 x 0.028) , y like tile 0_1
    #... etc
    if cde == '0, 0':
        y_max = tfw[5] 
    elif cde == '0, 1':
        y_max = tfw[5] - (Y *  pix)
    elif cde == '1, 0':
        x_min = tfw[4] + (X *  pix)
    elif cde == '1, 1':
        Y2 = outDataset.RasterYSize
        X2 = outDataset.RasterXSize
        # well this should be correct - finding the hypotenuse length the
        # multiplying by the scale
        x_min =  x_min + (X2 * pix)
        y_max = x_min + (X2 * pix) - (Y2 *  pix)
        
    

    outDataset.SetGeoTransform((
        x_min,    # 0
        pix,  # 1
        0,                      # 2
        y_max,    # 3
        0,                      # 4
        pixneg)) 
    

    outDataset.SetProjection(srs.ExportToWkt())
    outDataset.FlushCache()
    outDataset=None



