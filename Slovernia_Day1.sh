#!/bin/bash

# A script for creating a DEM and ortho from micmac
# The setting -1 means it will detect points at max resoltuiom - this is lengthy.
# Change to something like 2000 or lower tpo resize smaller and thus quicker 

 cd /media/ciaran/Storage1/Day1/1/PHOTOS;



# Creatw an image pair list based on gps coordinates
# The .csv file is a list of containing image name GNSS coords yaw pitch roll
# A func exists (data.py) to reformat the bramour data - for other platforms
# Not eesential but speeds up matching a lot - if not should read from exif
# if all data avalable

# IMPORTANT!!!! Best to take centre image - make the syscort based on the centre image coord
# TODO - automate this
mm3d OriConvert OriTxtInFile agilog_edited.csv Nav-Brut-RTL ChSys=DegreeWGS84@SysCoRTL.xml MTD1=1 NameCple=FileImagesNeighbour.xml CalcV=1 ImC=DSC00181.JPG NbImC=25;

# Tie point detection - BE WARNED! This is atfull resolutiom (-1) and will take a
# LONG time eg 24 HOURS with 1500 images - pymicmac FAR quicker

mm3d Tapioca File FileImagesNeighbour.xml $0;

# 1. Alternatively replace -1 with image resizing option eg 1000

# 2. Alternatively use mulscale to try at a reduced resolution, then only the images
# with no of tie points over a certain threshold are used on final tie point
# detection with full res imagery

# mm3d Tapioca MulScale File FileImagesNeighbour.xml lowressize hiressize NbMinPt nofofpoints
# mm3d Tapioca MulScale File FileImagesNeighbour.xml 1000 4000 NbMinPt 10

# Reduce the tie points with micmac Schnapps the output folder is 'mini' by default

mm3d Schnaps ".*JPG"; 

# Schnaps_poubelle.txt has the list of potentially dodgy 


# Compute orientations
# At full res peocessing is bloody geological. Radial-Basic is quicker and maybe
# sufficient  

# IMPORTANT Calib first - not sure whether this will play ball with schnaps
# # TODO - automate this - need 

mm3d Tapas RadialBasic  "DSC00181.JPG|DSC00182.JPG|DSC00180.JPG|DSC00183.JPG|DSC00179.JPG|DSC00140.JPG|DSC00141.JPG|DSC00219.JPG|DSC00218.JPG|DSC00220.JPG|DSC00139.JPG|DSC00142.JPG|DSC00217.JPG|DSC00184.JPG|DSC00178.JPG|DSC00221.JPG|DSC00143.JPG|DSC00138.JPG|DSC00216.JPG|DSC00177.JPG|DSC00185.JPG|DSC00102.JPG|DSC00222.JPG|DSC00101.JPG|DSC00103.JPG" Out=Sample4Calib-Rel;

# Hence the use of Schnapps and explicit Homol_mini 
mm3d Tapas Fraser ".*JPG" Out=All-Rel SH=_mini InCal=Sample4Calib-Rel;

# First Check
mm3d AperiCloud ".*JPG" All-Rel;

# Next calculate the movement during camera execution to edit the cloud in next command
# this is for lever arm compensation
# TODO - require automatic extraction of stdout figure

mm3d CenterBascule ".*JPG" All-Rel Nav-Brut-RTL tmp CalcV=1;

# Calculate the adjustment for the images based on the last figure returned above in
# cmd output
# Delay = ......

# Convert coords using delay obtained above
mm3d OriConvert OriTxtInFile agilog_edited.csv Nav-adjusted-RTL  MTD1=1 Delay=0.0174099;

# Execute the adjustment
mm3d CenterBascule ".*JPG" All-Rel Nav-adjusted-RTL All-RTL;

# CRITICAL THAT THE XML IS NAMED CORRECTLY!!!! AS BELOW!!!!!!!!!!!!!!!!!!

#mm3d ChgSysCo  ".*JPG" All-RTL SysCoRTL.xml@sysCoUTM33_EPSG32632.xml All-UTM


# Ortho and dem production----------------------------------------------------------------------------
# The old way - not recommended
# ALTHOUGH - inexplicably pims2mnt didn't work on large dataset so worth trying 
# if that fails

#mm3d Malt Ortho ".*JPG" All-UTM DirMEC=MEC;
# I don't fully understand the params - but the cmd takes a very long time with the defaults above
# mm3d Malt Ortho ".*JPG" All-UTM DirMEC=MEC DefCor=0 AffineLast=1 Regul=0.005 HrOr=0 LrOr=0 ZoomF=1

# There is a bug with Tawny!!!!
#mm3d Tawny MEC;

# RECOMMENDED
# Use the newer MicMac functions PIMs and Pims2MNT----------------------------------------------
# Check out the micmac site for mandatory and named args

mm3d Pims MicMac ".*JPG" All-UTM DefCor=0;

# DEM (PIMs-Merged_Prof.tif) is produced in the  PIMS-Tmp-Basc folder 
mm3d Pims2MNT MicMac DoOrtho=1;

# MICMAC - based mosaicing 
# RadiomEgal=1 means match the image hists or whatever

Tawny PIMs-ORTHO/ RadiomEgal=1 Out=Orthophotomosaic.tif;

# VODKA cmd get rid of vignetting TODO

#-----------------------------------------------------------------------------------------------------

# Create a dense coloured point cloud
mm3d Nuage2Ply PIMs-TmpBasc/PIMs-Merged.xml Attr=PIMs-ORTHO/Orthophotomosaic.tif Out=pointcloud.ply;

# OR
#mm3d C3DC MicMac ".*JPG" MEP-Terrain Out=C3DC_MicMac.ply

# OSSIM - BASED MOSAICING ----------------------------------------------------------------------------
# Just here as an alternative for putting together tiles 
# Create some image histograms for ossim
#ossim-create-histo -i *Ort**.tif;

# Basic ortho with ossim is:
#ossim-orthoigen *Ort**.tif mosaic.tif;

# Or more options
# Here am feathering edges and matching histogram to specific image - produced most pleasing result
# See https://trac.osgeo.org/ossim/wiki/orthoigen for really detailed cmd help
#ossim-orthoigen --combiner-type ossimFeatherMosaic --hist-match Ort_DSC00698.tif *Ort**.tif mosaic.tif;

# ----------------------------------------------------------------------------------------------------


