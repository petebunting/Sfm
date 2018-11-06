# This is a generic workflow for DJI type platforms etc with embedded GNSS data
# Modified from the original L.Girod script

# example:
# ./Drone.sh -e JPG -u "30 +north" -g 1 -w 2 -prc 20



# add default values 
EXTENSION=JPG
X_OFF=0;
Y_OFF=0;
utm_set=false
do_ply=true
do_AperiCloud=true
size=2000
resol_set=false
ZoomF=2 
DEQ=1
obliqueFolder=none
gpu=0
proc=16 
win=2

 
while getopts "e:x:y:u:sz:r:z:eq:g:w:proc:csv:h" opt; do  
  case $opt in
    h)
      echo "Run the workflow for drone acquisition at nadir (and pseudo nadir) angles)."
      echo "usage: Drone.sh -e JPG -x 55000 -y 6600000 -u \"32 +north\" -p true -r 0.05"
      echo "	-e EXTENSION     : image file type (JPG, jpg, TIF, png..., default=JPG)."
      echo "	-x X_OFF         : X (easting) offset for ply file overflow issue (default=0)."
      echo "	-y Y_OFF         : Y (northing) offset for ply file overflow issue (default=0)."
      echo "	-u UTMZONE       : UTM Zone of area of interest. Takes form 'NN +north(south)'"
      echo "	-sz size         : resize of imagery eg - 2000"
      echo "	-r RESOL         : Ground resolution (in meters)"
      echo "	-z ZoomF         : Last step in pyramidal dense correlation (default=2, can be in [8,4,2,1])"
      echo "	-eq DEQ          : Degree of equalisation between images during mosaicing (See mm3d Tawny)"
      echo " -g gpu           : Whether to use GPU support, default 1 (true!)"
      echo " -w win           : Correl window size"
      echo " -prc proc        : no of CPU thread used (needed even when using GPU)"
      echo " -csv -CSV        : whether to use a separate csv "
      echo "	-h	             : displays this message and exits."
      echo " " 
      exit 0
      ;;    
	e)
      EXTENSION=$OPTARG
      ;;
	u)
      UTM=$OPTARG
      utm_set=true
      ;;
 	sz)
      size=$OPTARG
      ;;        
	r) 
      RESOL=$OPTARG
      resol_set=true
      ;;  
	x)
      X_OFF=$OPTARG
      ;;	
	y)
      Y_OFF=$OPTARG
      ;;	
	z)
      ZoomF=$OPTARG
      ;;
	eq)
      DEQ=$OPTARG  
      ;;
	g)
      gpu=$OPTARG
      ;;
	w)
      win=$OPTARG
      ;;
	prc)
      proc=$OPTARG  
      ;; 
    csv)
      CSV=$OPTARG 
      ;;         
    \?)
      echo "DroneNadir.sh: Invalid option: -$OPTARG" >&1
      exit 1
      ;;
    :)
      echo "DroneNadir.sh: Option -$OPTARG requires an argument." >&1
      exit 1
      ;;
  esac
done
if [ "$utm_set" = false ]; then
	echo "UTM zone not set"
	exit 1
fi


if [ "$gpu" = 0 ]; then
	echo "Using CPU only"
	echo "$proc CPU threads to be used during dense matching"
fi
if [ "$gpu" = 1 ]; then
    echo "$proc CPU threads to be used during dense matching"
	echo "Using GPU support" 
fi 

#mm3d SetExif ."*JPG" F35=45 F=30 Cam=ILCE-6000  
# magick convert .*$EXTENSION -resize 50% .*$EXTENSION 

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
  

#mm3d SetExif ."*JPG" F35=45 F=30 Cam=ILCE-6000  
# magick convert .*$EXTENSION -resize 50% .*$EXTENSION 
#Get the GNSS data out of the images and convert it to a txt file (GpsCoordinatesFromExif.txt)
if [ "$CSV" != none ]; then 
    echo "using csv file" 
    cs=*.csv   
    mm3d OriConvert OriTxtInFile $cs RAWGNSS_N ChSys=DegreeWGS84@SysUTM.xml MTD1=1  NameCple=FileImagesNeighbour.xml CalcV=1
else
    echo "using exif data"
    mm3d XifGps2Txt .*$EXTENSION
    #Get the GNSS data out of the images and convert it to a xml orientation folder (Ori-RAWGNSS), also create a good RTL (Local Radial Tangential) system.
    mm3d XifGps2Xml .*$EXTENSION RAWGNSS
    mm3d OriConvert "#F=N X Y Z" GpsCoordinatesFromExif.txt RAWGNSS_N ChSys=DegreeWGS84@RTLFromExif.xml MTD1=1 NameCple=FileImagesNeighbour.xml CalcV=1
fi  
 

#Find Tie points using 1/2 resolution image (best value for RGB bayer sensor)
mm3d Tapioca File FileImagesNeighbour.xml $size


mm3d Schnaps .*$EXTENSION MoveBadImgs=1

#Compute Relative orientation (Arbitrary system)
mm3d Tapas FraserBasic .*$EXTENSION Out=Arbitrary SH=_mini

#Visualize relative orientation, if apericloud is not working, run 

mm3d AperiCloud .*$EXTENSION Ori-Arbitrary SH=_mini


#Transform to  RTL system
mm3d CenterBascule .*$EXTENSION Arbitrary RAWGNSS_N Ground_Init_RTL

#This tends to screw things up - not required 
#Bundle adjust using both camera positions and tie points (number in EmGPS option is the quality estimate of the GNSS data in meters)
mm3d Campari .*$EXTENSION Ground_Init_RTL Ground_RTL EmGPS=[RAWGNSS_N,1] AllFree=1 SH=_mini

#Visualize Ground_RTL orientation
mm3d AperiCloud .*$EXTENSION Ori-Ground_RTL SH=_mini

#Change system to final cartographic system  
if [ "$CSV" != none ]; then 
    mm3d ChgSysCo  .*$EXTENSION Ground_RTL SysCoRTL.xml@SysUTM.xml Ground_UTM
else
    mm3d ChgSysCo  .*$EXTENSION Ground_RTL RTLFromExif.xml@SysUTM.xml Ground_UTM
    mm3d OriExport Ori-Ground_UTM/.*xml CameraPositionsUTM.txt AddF=1
fi


#Correlation into DEM 
 
if [ "$gpu" != 1 ]; then 
    mm3d Malt UrbanMNE ".*.$EXTENSION" Ground_UTM UseGpu=0 EZA=1 DoOrtho=1 SzW=$win ZoomF=$ZoomF NbProc=$proc
else
	/home/ciaran/MicMacGPU/micmac/bin/mm3d Malt UrbanMNE ".*.$EXTENSION" Ground_UTM UseGpu=1 EZA=1 DoOrtho=1 SzW=$win ZoomF=$ZoomF NbProc=$proc
fi

if [ "$DEQ" != none ]; then 
	mm3d Tawny Ortho-MEC-Malt RadiomEgal=1 Out=Orthophotomosaic.tif DEq=$DEQ 
else
	mm3d Tawny Ortho-MEC-Malt RadiomEgal=1 Out=Orthophotomosaic.tif DEq=1 
fi

mm3d Tawny Ortho-MEC-Malt RadiomEgal=1 DegRap=4

# TODO - Tawny is not great for a homogenous ortho

# OSSIM - BASED MOSAICING ----------------------------------------------------------------------------
# Just here as an alternative for putting together tiles 
#for f in *.tif; 
#do      
#gdal_edit.py -a_srs "+proj=utm +zone=30 +north +ellps=WGS84 +datum=WGS84 +units=m +no_defs" "$f"; 
#done




# Create some image histograms for ossim
#ossim-create-histo -i *Ort**.tif;
#GNU para
# find **Ort_*.tif | parallel "ossim-create-histo -i {}"
 
# Basic ortho with ossim is:
#ossim-orthoigen *Ort**.tif mosaic_plain.tif;

#ossim-orthoigen --combiner-type ossimFeatherMosaic *tile*/*Ortho-MEC-Malt/*Orthophotomosaic*.tif feather.tif

#choices
#ossimBlendMosaic ossimMaxMosaic ossimImageMosaic ossimClosestToCenterCombiner ossimBandMergeSource ossimFeatherMosaic 


#Making OUTPUT folder
mkdir OUTPUT
#PointCloud from Ortho+DEM, with offset substracted to the coordinates to solve the 32bit precision issue
mm3d Nuage2Ply MEC-Malt/NuageImProf_STD-MALT_Etape_8.xml Attr=Ortho-MEC-Malt/Orthophotomosaic.tif Out=OUTPUT/PointCloud_OffsetUTM.ply Offs=[$X_OFF,$Y_OFF,0]

cd MEC-Malt
finalDEMs=($(ls Z_Num*_DeZoom*_STD-MALT.tif))
finalcors=($(ls Correl_STD-MALT_Num*.tif))
DEMind=$((${#finalDEMs[@]}-1))
corind=$((${#finalcors[@]}-1))
lastDEM=${finalDEMs[DEMind]}
lastcor=${finalcors[corind]}
laststr="${lastDEM%.*}"
corrstr="${lastcor%.*}"
cp $laststr.tfw $corrstr.tfw
cd ..


mm3d ConvertIm Ortho-MEC-Malt/Orthophotomosaic.tif Out=OrthFinal.tif

gdal_translate -a_srs "+proj=utm +zone=$UTM +ellps=WGS84 +datum=WGS84 +units=m +no_defs" Ortho-MEC-Malt/OrthFinal.tif OUTPUT/OrthoImage_geotif.tif
gdal_translate -a_srs "+proj=utm +zone=$UTM +ellps=WGS84 +datum=WGS84 +units=m +no_defs" MEC-Malt/$lastDEM OUTPUT/DEM_geotif.tif
gdal_translate -a_srs "+proj=utm +zone=$UTM +ellps=WGS84 +datum=WGS84 +units=m +no_defs" MEC-Malt/$lastcor OUTPUT/CORR.tif
