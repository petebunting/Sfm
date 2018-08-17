#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Mar 20 11:48:13 2018

@author: ciaranrobb

Edit and output a C-Astral 'corrected' array for use with MicMac 

The error GNSS is normally so miniscule that arguably it doesn't matter a huge amount
but for the sake of completness...

C-Astral are dependent on commercial software for the above which is annoying,
plus there own program only works in Windows (lame)

This is a bit of kludge at the moment to be refined...
"""

import numpy as np
import pandas as pd
import os
from glob2 import glob

from tqdm import tqdm

import piexif
import glob2
from os import path

from PIL import Image
from joblib import Parallel, delayed

import xml.etree.ElementTree as ET

from shutil import copy



def convert_c3p(folder, lognm):
    
    """
    Edit csv file for c3p to work with MicMac.
    
    This assumes the column order is name, x, y, z, yaw, pitch, roll
    
    Parameters
    ----------  
    
    folder : string
            path to folder containing jpegs
    lognm : string
            path to c3p derived csv file
                           
    """
    # Get a list of file paths 
    fileList = glob2.glob(os.path.join(folder, '*.JPG'))
    
    #split them so it is just the jpg (ugly yes)
    # these will constitute the first column of the output csv
    files = [os.path.split(file)[1] for file in fileList]
    files.sort()

    # must be read as an object as we are dealing with strings and numbers
    #npCsv = np.loadtxt(lognm, dtype='object')
    
    # pd read in with ; sep
    pdcsv=pd.read_csv(lognm, sep=';')
    
    newCsv = pd.concat([pdcsv['Longitude'], pdcsv['Latitude'],
                       pdcsv['Altitude'], pdcsv['Yaw'],
                       pdcsv['Pitch'], pdcsv['Roll']], axis=1)
    

    #del pdcsv
    # get rid of the first columns consisting number 1
    #npCsv = pdcsv[:,1:len(pdcsv)]

    newCsv.insert(loc=0, column="#F=N", value=files)
  
    
    # header for MicMac     
    hdr = ["#F=N", "X", "Y", "Z", "K", "W", "P"]
           
    # insert new header
    newCsv.columns = [hdr]       
    
    edNm = lognm[:-4]+'_edited.csv'
    
    newCsv.to_csv(edNm, sep=' ', index=False, header=hdr)       
       
def remove_prefix(folder, prefix):
    
    """
    Remove pointless file prefix on C3p jpgs. 
    
    Parameters
    ----------  
    
    folder : string
             path to folder containing jpgs
             
    prefix : string
             prefix to remove from jpg files
                           
    """
    
    fileList = glob(os.path.join(folder,'*.JPG'))
    
    for file in tqdm(fileList):
        new = file.replace(prefix, '', 1)
        os.rename(file, new)
        



def focalen_exif(folder):
    
    """
    Add focal info to exif for MicMac.
    MicMac also has a tool for this - just in case it doesnt work
    
    Parameters
    ----------  
    
    folder : string
             path to folder containing jpgs
             
                           
    """
    
    fileList = glob2.glob(path.join(folder, '*.JPG'))
    
    def _ed_ppx_exif(fle):
        
        img = Image.open(fle)
        
       # w, h = img.size
        
        exif_dict = piexif.load(img.info['exif'])
    #    
    #    exif_dict['Exif'][piexif.ImageIFD.XResolution] = (w, 1)
    #    exif_dict['Exif'][piexif.ImageIFD.YResolution] = (h, 1)
        
        # multiply by 1.5 to get 35mm equiv apparently (based on googling)
        exif_dict['Exif'][piexif.ExifIFD.FocalLength]=(16, 30)
        
        
        exif_dict['Exif'][piexif.ExifIFD.FocalLengthIn35mmFilm]=(24,45)
        # if it was 30 as matej said
    #    exif_dict['Exif'][piexif.ExifIFD.FocalLengthIn35mmFilm]=(24,45)
        
    #    exif_dict["1st"][piexif.ImageIFD.XResolution] = (w, 1)
    #    exif_dict["1st"][piexif.ImageIFD.YResolution] = (h, 1)
    #
    #    exif_dict["1st"][piexif.ExifIFD.FocalLength]=(50, 5)
    #    
    #    exif_dict["1st"][piexif.ExifIFD.FocalLengthIn35mmFilm]=(75,10)
        
        exif_bytes = piexif.dump(exif_dict)
        
        piexif.insert(exif_bytes, fle)

    Parallel(n_jobs=-1,verbose=5)(delayed(_ed_ppx_exif)(file) for file in fileList)
    
    
    
def mirror_pairs(fle):
    
    """
    Micmac returns an error when image pairs are only in one direction. 
    To avoid this, this func reverses the pair index and appends to pair file
    
    Parameters
    ----------  
    
    fle : string
             path to xml pairs file
    """


    tree = ET.parse(fle)  
    root = tree.getroot()

    # 
    tree2 = ET.ElementTree()
    
        
    # Bloody hell this is such a shit module.
    # Create an element, then write a new root even though there aint one
    new = ET.Element('SauvegardeNamedRel')
    tree2._setroot(new)
    # finally the var needed
    newRoot = tree2.getroot()
    
    for elem in tqdm(root):
        entry = elem.text
        entlist = entry.split()
        entlist.reverse()
        newent = ' '.join(entlist)
        cple = ET.Element("Cple")
        cple.text = newent
        newRoot.append(elem)
        newRoot.append(cple)
    
    
    
    
    newFle = fle[:-4]+'edited.xml'
    tree2.write(newFle)
    
    
def mirror_pairs_subset(fle, newFle, maxInd=10):
    
    """

    Micmac returns an error when image pairs are only in one direction. 
    To avoid this, this func reverses the pair index and appends to pair file
    
    Parameters
    ----------  
    
    fle : string
             path to xml pairs file
    """
    tree = ET.parse(fle)  
    root = tree.getroot()

    # 
    tree2 = ET.ElementTree()
    
        
    # Bloody hell this is such a shit module.
    # Create an element, then write a new root even though there aint one
    new = ET.Element('SauvegardeNamedRel')
    tree2._setroot(new)
    # finally the var needed
    newRoot = tree2.getroot()
    
    for index, elem in tqdm(enumerate(root)):
        entry = elem.text
        entlist = entry.split()
        entlist.reverse()
        newent = ' '.join(entlist)
        cple = ET.Element("Cple")
        cple.text = newent
        newRoot.append(elem)
        newRoot.append(cple)
        if index > maxInd:
            break
    
    tree.write(newFle)

def mv_subset(csv, inFolder, outfolder):
    
    os.chdir(inFolder)
    
    dF = pd.read_table(csv)
    
    dfList = list(dF['#F=N'])
    
    Parallel(n_jobs=-1,verbose=5)(delayed(copy)(file, 
            outfolder) for file in dfList)
        
    
    

        