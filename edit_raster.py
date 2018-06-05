#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Jun  5 10:24:52 2018

@author: ciaran
"""
import gdal 

import argparse
from subprocess import call
from glob2 import glob
from os import path

parser = argparse.ArgumentParser()

parser.add_argument("-inRas", "--inR", type=str, required=True, 
                    help="path to csv file")

parser.add_argument("-edRas", "--outR", type=str, required=True, 
                    help="Micmac algo type eg RadialBasic")
parser.add_argument("-pixsize", "--pix", type=float, required=False, 
                    help="Micmac algo type eg RadialBasic")

#parser.add_argument("-fmt", "--format", type=int, required=False, 
#                    help="index of first image")

#parser.add_argument("-dtype", "--data", type=int, required=False, 
#                    help="index of last image")

args = parser.parse_args() 

inDataset = gdal.Open(args.inR)
outDataset = gdal.Open(args.outR, gdal.GA_Update)

#if args.format:
#    FMT = args.format
#elif args.data:    
#    dtype = args.data
#
#
#if FMT == 'HFA':
#    fmt = '.img'
#if FMT == 'KEA':
#    fmt = '.kea'
#if FMT == 'Gtiff':
#    fmt = '.tif'

x_pixels = inDataset.RasterXSize  # number of pixels in x
y_pixels = inDataset.RasterYSize  # number of pixels in y
geotransform = inDataset.GetGeoTransform()

if args.pix:
    PIXEL_SIZE=args.pix
else:    
    PIXEL_SIZE = geotransform[1]  # size of the pixel...they are square so thats ok.
#if not would need w x h
x_min = geotransform[0]
y_max = geotransform[3]
# x_min & y_max are like the "top left" corner.
projection = inDataset.GetProjection()
geotransform = inDataset.GetGeoTransform()   
#dtype=gdal.GDT_Int32
#driver = gdal.GetDriverByName(FMT)

# Set params for output raster
#    outDataset = driver.Create(
#        outMap+fmt, 
#        x_pixels,
#        y_pixels,
#        bands,
#        dtype)

outDataset.SetGeoTransform((
    x_min,    # 0
    PIXEL_SIZE,  # 1
    0,                      # 2
    y_max,    # 3
    0,                      # 4
    -PIXEL_SIZE))
    
outDataset.SetProjection(projection)

outDataset.FlushCache()

