#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Nov  5 12:45:39 2018

@author: ciaran

usage:
    mask_dsm.py -folder $PWD
"""

import gdal
import argparse
from glob2 import glob
import os
from tqdm import tqdm
from joblib import Parallel, delayed
import numpy as np
# This is taken from geospatial_learn and is here for convenience
# The lib function is more flexible than this script which is here to a masking operation specific to MicMac

def _copy_dataset_config(inDataset, FMT = 'Gtiff', outMap = 'copy',
                         dtype = gdal.GDT_Int32, bands = 1):
    """Copies a dataset without the associated rasters.

    """
    if FMT == 'HFA':
        fmt = '.img'
    if FMT == 'KEA':
        fmt = '.kea'
    if FMT == 'Gtiff':
        fmt = '.tif'
    
    x_pixels = inDataset.RasterXSize  # number of pixels in x
    y_pixels = inDataset.RasterYSize  # number of pixels in y
    geotransform = inDataset.GetGeoTransform()
    PIXEL_SIZE = geotransform[1]  # size of the pixel...they are square so thats ok.
    #if not would need w x h
    x_min = geotransform[0]
    y_max = geotransform[3]
    # x_min & y_max are like the "top left" corner.
    projection = inDataset.GetProjection()
    geotransform = inDataset.GetGeoTransform()   
    #dtype=gdal.GDT_Int32
    driver = gdal.GetDriverByName(FMT)
    
    # Set params for output raster
    outDataset = driver.Create(
        outMap+fmt, 
        x_pixels,
        y_pixels,
        bands,
        dtype)

    outDataset.SetGeoTransform((
        x_min,    # 0
        PIXEL_SIZE,  # 1
        0,                      # 2
        y_max,    # 3
        0,                      # 4
        -PIXEL_SIZE))
        
    outDataset.SetProjection(projection)
    
    return outDataset

def mask_raster_multi(inputIm,  mval=1, outval = None, mask=None,
                    blocksize = 256, FMT = None, dtype=None):
    """ 
    Perform a numpy masking operation on a raster where all values
    corresponding to  mask value are retained - does this in blocks for
    efficiency on larger rasters
    
    Parameters 
    ----------- 
    
    inputIm : string
              the granule folder 
        
    mval : int
           the masking value that delineates pixels to be kept
        
    outval : numerical dtype eg int, float
              the areas removed will be written to this value default is 0
        
    mask : string
            the mask raster to be used (optional)
        
    FMT : string
          the output gdal format eg 'Gtiff', 'KEA', 'HFA'
        
    mode : string
           None > 10m data, '20' >20m
        
    blocksize : int
                the chunk of raster read in & write out

    """

    if FMT == None:
        FMT = 'Gtiff'
        fmt = '.tif'
    if FMT == 'HFA':
        fmt = '.img'
    if FMT == 'KEA':
        fmt = '.kea'
    if FMT == 'Gtiff':
        fmt = '.tif'
    
    
    if outval == None:
        outval = 0
    
    inDataset = gdal.Open(inputIm, gdal.GA_Update)
    bands = inDataset.RasterCount
    
    bnnd = inDataset.GetRasterBand(1)
    cols = inDataset.RasterXSize
    rows = inDataset.RasterYSize

    
    
    # So with most datasets blocksize is a row scanline
    if blocksize == None:
        blocksize = bnnd.GetBlockSize()
        blocksizeX = blocksize[0]
        blocksizeY = blocksize[1]
    else:
        blocksizeX = blocksize
        blocksizeY = blocksize
    
    if mask != None:
        msk = gdal.Open(mask)
        maskRas = msk.GetRasterBand(1)
        
        for i in tqdm(range(0, rows, blocksizeY)):
            if i + blocksizeY < rows:
                numRows = blocksizeY
            else:
                numRows = rows -i
        
            for j in range(0, cols, blocksizeX):
                if j + blocksizeX < cols:
                    numCols = blocksizeX
                else:
                    numCols = cols - j
                mask = maskRas.ReadAsArray(j, i, numCols, numRows)
                if mval not in mask:
                    array = np.zeros(shape=(numRows,numCols), dtype=np.int32)
                    for band in range(1, bands+1):
                        bnd = inDataset.GetRasterBand(band)
                        bnd.WriteArray(array, j, i)
                else:
                    
                    for band in range(1, bands+1):
                        bnd = inDataset.GetRasterBand(band)
                        array = bnd.ReadAsArray(j, i, numCols, numRows)
                        array[mask != mval]=0
                        bnd.WriteArray(array, j, i)
                        
    else:
             
        for i in tqdm(range(0, rows, blocksizeY)):
                if i + blocksizeY < rows:
                    numRows = blocksizeY
                else:
                    numRows = rows -i
            
                for j in range(0, cols, blocksizeX):
                    if j + blocksizeX < cols:
                        numCols = blocksizeX
                    else:
                        numCols = cols - j
                    for band in range(1, bands+1):
                        bnd = inDataset.GetRasterBand(1)
                        array = bnd.ReadAsArray(j, i, numCols, numRows)
                        array[array != mval]=0
                        if outval != None:
                            array[array == mval] = outval     
                            bnd.WriteArray(array, j, i)
        # This is annoying but necessary as the stats need updated and cannot be 
        # done in above band loop due as this would be very inefficient
        #for band in range(1, bands+1):
        #inDataset.GetRasterBand(1).ComputeStatistics(0)
           
        inDataset.FlushCache()
        inDataset = None
        
#MAIN script------------------------------------------------------------------        
parser = argparse.ArgumentParser()




parser.add_argument("-folder", "--fld", type=str, required=True, 
                    help="input dsm")



args = parser.parse_args() 


wildCard1 = '*tile*/*MEC-Malt/Z_Num7_DeZoom2_STD-MALT.tif'
wildCard2 = '*tile*/*MEC-Malt/AutoMask_STD-MALT_Num_6.tif'

fileListIm = glob(os.path.join(args.fld, wildCard1))
fileListMsk = glob(os.path.join(args.fld, wildCard2))

fileListIm.sort()
fileListMsk.sort()


finalList = list(zip(fileListIm, fileListMsk))

Parallel(n_jobs=-1,
         verbose=3)(delayed(mask_raster_multi)(f[0],
                   mask=f[1]) for f in finalList)






