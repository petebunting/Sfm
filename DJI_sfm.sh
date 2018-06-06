#!/bin/bash


#Get the GNSS data out of the images and convert it to a txt file (GpsCoordinatesFromExif.txt)
mm3d XifGps2Txt ".*JPG";
#Get the GNSS data out of the images and convert it to a xml orientation folder (Ori-RAWGNSS), also create a good RTL (Local Radial Tangiential) system.
mm3d XifGps2Xml ".*JPG" RAWGNSS;
#Use the GpsCoordinatesFromExif.txt file to create a xml orientation folder (Ori-RAWGNSS_N), and a file (FileImagesNeighbour.xml) detailing what image sees what other image (if camera is <50m away)
mm3d OriConvert "#F=N X Y Z" GpsCoordinatesFromExif.txt RAWGNSS_N ChSys=DegreeWGS84@RTLFromExif.xml MTD1=1 NameCple=FileImagesNeighbour.xml; #DN=50
#Find Tie points
mm3d Tapioca File FileImagesNeighbour.xml $0; 

# weed out the crap  
mm3d Schnaps ".*JPG" VeryStrict=1 MoveBadImgs=1;
#Compute Relative orientation (Arbitrary system)

mm3d Tapas Fraser ".*JPG" Out=Arbitrary SH=_mini;
#Visualize relative orientation  
mm3d AperiCloud ".*JPG" Ori-Arbitrary;
#Transform to  RTL system
mm3d CenterBascule ".*JPG" Arbitrary RAWGNSS_N Ground_Init_RTL;
#Bundle adjust using both camera positions and tie points (number in EmGPS option is the quality estimate of the GNSS data in meters)
mm3d Campari ".*JPG" Ground_Init_RTL Ground_RTL EmGPS=[RAWGNSS_N,5];

#Change system to final cartographic system 
mm3d ChgSysCo  ".*JPG" Ground_RTL RTLFromExif.xml@sysCoUTM30_EPSG32630.xml Ground_UTM;
#Correlation into DEM with only Nadir images (hence weird pattern, to be adapted for other datasets, "".*JPG"" if all images)
 

mm3d Pims MicMac ".*JPG" Ground_UTM DefCor=0 FilePair=FileImagesNeighbour.xml;

#mm3d Pims2Ply MicMac Out=Final.ply;  

# DEM (PIMs-Merged_Prof.tif) is produced in the  PIMS-Tmp-Basc folder 
mm3d Pims2MNT MicMac DoOrtho=1;

mm3d Tawny PIMs-ORTHO/ Out=Orthophotomosaic.tif; 

# OR?
mm3d Nuage2Ply PIMs-TmpBasc/PIMs-Merged.xml Attr=PIMs-ORTHO/Orthophotomosaic.tif Out=pointcloud.ply;

# OSSIM - BASED MOSAICING ----------------------------------------------------------------------------
# Just here as an alternative for putting together tiles 
# gdalwarp -t_srs EPSG:32617 -s_srs EPSG:4326 *Ort**.tif
# Create some image histograms for ossim
#ossim-create-histo -i *Ort**.tif;

# Unfortunately have to reproject all the bloody images for OSSIM to understand ie espg4326
# Basic ortho with ossim is:
#ossim-orthoigen *Ort**.tif mosaic_plain.tif;

# Or more options
# Here am feathering edges and matching histogram to specific image - produced most pleasing result
# See https://trac.osgeo.org/ossim/wiki/orthoigen for really detailed cmd help
#ossim-orthoigen --combiner-type ossimFeatherMosaic --hist-match Ort_DSC00698.tif *Ort**.tif mosaic.tif;