#!/bin/bash



resol_set=false
ZoomF=2
EQUAL=2


while getopts "d:r:z:e:h" opt; do
  case $opt in
    h)
      echo "Run the workflow for drone acquisition at nadir (and pseudo nadir) angles)."
      echo "usage: dense_cloud.sh -d 0.563 -r 0.05 -e 3"
      echo "	-d DELAY         : GNSS - Camera Delay"
      echo "	-r RESOL         : Ground resolution (in meters)"
      echo "	-z ZoomF         : Last step in pyramidal dense correlation , (default=2 can be in [8,4,2,1])"
      echo "	-e EQUAL         : Degree of equalisation during mosaicing with Tawny (default=2)"
      echo "	-h	             : displays this message and exits."
      echo " "
      exit 0
      ;;   
	d)
      DELAY=$OPTARG
      ;;  
	r)
      RESOL=$OPTARG
      resol_set=true
      ;;	 
	z)
      ZoomF=$OPTARG
      ;;
	e)
      EQUAL=$OPTARG
      ;;
    \?)
      echo "dense_cloud.sh: Invalid option: -$OPTARG" >&1
      exit 1
      ;;
    :)
      echo "dense_cloud.sh: Option -$OPTARG requires an argument." >&1
      exit 1
      ;;
  esac
done

# GNSS - camera delay
mm3d OriConvert OriTxtInFile $DELAY Nav-adjusted-RTL ChSys=DegreeWGS84@SysCoRTL.xml MTD1=1 Delay=$2;


# Execute the adjustment
mm3d CenterBascule ".*JPG" All-Rel Nav-adjusted-RTL All-RTL;

# CRITICAL THAT THE XML IS NAMED CORRECTLY!!!! AS BELOW!!!!!!!!!!!!!!!!!!

mm3d ChgSysCo  ".*JPG" All-RTL SysCoRTL.xml@SysUTM.xml Ground-UTM;


#Correlation into DEM
if [ "$resol_set" = true ]; then
	mm3d Malt Ortho ".*.$EXTENSION" Ground_UTM ResolTerrain=$RESOL EZA=1 ZoomF=$ZoomF
else
	mm3d Malt Ortho ".*.$EXTENSION" Ground_UTM EZA=1 ZoomF=$ZoomF
fi
 
#Mosaic from individual orthos
# NOTE - think an equalisation method would not go amiss here eg DEq=2 hence it has been added for now
mm3d Tawny Ortho-MEC-Malt DEq=$EQUAL
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

gdal_translate -a_srs "+proj=utm +zone=$UTM +ellps=WGS84 +datum=WGS84 +units=m +no_defs" Ortho-MEC-Malt/Orthophotomosaic.tif OUTPUT/OrthoImage_geotif.tif
gdal_translate -a_srs "+proj=utm +zone=$UTM +ellps=WGS84 +datum=WGS84 +units=m +no_defs" MEC-Malt/$lastDEM OUTPUT/DEM_geotif.tif
gdal_translate -a_srs "+proj=utm +zone=$UTM +ellps=WGS84 +datum=WGS84 +units=m +no_defs" MEC-Malt/$lastcor OUTPUT/CORR.tif