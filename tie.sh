#!/bin/bash


mm3d OriConvert OriTxtInFile $1 Nav-Brut-RTL ChSys=DegreeWGS84@SysCoRTL.xml MTD1=1  NameCple=FileImagesNeighbour.xml CalcV=1;

# Here we use the defaults which are RadialBasic

 
# TODO 
# Automate selecting a calibration subset

# NameCple=FileImagesNeighbour.xml CalcV=1 ImC=DSC00709.JPG NbImC=10 

mm3d Tapioca File FileImagesNeighbour.xml $2;

mm3d Schnaps ".*JPG" VeryStrict=1 MoveBadImgs=1;

# This should work now, but not sure whether the incal will work with tapas
# Frequently the calib doesn't work so sod that
#calib_subset.py -folder $PWD; 

mm3d Tapas $3 ".*JPG" Out=All-Rel SH=_mini #InCal=Sample4Calib-Rel

# TODO get rid vignette
#mm3d Vodka ".*JPG"

mm3d AperiCloud ".*JPG" All-Rel;

#meshlab AperiCloud_All-Rel.ply

# Next calculate the movement during camera execution to edit the cloud in next command
# this is for lever arm compensation
# TODO - require automatic extraction of stdout figure

mm3d CenterBascule ".*JPG" All-Rel Nav-Brut-RTL tmp CalcV=1
