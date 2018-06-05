#!/bin/bash



# GNSS delay
# Delay calculation
# QUESTION - why is the original text file being used when rejects etc have been binned
# Does this affect the later results??
mm3d OriConvert OriTxtInFile $1 Nav-adjusted-RTL ChSys=DegreeWGS84@SysCoRTL.xml MTD1=1 Delay=$2;

 
# Execute the delay correction between GPS and camera
mm3d CenterBascule ".*JPG" All-Rel Nav-adjusted-RTL All-RTL;

# CRITICAL THAT THE XML IS NAMED CORRECTLY!!!! AS BELOW!!!!!!!!!!!!!!!!!!

mm3d ChgSysCo  ".*JPG" All-RTL SysCoRTL.xml@$3 All-UTM;
 
 
# Ortho and dem production----------------------------------------------------------------------------
# The old way - not recommended  
# ALTHOUGH - inexplicably pims2mnt didn't work on large dataset so worth trying 
# if that fails
 
#mm3d Malt Ortho ".*JPG" All-UTM DirMEC=MEC;
# I don't fully understand the params - but the cmd takes a very long time with the defaults above
# mm3d Malt Ortho ".*JPG" All-UTM DirMEC=MEC EZA=1 DefCor=0 NbVI=2 AffineLast=1 Regul=0.005 HrOr=0 LrOr=0 ZoomF=1

# There is a bug with Tawny!!!!
#mm3d Tawny MEC; 

# RECOMMENDED
# Use the newer MicMac functions PIMs and Pims2MNT---------------------------------------------- 
# Check out the micmac site for mandatory and named args 

# There is a filepair arg FilePair=FileImagesNeighbour.xml
# I wonder if it is worth using
mm3d Pims MicMac ".*JPG" All-UTM DefCor=0 ZoomF=1 #FilePair=FileImagesNeighbour.xml;


mm3d Pims2Ply MicMac Out=Final.ply;

# Do this first to get a gapless ortho  
mm3d Pims2MNT MicMac DoOrtho=1 UseTA=1;

# Erm this throws an error claiming a lack of some file with DoMnt=0 annoyingly
# this is an attempt to fill gaps
#mm3d Pims2MNT MicMac DoOrtho=1 DoMnt=0 UseTA=1;

mm3d Tawny PIMs-ORTHO/ DEq=2 Out=Orthophotomosaic.tif;

# CorThr=0.7 (default correlation for tawny) 

# Now we do the DSM
#DEM (PIMs-Merged_Prof.tif) is produced in the  PIMS-Tmp-Basc folder 



# Tawny is a bit unreliable - when the image gets big - it seems to produce a
# header and subtiles (the header can't be opened in QGIS)
# The images are incorrectly placed if tile as the header doesn't work
# Suspect I need to look more at params
# https://micmac.ensg.eu/index.php/Tawny
mm3d Tawny PIMs-ORTHO/ DEq = 2 Out=Orthophotomosaic.tif;


# This seems to fail when it gets big....hence pims2ply before-hand
mm3d Nuage2Ply PIMs-TmpBasc/PIMs-Merged.xml Attr=PIMs-ORTHO/Orthophotomosaic.tif Out=pointcloud.ply

gdal_edit.py -a_srs EPSG:32630 PIMs-TmpBasc/PIMs-Merged_Prof.tif;

edit_raster.py -inRas PIMs-TmpBasc/PIMs-Merged_Prof.tif -edRas PIMs-ORTHO/Orthophotomosaic_Tile_0_0.tif -pixsize 0.02;



Cutting--room--floor-----------------------------------------------------------
#Project info for ortho - failed as it has no ref seemingly

#

#gdalsrsinfo -o wkt PIMs-TmpBasc/PIMs-Merged_Prof.tif > target.wkt;

#gdalwarp -t_srs target.wkt -to SRC_METHOD=NO_GEOTRANSFORM PIMs-ORTHO/Orthophotomosaic_Tile_0_0.tif OrthoFinal.tif

# RSGIS mosaicing-------------------------------------------------------------
# source activate pyrsgis
# Load of massive gaps - must change a param somewhere
# rsgislib_mosaic.py -i /home/ciaran/boats/PIMs-ORTHO -s *Ort**.tif -o RSGIS_mosaic.tif

# OSSIM - BASED MOSAICING ----------------------------------------------------------------------------
# Just here as an alternative for putting together tiles 
# Unfortunately have to reproject all the bloody images for OSSIM to understand ie espg4326
# So really there has to be a load of tidyup not currently present here
# gdalwarp -t_srs EPSG:32630 -s_srs EPSG:4326 *Ort**.tif
# Create some image histograms for ossim
#ossim-create-histo -i *Ort**.tif;

# Basic ortho with ossim is:
#ossim-orthoigen *Ort**.tif mosaic_plain.tif;

# Or more options
# Here am feathering edges and matching histogram to specific image - produced most pleasing result
# See https://trac.osgeo.org/ossim/wiki/orthoigen for really detailed cmd help
#ossim-orthoigen --combiner-type ossimFeatherMosaic --hist-match Ort_DSC00698.tif --srs ESPG:32630 *Ort**.tif mosaic.tif;
