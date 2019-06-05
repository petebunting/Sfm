#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Jun  5 12:56:23 2019

@author: ciaran robb

Make a DTM with pdal - this is limited to a pdal pipeline at present hence script

Usage 

dtm_gen.py -pcl grndgrnd.las -res 0.5 -dtm DTMlatest.tif

"""
import argparse
import subprocess
import json
import os

parser = argparse.ArgumentParser()

parser.add_argument("-pcl", "--pcloud", type=str, required=True, 
                    help="input point cloud")

parser.add_argument("-res", "--rez", type=str, required=False, 
                    help="resolution of DTM")


parser.add_argument("-dtm", "--outRas", type=str, required=False, 
                    help="Output dtm")



args = parser.parse_args() 

inCloud  = args.pcloud

outDTM =args.outRas

resol = args.rez

hd, tl = os.path.split(inCloud)

# This is pish - they need to change the input mechanism

cmdTogo = {
    "pipeline": [
        inCloud,
        {
            "filename": outDTM,
            "gdaldriver":"GTiff",
            "output_type":"all",
            "resolution": resol,
            "type": "writers.gdal"
        }
    ]
}

ootJson = os.path.join(hd, 'dtmcmd.json')

with open(ootJson, 'w') as outfile:  
    json.dump(cmdTogo, outfile)
    
#"source", "activate", "pdal", ";",

pdalCmd = ["pdal", "pipeline", ootJson]

subprocess.run(pdalCmd)







