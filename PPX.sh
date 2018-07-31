# Author Ciaran Robb & Luc Girod

# A lot of this is Luc Girod's work (MicMac dev) - I have altered some inputs for
# the Bramour PPX platform
# You will need a Unix platform

# This file is a workflow for the Bramour PPX fixed wing platform 
# 

#I would like to remind users that an along-track overlap of 80% and across track overlap of 60% are the minimum recommended values.

# example: (remove dot and slash if on your path)
# ./PPX.sh -e JPG -csv Llan.csv -u "30 +north" -r 0.1



# add default values
EXTENSION=JPG 
CSV=*.csv  
X_OFF=0;
Y_OFF=0;
utm_set=false
size=2000
do_ply=true
resol_set=false
ZoomF=1
DEQ=1
gpu=0
  
# TODO An option for this cmd if exif lacks info, which with bramour is possible
# mm3d SetExif ."*JPG" F35=45 F=30 Cam=ILCE-6000  
 
while getopts "e:csv:x:y:u:sz:p:r:z:eq:g:h" opt; do   
  case $opt in 
    h)
      echo "Run the workflow for drone acquisition at nadir (and pseudo nadir) angles)."
      echo "usage: PPX.sh -e JPG -x 55000 -y 6600000 -u \"32 +north\" -p true -r 0.05"
      echo "	-e EXTENSION     : image file type (JPG, jpg, TIF, png..., default=JPG)."
      echo "	-csv CSV         : csv of image coords"
      echo "	-x X_OFF         : X (easting) offset for ply file overflow issue (default=0)."
      echo "	-y Y_OFF         : Y (northing) offset for ply file overflow issue (default=0)."
      echo "	-u UTMZONE       : UTM Zone of area of interest. Takes form 'NN +north(south)'"
      echo "	-s SH            : Do not use 'Schnaps' optimised homologous points."
      echo "	-p do_ply        : use to NOT export ply file."
      echo "	-r RESOL         : Ground resolution (in meters)"
      echo "	-z ZoomF         : Last step in pyramidal dense correlation (default=2, can be in [8,4,2,1])"
      echo "	-eq DEQ          : Degree of equalisation between images during mosaicing (See mm3d Tawny)"
      echo "	-g gpu           : Use GPU default is 0, if you want to use -g=1"
      echo "	-h	         : displays this message and exits."
      echo " "
      exit 0
      ;;    
	e)  
      EXTENSION=$OPTARG
      ;;    
	csv)
      CSV=$OPTARG 
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
    p)
      do_ply=false
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
	g)
      gpu=$OPTARG    
      ;;
    \?)
      echo "PPXNadir.sh: Invalid option: -$OPTARG" >&1
      exit 1
      ;;
    :)
      echo "PPXNadir.sh: Option -$OPTARG requires an argument." >&1
      exit 1
      ;;
  esac
done
if [ "$utm_set" = false ]; then
	echo "UTM zone not set"
	exit 1
fi
if [ "$use_schnaps" = true ]; then
	echo "Using Schnaps!"
	SH="_mini"
else
	echo "Not using Schnaps!"
	SH=""
fi

# TODO An option for this cmd if exif lacks info, which with bramour is possible
# mm3d SetExif ."*JPG" F35=45 F=30 Cam=ILCE-6000 

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


 


# In place of L.Girods cmds to get coords from the images we are using a csv file as this applys to a system where they are recorded by a separate GPS

mm3d OriConvert OriTxtInFile $CSV RAWGNSS_N ChSys=DegreeWGS84@SysCoRTL.xml MTD1=1  NameCple=FileImagesNeighbour.xml CalcV=1
 
#Find Tie points using 1/2 resolution image 

mm3d Tapioca File FileImagesNeighbour.xml $size

mm3d Schnaps .*$EXTENSION VeryStrict=1 MoveBadImgs=1

#Compute Relative orientation (Arbitrary system)
mm3d Tapas FraserBasic .*$EXTENSION Out=Arbitrary SH=_mini

#Visualize relative orientation, if apericloud is not working, run  

mm3d AperiCloud .*$EXTENSION Ori-Arbitrary SH=_mini 
 

#Transform to  RTL system
mm3d CenterBascule .*$EXTENSION Arbitrary RAWGNSS_N Ground_Init_RTL

#Bundle adjust using both camera positions and tie points (number in EmGPS option is the quality estimate of the GNSS data in meters)
# Should this be replaced with the delay estimate? EmGPS is 1 metre here but it could be lower.  
mm3d Campari .*$EXTENSION Ground_Init_RTL Ground_RTL EmGPS=[RAWGNSS_N,1] AllFree=1 SH=_mini

#Visualize Ground_RTL orientation
if [ "$do_AperiCloud" = true ]; then
	mm3d AperiCloud .*$EXTENSION Ori-Ground_RTL SH=_mini 
fi
#Change system to final cartographic system
mm3d ChgSysCo  .*$EXTENSION Ground_RTL SysCoRTL.xml@SysUTM.xml Ground_UTM

#Print out a text file with the camera positions (for use in external software, e.g. GIS)
mm3d OriExport Ori-Ground_UTM/.*xml CameraPositionsUTM.txt AddF=1

#Taking away files from the oblique folder
#if [ "$obliqueFolder" != none ]; then	
#	here=$(pwd)
#	cd $obliqueFolder	
#	find ./ -type f -name "*" | while read filename; do
#		f=$(basename "$filename")
#		rm  $here/$f
#	done	
#	cd $here	
#fi

  
# Correlation into DEM - Note these use the smallest correll window of 3 - SzW=1
# This is to ensure detail captured on forest or high freq areas of features

# Note on GPUs - this seems to fail no matter what at present

# Also the NbProc=32 (eg) is the threads but not sure if this uses all by default
# It looks as though it does on the makefiles generated

if [ "$resol_set" = true ]; then
	mm3d Malt Ortho ".*.$EXTENSION" Ground_UTM SzW=1 UseGpu=$gpu ResolTerrain=$RESOL EZA=1 ZoomF=$ZoomF
else
	mm3d Malt Ortho ".*.$EXTENSION" Ground_UTM  SzW=1 UseGpu=$gpu EZA=1 ZoomF=$ZoomF
fi

#Mosaic from individual orthos
# NOTE - think an equalisation method would not go amiss here eg DEq=2 hence it has been added for now

if [ "$DEQ" != none ]; then
	mm3d Tawny Ortho-MEC-Malt DEq=$DEQ
else
	mm3d Tawny Ortho-MEC-Malt DEq=1
fi



# TODO - Tawny is not great for a homogenous ortho

# Here is an alternative on the MM forum using image magick
# Just here as an alternative for putting together tiles 
# # This need GNU parallel
# paralell echo ::: cmd
# gdalwarp -overwrite -s_srs "+proj=utm +zone=30 +ellps=WGS84+datum=WGS84 +units=m +no_defs" -t_srs EPSG:4326 -srcnodata 0 -dstnodata 0 *Ort**.tif
# Create some image histograms for ossim
#ossim-create-histo -i *Ort**.tif;

# Unfortunately have to reproject all the bloody images for OSSIM to understand ie espg4326
# Basic ortho with ossim is:
#ossim-orthoigen *Ort**.tif mosaic_plain.tif;

# Or more options
# Here am feathering edges and matching histogram to specific image - produced most pleasing result
# See https://trac.osgeo.org/ossim/wiki/orthoigen for really detailed cmd help
#ossim-orthoigen --combiner-type ossimFeatherMosaic --hist-match Ort_DSC00698.tif *Ort**.tif mosaic.tif;
#ossim-orthoigen --combiner-type ossimBlendMosaic *Ort**.tif mosaic_blend.tif
# back to utm
# gdalwarp -t_srs EPSG:4326  -s_srs EPSG:32630 *Ort**.tif


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

gdal_translate -a_srs "+proj=utm +zone=$UTM +ellps=WGS84 +datum=WGS84 +units=m +no_defs" Ortho-MEC-Malt/Orthophotomosaic.tif OUTPUT/OrthoImage_geotif.tif
gdal_translate -a_srs "+proj=utm +zone=$UTM +ellps=WGS84 +datum=WGS84 +units=m +no_defs" MEC-Malt/$lastDEM OUTPUT/DEM_geotif.tif
gdal_translate -a_srs "+proj=utm +zone=$UTM +ellps=WGS84 +datum=WGS84 +units=m +no_defs" MEC-Malt/$lastcor OUTPUT/CORR.tif

 