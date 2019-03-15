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
import micasense.imageutils as imageutils
import micasense.capture as capture
from micasense.panel import Panel
from micasense.image import Image as MImage
import numpy as np
import micasense.imageset as imageset
from glob2 import glob
import argparse
from subprocess import call
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

parser.add_argument("-alIm", "--alg", type=int, required=False, default=-1, 
                    help="no of threads to use - defaults to all")

args = parser.parse_args() 

calibPre = os.path.abspath(args.pcal)

if args.pstcal != None:
    calibPost = os.path.abspath(args.pstcal)


imagesFolder = os.path.abspath(args.fimages)


ReflectanceimagesFolder = os.path.abspath(args.rimages)

nt = args.noT


print("Alinging images. Depending on settings this can take from a few seconds to many minutes")
# Increase max_iterations to 1000+ for better results, but much longer runtimes
'''
Right so each capture means each set of bands 1-5
This requires the image list to be sorted in a way that can be aligned
It appears as though micasense have done this with their lib

'''

#capture = capture.Capture.from_filelist(imagesFolder)
##
##
#warp_matrices, alignment_pairs = imageutils.align_capture(capture, max_iterations=100)
##
#print("Finished Aligning, warp matrices:")
#for i,mat in enumerate(warp_matrices):
#    print("Band {}:\n{}".format(i,mat))

panel_ref = [0.67, 0.69, 0.68, 0.61, 0.67]

imgset = imageset.ImageSet.from_directory(imagesFolder)


preCapList = glob(os.path.join(calibPre, "*.tif"))
preCapList.sort()
pCapPre = capture.Capture.from_filelist(preCapList) 
pPreIr = pCapPre.panel_irradiance(panel_ref)

if args.pstcal != None:
    pCapPost = capture.Capture.from_filelist(glob(calibPost, "*.tif")) 

    pPostIr = pCapPost.panel_irradiance(panel_ref)

    panel_irradiance = (pPreIr + pPostIr) / 2
else:
    panel_irradiance = pPreIr
 #RedEdge band_index order

# First we must find an image with decent features from which a band alignment 
# can be applied to the whole dataset
 
wildCrd = "IMG_0007"+args.alg+"*.tif"
algList = glob(os.path.join('000', wildCrd))
algList.sort()
imAl = capture.Capture.from_filelist(algList) 
imAl.compute_reflectance(panel_irradiance)
imAl.plot_undistorted_reflectance(panel_irradiance)

def align_template(imAl, mx):
    warp_matrices, alignment_pairs = imageutils.align_capture(imAl, max_iterations=mx)
    for x,mat in enumerate(warp_matrices):
        print("Band {}:\n{}".format(x,mat))
    dist_coeffs = []
    cam_mats = []
    # create lists of the distortion coefficients and camera matricies
    for im,img in enumerate(imAl.images):
        dist_coeffs.append(img.cv2_distortion_coeff())
        cam_mats.append(img.cv2_camera_matrix())
    # cropped_dimensions is of the form:
    # (first column with overlapping pixels present in all images, 
    #  first row with overlapping pixels present in all images, 
    #  number of columns with overlapping pixels in all images, 
    #  number of rows with overlapping pixels in all images   )
    cropped_dimensions = imageutils.find_crop_bounds(imAl.images[0].size(), 
                                                     warp_matrices, 
                                                     dist_coeffs, 
                                                     cam_mats)
    
    im_aligned = imageutils.aligned_capture(warp_matrices, alignment_pairs, cropped_dimensions)
    im_display = np.zeros((im_aligned.shape[0],im_aligned.shape[1],5), dtype=np.float32 )
    
    for i in range(0,im_aligned.shape[2]):
        im_display[:,:,i] =  imageutils.normalize(im_aligned[:,:,i])
        
    rgb = im_display[:,:,[2,1,0]] 
    cir = im_display[:,:,[3,2,1]] 
    fig, axes = plt.subplots(1, 2, figsize=(16,16)) 
    plt.title("Red-Green-Blue Composite") 
    axes[0].imshow(rgb) 
    plt.title("Color Infrared (CIR) Composite") 
    axes[1].imshow(cir) 
    plt.show()
    
    return warp_matrices, alignment_pairs, dist_coeffs, cam_mats, cropped_dimensions

for i in imgset.captures: 
    i.compute_reflectance(panel_irradiance) 
    #i.plot_undistorted_reflectance(panel_irradiance)  
    #warp_matrices, alignment_pairs = imageutils.align_capture(i, max_iterations=1000)
    for x,mat in enumerate(warp_matrices):
        print("Band {}:\n{}".format(x,mat))
    dist_coeffs = []
    cam_mats = []
    # create lists of the distortion coefficients and camera matricies
    for im,img in enumerate(i.images):
        dist_coeffs.append(img.cv2_distortion_coeff())
        cam_mats.append(img.cv2_camera_matrix())
    # cropped_dimensions is of the form:
    # (first column with overlapping pixels present in all images, 
    #  first row with overlapping pixels present in all images, 
    #  number of columns with overlapping pixels in all images, 
    #  number of rows with overlapping pixels in all images   )
    cropped_dimensions = imageutils.find_crop_bounds(i.images[0].size(), 
                                                     warp_matrices, 
                                                     dist_coeffs, 
                                                     cam_mats)

    im_aligned = imageutils.aligned_capture(warp_matrices, alignment_pairs, cropped_dimensions)
    im_display = np.zeros((im_aligned.shape[0],im_aligned.shape[1],5), dtype=np.float32)
    

    for k in range(0,im_aligned.shape[2]):
        im_display[:,:,k] =  imageutils.normalize(im_aligned[:,:,k])
# Only here for experimentation
#    rgb = im_display[:,:,[2,1,0]]
#    cir = im_display[:,:,[3,2,1]]
#    fig, axes = plt.subplots(1, 2, figsize=(16,16))
#    plt.title("Red-Green-Blue Composite")
#    axes[0].imshow(rgb)
#    plt.title("Color Infrared (CIR) Composite")
#    axes[1].imshow(cir)
#    plt.show()
#    rows, cols, bands = im_display.shape
#    driver = gdal.GetDriverByName('GTiff')
#    outRaster = driver.Create("bgren.tiff", 
#                              cols, rows, bands, gdal.GDT_Float32)
#    
#    
#    for ras in range(0,bands):
#        outband = outRaster.GetRasterBand(ras+1)
#        outband.WriteArray(im_aligned[:,:,ras])
#        outband.FlushCache()
#    
#    outRaster = None
