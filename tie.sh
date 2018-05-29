#!/bin/bash


mm3d OriConvert OriTxtInFile $1 Nav-Brut-RTL ChSys=DegreeWGS84@SysCoRTL.xml MTD1=1  NameCple=FileImagesNeighbour.xml CalcV=1;

# Here we use the defaults which are RadialBasic


# TODO 
# Automate selecting a calibration subset

# NameCple=FileImagesNeighbour.xml CalcV=1 ImC=DSC00264.JPG NbImC=10 

mm3d Tapioca File FileImagesNeighbour.xml $2;

mm3d Schnaps ".*JPG";

calib_subset.py -csv $1; 

mm3d Tapas RadialBasic ".*JPG" Out=All-Rel SH=_mini InCal=Sample4Calib-Rel

mm3d AperiCloud ".*JPG" All-Rel;

meshlab AperiCloud_All-Rel.ply

# Next calculate the movement during camera execution to edit the cloud in next command
# this is for lever arm compensation
# TODO - require automatic extraction of stdout figure

mm3d CenterBascule ".*JPG" All-Rel Nav-Brut-RTL tmp CalcV=1
