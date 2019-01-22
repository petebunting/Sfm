#!/home/ciaran/anaconda3/bin/python

# Author Ciaran Robb
# Aberystwyth University

# -*- coding: utf-8 -*-
"""
Created on Tue May 29 16:20:58 2018

@author: ciaran

This scripts tiles large datsets for micmac and processes in parallel or sequnce depending 

This uses Malt which appears to be better for orthophoto generation

Gpu use is optional

Tends to overload 11gb GPU with around 30 images+

Usage: 
    

"""


from subprocess import call
from glob2 import glob
from os import path, mkdir, remove
from shutil import rmtree, move
from joblib import Parallel, delayed#, parallel_backend
from uav.tile import runtile


def runMalt(fld, gOri= "Ground_UTM", numChunks='3,3', mp=-1, bFolder='MaltBatch',
            algo="UrbanMNE", zreg='0.02', zoomF='ZoomF=2',
            mmgpu = 'mm3d', gP = '1'):
    

    def _prep(fld, numChunks, gOri='Ori-Ground_UTM'):
        DMatch = path.join(fld, 'DMatch')
        bFolder = path.join(fld, 'MaltBatch')
        distMatch = path.join(fld, 'DistributedMatching.xml')
        
        binList = [DMatch, bFolder]
        
        
        # Some funcs for use later tile one from pymicmac
        
        # folders to bin
        for crap in binList:
            try:       
                rmtree(crap)
                
            except OSError:
                pass
        # files to bin
        try:
            remove(distMatch)
        except OSError:
                pass
        
        mkdir(bFolder)
        txtList = glob(path.join(DMatch,'*.list'))
        nameList = [path.split(i)[1] for i in txtList]
        txtList.sort()
        nameList .sort()
    #list mania - I am crap at writing code
        finalList = list(zip(txtList, nameList))
        runtile('Ori-'+gOri, 'JPG', 'DistributedMatching.xml', 'DMatch', numChunks)   
        
        return finalList
    
    zregu = 'Regul='+zreg
    # run tiling
    

    
# May revert to another way but lets see.....
    def _proc_malt(subList, subName, bFolder):
        
        flStr = open(subList).read()
        flStr.replace("\n", "|")
        sub = flStr.replace("\n", "|")
        print('the img subset is \n'+sub+'\n\n')    
                
        mm3d = [mmgpu, "Malt", algo,'"'+sub+'"', gOri, "DefCor=0", "DoOrtho=1",
                "SzW=1", "DirMEC="+subName,
                "UseGpu="+gP, zoomF, zregu, "NbProc=1", "EZA=1"] #, 'SH=_mini']
        call(mm3d)
        tawny = ['mm3d', 'Tawny', "Ortho-"+subName+'/', 'RadiomEgal=1', 'DegRap=4',
                 'Out=Orthophotomosaic.tif']
        call(tawny)
        mDir = path.join(fld, subName)
        oDir = path.join(fld, "Ortho-"+subName) 
        hd, tl = path.split(subList)
        subDir = path.join(bFolder, tl)
        mkdir(subDir)
        move(mDir, subDir)
        move(oDir, subDir)




    

    
    finalList = _prep(fld, numChunks, gOri='Ori-Ground_UTM')
    
    Parallel(n_jobs=mp,verbose=5)(delayed(_proc_malt)(i[0], 
             i[1], bFolder) for i in finalList)    
    


    


