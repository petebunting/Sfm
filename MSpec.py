#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Mar 12 15:35:40 2019

@author: Ciaran Robb

https://github.com/Ciaran1981/Sfm


A script for processing to surface reflectance and aligning bands on Micasense
Rededge

Based on the material on the micasense lib git site, though this uses the 
micasense lib with multiprocessing disabled as multiprocessing is ised in this
scirpt via joblib. 

"""
import os#, sys
import matplotlib.pyplot as plt
#from PIL import Image
#import micasense.metadata as metadata
#import micasense.utils as msutils
#import micasense.plotutils as plotutils
import micasense.imageutils as imageutils
import micasense.capture as capture
#from micasense.panel import Panel
#from micasense.image import Image as MImage
import numpy as np
import micasense.imageset as imageset
from glob2 import glob
import imageio
import argparse
from scipy.misc import bytescale
import cv2
#from tqdm import tqdm
from subprocess import call
from joblib import Parallel, delayed
from osgeo import gdal, gdal_array


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

parser.add_argument("-alIm", "--alg", type=str, required=True, 
                    help="alignment image")

parser.add_argument("-refBnd", "--rB", type=int, required=False, default=1, 
                    help="band to which others are aligned")

parser.add_argument("-mx", "--mxiter", type=int, required=False, default=100, 
                    help="max iterations in alignment of bands")

parser.add_argument("-nt", "--noT", type=int, required=False, default=-1,
                    help="no of tiles at a time")

parser.add_argument("-stk", "--stack", type=bool, required=False, default=False,
                    help="no of tiles at a time")


args = parser.parse_args() 

calibPre = os.path.abspath(args.pcal)

if args.pstcal != None:
    calibPost = os.path.abspath(args.pstcal)


imagesFolder = os.path.abspath(args.fimages)


reflFolder = os.path.abspath(args.rimages)

#nt = args.noT


print("Aligning images, may take a while...")
# Increase max_iterations to 1000+ for better results, but much longer runtimes
'''
Right so each capture means each set of bands 1-5
This requires the image list to be sorted in a way that can be aligned
It appears as though micasense have done this with their lib

The git site author claims the warp can be applied to whole image set after choosing a decent calib image
I doubt this based on results!!! Just using using unwarped images results in non-aligned images

'''



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
 
wildCrd = "IMG_"+args.alg+"*.tif"
algList = glob(os.path.join('000', wildCrd))
#algList.sort()
imAl = capture.Capture.from_filelist(algList) 
imAl.compute_reflectance(panel_irradiance)
#imAl.plot_undistorted_reflectance(panel_irradiance)


rf = args.rB

# func to align and display the result. 
def align_template(imAl, mx, reflFolder, ref_ind=rf):

    
    warp_matrices, alignment_pairs = imageutils.align_capture(imAl,
                                                              ref_index=ref_ind, 
                                                              warp_mode=cv2.MOTION_HOMOGRAPHY,
                                                              max_iterations=mx)
    for x,mat in enumerate(warp_matrices):
        print("Band {}:\n{}".format(x,mat))

    # cropped_dimensions is of the form:
    # (first column with overlapping pixels present in all images, 
    #  first row with overlapping pixels present in all images, 
    #  number of columns with overlapping pixels in all images, 
    #  number of rows with overlapping pixels in all images   )
    dist_coeffs = []
    cam_mats = []
# create lists of the distortion coefficients and camera matricies
    for i,img in enumerate(imAl.images):
        dist_coeffs.append(img.cv2_distortion_coeff())
        cam_mats.append(img.cv2_camera_matrix())
        
    warp_mode = cv2.MOTION_HOMOGRAPHY #alignment_pairs[0]['warp_mode']
    match_index = alignment_pairs[0]['ref_index']
    
    cropped_dimensions, edges = imageutils.find_crop_bounds(imAl, 
                                                            warp_matrices,
                                                            warp_mode=cv2.MOTION_HOMOGRAPHY)
   # capture, warp_matrices, cv2.MOTION_HOMOGRAPHY, cropped_dimensions, None, img_type="reflectance",
    im_aligned = imageutils.aligned_capture(imAl, warp_matrices, warp_mode,
                                            cropped_dimensions, match_index,
                                            img_type="reflectance")
    
    im_display = np.zeros((im_aligned.shape[0],im_aligned.shape[1],5), dtype=np.float32 )
    
    for iM in range(0,im_aligned.shape[2]):
        im_display[:,:,iM] =  imageutils.normalize(im_aligned[:,:,iM])
        
    rgb = im_display[:,:,[2,1,0]] 
    cir = im_display[:,:,[3,2,1]] 
    grRE = im_display[:,:,[4,2,1]] 
#    fig, axes = plt.subplots(1, 3, figsize=(16,16)) 
#    plt.title("Red-Green-Blue Composite") 
#    axes[0].imshow(rgb) 
#    plt.title("Color Infrared (CIR) Composite") 
#    axes[1].imshow(cir) 
#    plt.title("Red edge-Green-Red (ReGR) Composite") 
#    axes[2].imshow(grRE) 
#    plt.show()
    
    prevList = [rgb, cir, grRE]
    nmList = ['rgb.jpg', 'cir.jpg', 'grRE.jpg']
    names = [os.path.join(reflFolder, pv) for pv in nmList]
    
    for ind, p in enumerate(prevList):
        img8 = bytescale(p)
        imageio.imwrite(names[ind], img8)
    
    return warp_matrices, alignment_pairs#, dist_coeffs, cam_mats, cropped_dimensions

warp_matrices, alignment_pairs = align_template(imAl, args.mxiter,reflFolder,
                                                ref_ind=rf)

    
# prep work dir

bndNames = ['Blue', 'Green', 'Red', 'NIR', 'Red edge']

bndFolders = [os.path.join(reflFolder, b) for b in bndNames]

[os.mkdir(bf) for bf in bndFolders]

# Main func to  write bands to their respective directory

def proc_imgs(i, warp_matrices, bndFolders, panel_irradiance):#, reflFolder):

#    for i in imgset.captures: 
    
    i.compute_reflectance(panel_irradiance) 
    #i.plot_undistorted_reflectance(panel_irradiance)  


    cropped_dimensions, edges = imageutils.find_crop_bounds(i, warp_matrices)
    
    im_aligned = imageutils.aligned_capture(i, warp_matrices,
                                            cv2.MOTION_HOMOGRAPHY,
                                            cropped_dimensions,
                                            None, img_type="reflectance")
    
    im_display = np.zeros((im_aligned.shape[0],im_aligned.shape[1],5), dtype=np.float32 )
    
    for iM in range(0,im_aligned.shape[2]):
        im_display[:,:,iM] =  imageutils.normalize(im_aligned[:,:,iM])
    
    for k in range(0,im_display.shape[2]):
         im = i.images[k]
         hd, nm = os.path.split(im.path)
         
         img8 = bytescale(im_display[:,:,k])
         
         outfile = os.path.join(bndFolders[k], nm)
         imageio.imwrite(outfile, img8)
        
         cmd = ["exiftool", "-tagsFromFile", im.path,  "-file:all", "-iptc:all",
               "-exif:all",  "-xmp", "-Composite:all", outfile, 
               "-overwrite_original"]
         call(cmd)
# for ref
#[proc_imgs(imCap, warp_matrices, reflFolder) for imCap in imgset]
def proc_stack(i, warp_matrices, panel_irradiance):
    
    i.compute_reflectance(panel_irradiance) 
        #i.plot_undistorted_reflectance(panel_irradiance)  
    
    
    cropped_dimensions, edges = imageutils.find_crop_bounds(i, warp_matrices)
    
    im_aligned = imageutils.aligned_capture(i, warp_matrices,
                                            cv2.MOTION_HOMOGRAPHY,
                                            cropped_dimensions,
                                            None, img_type="reflectance")
    
    im_display = np.zeros((im_aligned.shape[0],im_aligned.shape[1],5), 
                          dtype=np.float32)
    
    rows, cols, bands = im_display.shape
    driver = gdal.GetDriverByName('GTiff')
    
    im = i.images[1]
    hd, nm = os.path.split(im.path[:-4])

    filename = "bgrne" #blue,green,red,nir,redEdge
    #
    
    outRaster = driver.Create(filename+".tiff", cols, rows, 5, gdal.GDT_UInt16)
    normalize = False
    
    # Output a 'stack' in the same band order as RedEdge/Alutm
    # Blue,Green,Red,NIR,RedEdge[,Thermal]
    
    # NOTE: NIR and RedEdge are not in wavelength order!
    
    i.compute_reflectance(panel_irradiance+[0])
    
    for i in range(0,5):
        outband = outRaster.GetRasterBand(i+1)
        if normalize:
            outband.WriteArray(imageutils.normalize(im_aligned[:,:,i])*65535)
        else:
            outdata = im_aligned[:,:,i]
            outdata[outdata<0] = 0
            outdata[outdata>1] = 1
            outband.WriteArray(outdata*65535)
        outband.FlushCache()
    
    if im_aligned.shape[2] == 6:
        outband = outRaster.GetRasterBand(6)
        outdata = im_aligned[:,:,5] * 100 # scale to centi-C to fit into uint16
        outdata[outdata<0] = 0
        outdata[outdata>65535] = 65535
        outband.WriteArray(outdata)
        outband.FlushCache()
    outRaster = None         

def decdeg2dms(dd):
   is_positive = dd >= 0
   dd = abs(dd)
   minutes,seconds = divmod(dd*3600,60)
   degrees,minutes = divmod(minutes,60)
   degrees = degrees if is_positive else -degrees
   return (degrees,minutes,seconds)

def write_log(capture, outputPath):
    header = "SourceFile,\
    GPSDateStamp,GPSTimeStamp,\
    GPSLatitude,GpsLatitudeRef,\
    GPSLongitude,GPSLongitudeRef,\
    GPSAltitude,GPSAltitudeRef,\
    FocalLength,\
    XResolution,YResolution,ResolutionUnits\n"
    
    lines = [header]
    for capture in imgset.captures:
        #get lat,lon,alt,time
        outputFilename = capture.uuid+'.tif'
        fullOutputPath = os.path.join(outputPath, outputFilename)
        lat,lon,alt = capture.location()
        #write to csv in format:
        # IMG_0199_1.tif,"33 deg 32' 9.73"" N","111 deg 51' 1.41"" W",526 m Above Sea Level
        latdeg, latmin, latsec = decdeg2dms(lat)
        londeg, lonmin, lonsec = decdeg2dms(lon)
        latdir = 'North'
        if latdeg < 0:
            latdeg = -latdeg
            latdir = 'South'
        londir = 'East'
        if londeg < 0:
            londeg = -londeg
            londir = 'West'
        resolution = capture.images[0].focal_plane_resolution_px_per_mm
    
        linestr = '"{}",'.format(fullOutputPath)
        linestr += capture.utc_time().strftime("%Y:%m:%d,%H:%M:%S,")
        linestr += '"{:d} deg {:d}\' {:.2f}"" {}",{},'.format(int(latdeg),int(latmin),latsec,latdir[0],latdir)
        linestr += '"{:d} deg {:d}\' {:.2f}"" {}",{},{:.1f} m Above Sea Level,Above Sea Level,'.format(int(londeg),int(lonmin),lonsec,londir[0],londir,alt)
        linestr += '{}'.format(capture.images[0].focal_length)
        linestr += '{},{},mm'.format(resolution,resolution)
        linestr += '\n' # when writing in text mode, the write command will convert to os.linesep
        lines.append(linestr)

    fullCsvPath = os.path.join(outputPath,'log.csv')
    with open(fullCsvPath, 'w') as csvfile: #create CSV
        csvfile.writelines(lines)
    return fullCsvPath
        

         
if args.stack == True:
    
    Parallel(n_jobs=args.noT, verbose=2)(delayed(proc_imgs)(imCap, 
             warp_matrices, bndFolders, 
             panel_irradiance) for imCap in imgset.captures)
    
    write_log(capture, reflFolder)

else:
    Parallel(n_jobs=args.noT, verbose=2)(delayed(proc_stack)(imCap, 
             warp_matrices, panel_irradiance) for imCap in imgset.captures)
    

    