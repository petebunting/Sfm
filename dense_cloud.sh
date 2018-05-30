#!/bin/bash




# Lever arm calculation
mm3d OriConvert OriTxtInFile $1 Nav-adjusted-RTL ChSys=DegreeWGS84@SysCoRTL.xml MTD1=1 Delay=$2;


# Execute the lever arm adjustment
mm3d CenterBascule ".*JPG" All-Rel Nav-adjusted-RTL All-RTL;

# CRITICAL THAT THE XML IS NAMED CORRECTLY!!!! AS BELOW!!!!!!!!!!!!!!!!!!

mm3d ChgSysCo  ".*JPG" All-RTL SysCoRTL.xml@$3 All-UTM;


# Ortho and dem production----------------------------------------------------------------------------
# The old way - not recommended 
# ALTHOUGH - inexplicably pims2mnt didn't work on large dataset so worth trying 
# if that fails

#mm3d Malt Ortho ".*JPG" All-UTM DirMEC=MEC;
# I don't fully understand the params - but the cmd takes a very long time with the defaults above
# mm3d Malt Ortho ".*JPG" All-UTM DirMEC=MEC EZA=1 DefCor=0 AffineLast=1 Regul=0.005 HrOr=0 LrOr=0 ZoomF=1

# There is a bug with Tawny!!!!
#mm3d Tawny MEC;

# RECOMMENDED
# Use the newer MicMac functions PIMs and Pims2MNT---------------------------------------------- 
# Check out the micmac site for mandatory and named args

# There is a filepair arg FilePair=FileImagesNeighbour.xml
# I wonder if it is worth using
mm3d Pims MicMac ".*JPG" All-UTM DefCor=0 FilePair=FileImagesNeighbour.xml;



# DEM (PIMs-Merged_Prof.tif) is produced in the  PIMS-Tmp-Basc folder 
mm3d Pims2MNT MicMac DoOrtho=1;

# Tawny is a bit unreliable - when the image gets big - it seems to produce a
# header and subtiles (the header can't be opened in QGIS)
mm3d Tawny PIMs-ORTHO/ RadiomEgal=1 Out=Orthophotomosaic.tif;

# This seems to fail when it gets big....
#mm3d Nuage2Ply PIMs-TmpBasc/PIMs-Merged.xml Attr=PIMs-ORTHO/Orthophotomosaic.tif Out=pointcloud.ply

# Perhaps this'd be better
mm3d Pims2Ply MicMac Out=Final.ply