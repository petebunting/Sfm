#!/home/ciaran/anaconda3/bin/python
# -*- coding: utf-8 -*-
"""
Created on Tue May 29 16:20:58 2018

@author: ciaran

This scripts calls the MicMac PIMs function in chunks for large datasets - gpu use is optional

Tends to overload 11gb GPU with around 30 images+

This uses pymicmac functionality to tile the datset into a grid then processes in sequence

Usage: 
    
pims_subset.py -folder $PWD -algo Forest -num 3,3 -zr 0.01 -g 1 

"""

from subprocess import call
from glob2 import glob
from os import path, mkdir, remove
from shutil import rmtree, move
from uav.tile import runtile


def runPIMs(fld, gOri, algo, numChunks, zregu, zoomF, mmgpu):

    DMatch = path.join(fld, 'DMatch')
    bFolder = path.join(fld, 'PIMsBatch')
    distMatch = path.join(fld, 'DistributedMatching.xml')
    
    binList = [DMatch, bFolder]
    
    for crap in binList:
        try:       
            rmtree(crap)
            
        except OSError:
            pass
    
    try:
        remove(distMatch)
    except OSError:
            pass
    
    mkdir(bFolder)

    runtile('Ori-'+gOri, 'JPG', 'DistributedMatching.xml', 'DMatch', numChunks)

    
    
    origList = [path.join(fld, 'PIMs-'+algo), 
                path.join(fld, 'PIMs-TmpBasc'),
                path.join(fld, 'PIMs-ORTHO'),
                path.join(fld, 'PIMs-TmpMnt'),
                path.join(fld, 'PIMs-TmpMntOrtho')]
    #
    txtList = glob(path.join(DMatch,'*.list'))
    
    
    # Some very ugly stuff going on in here
    for subList in txtList:
        flStr = open(subList).read()
        flStr.replace("\n", "|")
        sub = flStr.replace("\n", "|")
        print('the img subset is \n'+sub+'\n\n')                 
        mm3d = [mmgpu, "PIMs", algo,'"'+sub+'"', gOri, "DefCor=0",
                "SzW=1",
                "UseGpu=1", zoomF, zregu, 'SH=_mini']
        call(mm3d)
        pmsDir = path.join(fld,'PIMs-Forest')
        
        hd, tl = path.split(subList)
        subDir = path.join(bFolder, tl)
        mkdir(subDir)
        mnt = ['mm3d', 'PIMs2MNT', algo, 'DoOrtho=1', zregu]
        call(mnt)
      
        tawny = ['mm3d', 'Tawny', 'PIMs-ORTHO/', 'RadiomEgal=1', 'DegRap=4',
                 'Out=Orthophotomosaic.tif']
        call(tawny)
        
        # sooooo ugly I am getting very lazy
        newPIMs = path.join(subDir, 'PIMs-Forest')
        newBasc = path.join(subDir, 'PIMs-TmpBasc')
        newOrtho = path.join(subDir, 'PIMs-ORTHO')
        newTmpM = path.join(subDir, 'PIMs-TmpMnt')
        newTmpMO = path.join(subDir, 'PIMs-TmpMntOrtho')
        mvList = [newPIMs, newBasc, newOrtho, newTmpM, newTmpMO]
        toGo = list(zip(origList, mvList))
        [move(f[0], f[1]) for f in toGo] 
        print(mvList)
    
    

