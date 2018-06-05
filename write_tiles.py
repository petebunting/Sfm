#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Jun  5 15:04:58 2018

@author: ciaran
"""



# This works as a mechanism but the x y origin calculations are the wrong way.
# its putting the second tile (0,1) on top rather than at bottom of first one.....

from glob2 import glob
import gdal, osr
from os import path
import numpy as np
import re

folder = path.join("PIMs-ORTHO", "Orthophotomosaic_Tile")

wildcard = '*Orthophotomosaic_Tile*.tif'

tfwPth = path.join("PIMs-ORTHO", "Orthophotomosaic.tfw")

tfw = np.loadtxt(tfwPth)


fileList = glob(path.join(folder, wildcard))

fileList.sort()

#Tile 0_1 is same x,  and y = [origen y ] - (20480 x 0.028)
#Tile 1_0 is same y,  and x = [origen x ] + (20480 x 0.028)
#Tile 1_1 x = [origen x ] + (20480 x 0.028) , y like tile 0_1
#... etc

inRas = gdal.Open(fileList[0])

xor, pish, yipe,  yor, shite,  pixy  = inRas.GetGeoTransform()

X = inRas.RasterXSize
Y = inRas.RasterYSize


for file in fileList:
    
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
    
    srs.ImportFromEPSG(32630)
    
    print(cde)
    if cde is '0, 0':
        y_max = tfw[5] 
    elif cde is '0, 1':
        y_max = tfw[5] - (Y *  pix+pix)
    elif cde is '1, 0':
        x_min = tfw[0] - (X *  pix)
    elif cde is '1, 1':
        x_min = tfw[0] + (X *  pix)
        
    

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



