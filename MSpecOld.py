#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Mar 12 15:35:40 2019

@author: Ciaran Robb

A script for processing to surface reflectance 
"""
import os, sys
import matplotlib.pyplot as plt
from PIL import Image
import micasense.metadata as metadata
import micasense.utils as msutils
#import micasense.plotutils as plotutils
#import micasense.imageutils as imageutils
from micasense.panel import Panel
from micasense.image import Image as MImage
#import numpy as np
from glob2 import glob
import argparse
from subprocess import call
#import cv2
import imageio
from scipy.misc import bytescale

#import gdal, gdal_array
#from joblib import Parallel, delayed

exiftoolPath=None

parser = argparse.ArgumentParser()

parser.add_argument("-precal", "--pcal", type=str, required=True, 
                    help="path to pre flight calibration images")

parser.add_argument("-postcal", "--pstcal", type=str, required=False,
                    default=None, help="path to post flight calibration images")

parser.add_argument("-img", "--fimages", type=str, required=True, 
                    help="path to flight images")

parser.add_argument("-o", "--rimages", type=str, required=True, 
                    help="path to output reflectance directory")

#parser.add_argument("-n", "--noT", type=int, required=False, default=-1, 
#                    help="no of threads to use - defaults to all")

args = parser.parse_args() 

calibPre = os.path.abspath(args.pcal)

if args.pstcal != None:
    calibPost = os.path.abspath(args.pstcal)


imagesFolder = os.path.abspath(args.fimages)


ReflectanceimagesFolder = os.path.abspath(args.rimages)

#nt = args.noT



panelCalibration = { 
    "Blue": 0.67, 
    "Green": 0.69, 
    "Red": 0.68, 
    "Red edge": 0.61, 
    "NIR": 0.67 
}


#'''
#the old funcs will probably be canned
#'''
   
def calib(calibPre, panelCalibration):
    """
    Function to process pre and post flight panel images
    
    Parameters
    ----------  
    
    calibPre : string
            path to folder containing pre flight panels
    panelCalibration : string
            path to folder containing pre flight panels
    """
    imageList = glob(os.path.join(calibPre,"*.tif"))
    imageList.sort()
    
    outList = []
    
    
    for imageName in imageList:
        imageRaw=plt.imread(imageName).T  

        #Image metadata
        meta = metadata.Metadata(imageName, exiftoolPath=exiftoolPath)
        bandName = meta.get_item('XMP:BandName')
        #Converting raw images to Radiance
        radianceImage, L, V, R = msutils.raw_image_to_radiance(meta, imageRaw.T)
        ##plotutils.plotwithcolorbar(V,'Vignette Factor')
        ##plotutils.plotwithcolorbar(R,'Row Gradient Factor')
        ##plotutils.plotwithcolorbar(V*R,'Combined Corrections')
        ##plotutils.plotwithcolorbar(L,'Vignette and row gradient corrected raw values')
        ##plotutils.plotwithcolorbar(radianceImage,'All factors applied and scaled to radiance')
        img = MImage(imageName)
        panel = Panel(img)
        if not panel.panel_detected():
            raise IOError("Panel Not Detected!")
            sys.exit(1)
        
        # Well it should bloody work really shouldn't it
        plt.imshow(panel.plot_image())
        
        
        print("Detected panel serial: {}".format(panel.serial))
        meanRadiance, std, num, sat_count = panel.raw()
        
        print("Extracted Panel Statistics:")
        print("Mean: {}".format(meanRadiance))
        print("Standard Deviation: {}".format(std))
        print("Panel Pixel Count: {}".format(num))
        print("Saturated Pixel Count: {}".format(sat_count))
        
        print('Mean Radiance in panel region: {:1.3f} W/m^2/nm/sr'.format(meanRadiance))
        panelReflectance = panelCalibration[bandName]
        radianceToReflectance = panelReflectance / meanRadiance
        print('Radiance to reflectance conversion factor: {:1.3f}'.format(radianceToReflectance))
        
        #reflectanceImage = radianceImage * radianceToReflectance
        outList.append([bandName, radianceToReflectance])
        
    
    return outList
#plotutils.plotwithcolorbar(reflectanceImage, 'Converted Reflectane Image')

preList = calib(calibPre, panelCalibration)
#postList = calib(calibPost, panelCalibration)

#flightReflectanceImage = flightRadianceImage * radianceToReflectance
#mean Pre and Post Flight Calibration
r2rB1 = (preList[0][1])
r2rB2 = (preList[1][1])
r2rB3 = (preList[2][1])
r2rB4 = (preList[3][1])
r2rB5 = (preList[4][1])

#Write function to read band
def get_band(image):
    meta = metadata.Metadata(image, exiftoolPath=exiftoolPath)
    band = meta.get_item('XMP:BandName')
    return band

    
imageOutList = glob(os.path.join(imagesFolder, "*.tif"))

if len(imageOutList) == 0:
    print("check the raw images folder path")
    sys.exit(1)


def saveIm(image, r2rB1, r2rB2, r2rB3, r2rB4, r2rB5):
    
    meta = metadata.Metadata(image, exiftoolPath=exiftoolPath)
    band = meta.get_item('XMP:BandName')
    if band is None:
        print('no meta for'+str(image))
        pass

    meta = metadata.Metadata(image, exiftoolPath=exiftoolPath)
    ImageRaw=plt.imread(image)
    #Convert DN to Radiance
    flightRadianceImage, _, _, _ = msutils.raw_image_to_radiance(meta, ImageRaw)

    #Convert Radiance to Reflectance
    if band == "Blue":
        flightReflectanceImage = flightRadianceImage * r2rB1
    elif band == "Green":
        flightReflectanceImage = flightRadianceImage * r2rB2
    elif band == "Red":
        flightReflectanceImage = flightRadianceImage * r2rB3
    elif band == "NIR":
        flightReflectanceImage = flightRadianceImage * r2rB4
    elif band == "Red edge":
        flightReflectanceImage = flightRadianceImage * r2rB5
    else:
        print("error")
    #Export TIFF
    if not os.path.exists(ReflectanceimagesFolder):
        os.makedirs(ReflectanceimagesFolder)
    hd, tl = os.path.split(image)
    outfile = os.path.join(ReflectanceimagesFolder, tl)
    im = Image.fromarray(flightReflectanceImage)
    #im.save(outfile)
    
    img8 = bytescale(flightReflectanceImage)
    imageio.imwrite(outfile, img8)
    
    cmd = ["exiftool", "-tagsFromFile", image,  "-file:all", "-iptc:all",
           "-exif:all",  "-xmp", "-Composite:all", outfile, 
           "-overwrite_original"]
    call(cmd)
    
    return outfile
        #print(outfile)
        #End loop

outFiles = [saveIm(file, r2rB1, r2rB2, r2rB3, r2rB4, r2rB5)  for file in imageOutList]

# joblib cliams pos seg fault        
#outFiles = Parallel(n_jobs=nt,verbose=2)(delayed(saveIm)(image, r2rB1, r2rB2,
#                    r2rB3, r2rB4, r2rB5) for image in imageOutList) 
#             i, bFolder) for i in subFinal) 
#        
