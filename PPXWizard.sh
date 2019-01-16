# This is a generic workflow for drone imagery using the malt pipeline

# Author Ciaran Robb
# Aberystwyth University

# example:
# ./Drone.sh -u "30 +north"

 
#create UTM file (after deleting any existing one)

rm SysUTM.xml
echo "<SystemeCoord>                                                                                              " >> SysUTM.xml
echo "         <BSC>                                                                                              " >> SysUTM.xml
echo "            <TypeCoord>  eTC_Proj4 </TypeCoord>                                                             " >> SysUTM.xml
echo "            <AuxR>       1        </AuxR>                                                                   " >> SysUTM.xml
echo "            <AuxR>       1        </AuxR>                                                                   " >> SysUTM.xml
echo "            <AuxR>       1        </AuxR>                                                                   " >> SysUTM.xml
echo "            <AuxStr>  +proj=utm +zone="$UTM "+ellps=WGS84 +datum=WGS84 +units=m +no_defs   </AuxStr>        " >> SysUTM.xml
echo "                                                                                                            " >> SysUTM.xml
echo "         </BSC>                                                                                             " >> SysUTM.xml
echo "</SystemeCoord>                                                                                             " >> SysUTM.xml
  
echo "the parameters for Bramor PPX are F35=45 F=30 Cam=ILCE-6000"  
mm3d vSetExif; 


mm3d XifGps2Txt .*JPG
#Get the GNSS data out of the images and convert it to a xml orientation folder (Ori-RAWGNSS), also create a good RTL (Local Radial Tangential) system.

mm3d XifGps2Xml .*JPG RAWGNSS

mm3d OriConvert "#F=N X Y Z" GpsCoordinatesFromExif.txt RAWGNSS_N ChSys=DegreeWGS84@RTLFromExif.xml MTD1=1 NameCple=FileImagesNeighbour.xml CalcV=1


mm3d vTapioca; 


mm3d vSchnaps; 

#Compute Relative orientation (Arbitrary system)
mm3d vTapas FraserBasic; 

#Transform to  RTL system
mm3d vCenterBascule; 


#Visualize Ground_RTL orientation
mm3d vAperiCloud .*$EXTENSION Ori-Ground_RTL SH=_mini;

#Change system to final cartographic system  

mm3d vCampari 
#Correlation into DEM 
 
#if [ "$gpu" != none ]; then 
    #	/home/ciaran/MicMacGPU/micmac/bin/mm3d Malt UrbanMNE ".*.$EXTENSION" Ground_UTM UseGpu=1 EZA=1 DoOrtho=1 SzW=$win ZoomF=$ZoomF NbProc=$proc
#else
mm3d vMalt UrbanMNE 

mm3d vTawny 



#Making OUTPUT folder

#PointCloud from Ortho+DEM, with offset substracted to the coordinates to solve the 32bit precision issue
mm3d vNuage2Ply #MEC-Malt/NuageImProf_STD-MALT_Etape_8.xml Attr=Ortho-MEC-Malt/Orthophotomosaic.tif Out=OUTPUT/PointCloud_OffsetUTM.ply Offs=[$X_OFF,$Y_OFF,0]
 
#cd MEC-Malt
#finalDEMs=($(ls Z_Num*_DeZoom*_STD-MALT.tif))
#finalcors=($(ls Correl_STD-MALT_Num*.tif))
#DEMind=$((${#finalDEMs[@]}-1))
#corind=$((${#finalcors[@]}-1))
#lastDEM=${finalDEMs[DEMind]}
#lastcor=${finalcors[corind]}
#laststr="${lastDEM%.*}"
#corrstr="${lastcor%.*}"
#cp $laststr.tfw $corrstr.tfw
#cd ..

mm3d vConvertIm Ortho-MEC-Malt/Orthophotomosaic.tif Out=OrthFinal.tif

#gdal_translate -a_srs "+proj=utm +zone=$UTM +ellps=WGS84 +datum=WGS84 +units=m +no_defs" Ortho-MEC-Malt/OrthFinal.tif OUTPUT/OrthoImage_geotif.tif
#gdal_translate -a_srs "+proj=utm +zone=$UTM +ellps=WGS84 +datum=WGS84 +units=m +no_defs" MEC-Malt/$lastDEM OUTPUT/DEM_geotif.tif
#gdal_translate -a_srs "+proj=utm +zone=$UTM +ellps=WGS84 +datum=WGS84 +units=m +no_defs" MEC-Malt/$lastcor OUTPUT/CORR.tif
