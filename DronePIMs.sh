# This is a generic workflow for DJI type platforms etc with embedded GNSS data
# Modified from the original L.Girod script

# example:
# ./DronePIMs.sh -e JPG -a Forest -u "30 +north" -r 0.1

# Important NOTE - MicMac CPU based is FAR quicker than using the GPU, as it's memory management limits GPU processing to small chunks
 
# add default values
EXTENSION=JPG
X_OFF=0;
Y_OFF=0;
utm_set=false
do_ply=true
do_AperiCloud=true
size=2000 
resol_set=false
ZoomF=1  
DEQ=1
gpu=false
obliqueFolder=none 
Algorithm=MicMac  

 
while getopts "e:a:csv:x:y:u:sz:spao:r:z:eq:h" opt; do
  case $opt in
    h) 
      echo "Run the workflow for drone acquisition at nadir (and pseudo nadir) angles)."
      echo "usage: DronePIMs.sh -e JPG -a MicMac -u 30 +north -r 0.1"
      echo "	-e EXTENSION     : image file type (JPG, jpg, TIF, png..., default=JPG)."
      echo "	-a Algorithm     : type of algo eg BigMac, MicMac, Forest, Statue etc"
      echo "	-x X_OFF         : X (easting) offset for ply file overflow issue (default=0)."
      echo "	-y Y_OFF         : Y (northing) offset for ply file overflow issue (default=0)."
      echo "	-u UTMZONE       : UTM Zone of area of interest. Takes form 'NN +north(south)'"
      echo "	-sz size         : resize of imagery eg - 2000"
      echo "	-p do_ply        : use to NOT export ply file."
      echo "	-a do_AperiCloud : use to NOT export AperiCloud file."
      echo "	-o obliqueFolder : Folder with oblique imagery to help orientation (will be entierely copied then deleted during process)."
      echo "	-r RESOL         : Ground resolution (in meters)"
      echo "	-z ZoomF         : Last step in pyramidal dense correlation (default=2, can be in [8,4,2,1])"
      echo "	-eq DEQ          : Degree of equalisation between images during mosaicing (See mm3d Tawny)"
      echo " -g gpu           : Whether to use GPU support, default false"
      echo "	-h	             : displays this message and exits."
      echo " "
      exit 0 
      ;;    
	e)   
      EXTENSION=$OPTARG 
      ;;
    algo)
      Algorithm=$OPTARG
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
	s)
      use_Schnaps=false
      ;;   	
    p)
      do_ply=false
      ;; 
    a)
      do_AperiCloud=false
      ;; 
	o)
      obliqueFolder=$OPTARG
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
      gpu=false  
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
#if [ "$use_schnaps" = true ]; then
#	echo "Using Schnaps!"
#	SH="_mini"
#else
#	echo "Not using Schnaps!"
#	SH=""
#fi
if [ "$gpu" = false ]; then
	echo "Using CPU only"
fi
if [ "$gpu" = true ]; then
	echo "Using GPU support" 
fi 
 
echo "Using $Algorithm for PIMs dense matching"  

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
      
 
#Copy everything from the folder with oblique images
if [ "obliqueFolder" != none ]; then
	cp $obliqueFolder/* . 
fi 
 
#Convert all images to tif (BW and RGB) for use in AperiCloud (because it otherwise breaks if too many CPUs are used)
#if [ "$do_AperiCloud" = true ]; then
#	DevAllPrep.sh
#fi 
#mm3d SetExif ."*JPG" F35=45 F=30 Cam=ILCE-6000  
#Get the GNSS data out of the images and convert it to a txt file (GpsCoordinatesFromExif.txt)
#if [ "$CSV"= true ]; then 
#    echo "using csv file" 
#    cs=*.csv   
 # mm3d OriConvert OriTxtInFile $cs RAWGNSS_N ChSys=DegreeWGS84@SysUTM.xml MTD1=1  NameCple=FileImagesNeighbour.xml CalcV=1

mm3d XifGps2Txt .*$EXTENSION
#Get the GNSS data out of the images and convert it to a xml orientation folder (Ori-RAWGNSS), also create a good RTL (Local Radial Tangential) system.
mm3d XifGps2Xml .*$EXTENSION RAWGNSS
 
#Use the GpsCoordinatesFromExif.txt file to create a xml orientation folder (Ori-RAWGNSS_N), and a file (FileImagesNeighbour.xml) detailing what image sees what other image (if camera is <50m away with option DN=50)
mm3d OriConvert "#F=N X Y Z" GpsCoordinatesFromExif.txt RAWGNSS_N ChSys=DegreeWGS84@RTLFromExif.xml MTD1=1 NameCple=FileImagesNeighbour.xml CalcV=1

#Find Tie points using 1/2 resolution image (best value for RGB bayer sensor)
mm3d Tapioca File FileImagesNeighbour.xml $size
 
#if [ "$use_schnaps" = true ]; then 
	#filter TiePoints (better distribution, avoid clogging)
mm3d Schnaps .*$EXTENSION MoveBadImgs=1 VeryStrict=1

#fi  
#Compute Relative orientation (Arbitrary system)
mm3d Tapas Fraser .*$EXTENSION Out=Arbitrary SH=_mini

#Visualize relative orientation, if apericloud is not working, run  
#if [ "$do_AperiCloud" = true ]; then 
mm3d AperiCloud .*$EXTENSION Arbitrary  
	
mm3d CenterBascule .*$EXTENSION Arbitrary RAWGNSS_N Ground_Init_RTL


#Bundle adjust using both camera positions and tie points (number in EmGPS option is the quality estimate of the GNSS data in meters)
mm3d Campari .*$EXTENSION Ground_Init_RTL Ground_RTL EmGPS=[RAWGNSS_N,1] AllFree=1 SH=_mini
   
#Visualize Ground_RTL orientation   
#if [ "$do_AperiCloud" = true ]; then
mm3d AperiCloud .*$EXTENSION Ground_RTL SH=_mini
#fi 
 
   
  
#Change system to final cartographic system  
if [ "$CSV" = true ]; then 
    mm3d ChgSysCo  .*$EXTENSION Ground_RTL SysCoRTL.xml@SysUTM.xml Ground_UTM
else
    mm3d ChgSysCo  .*$EXTENSION Ground_RTL RTLFromExif.xml@SysUTM.xml Ground_UTM
    mm3d OriExport Ori-Ground_UTM/.*xml CameraPositionsUTM.txt AddF=1
fi

#Print out a text file with the camera positions (for use in external software, e.g. GIS)

 
#Taking away files from the oblique folder
if [ "$obliqueFolder" != none ]; then	
	here=$(pwd)
	cd $obliqueFolder	 
	find ./ -type f -name "*" | while read filename; do
		f=$(basename "$filename")
		rm  $here/$f 
	done	
	cd $here	
fi

# Important NOTE
 
 

if [ "$gpu" = true ]; then
	#mm3d PIMs $Algorithm .*$EXTENSION Ground_UTM DefCor=0 ZReg=0.005 SzW=1 UseGpu=1 ZoomF=$ZoomF 
	pims_subset.py -folder $PWD -algo $Algorithm -num 150
else
    mm3d PIMs $Algorithm .*$EXTENSION Ground_UTM DefCor=0 SzW=1 ZoomF=$ZoomF  
fi 


#source activate pymicmac; 
 
# Part of crap hack as it doesn't uinderstand the compiled stuff from other micmac
#rm -rf Tmp-MM-Dir/*.xml
#rm -rf Tmp-MM-Dir/*.dmp 

# This is likely to be added as Malt produces a void free Ortho NbProc key parameter
# For robustness it is better to leave defaults
#mm3d Malt Ortho ".*JPG" Ground_UTM  EZA=1 NbProc=20
# Also worth using Ground or Urbane settings depending on application

# UseTA=1 # this would rid us of the crap interp in voids 
mm3d Pims2MNT $Algorithm DoOrtho=1

 

#source deactivate pymicmac;
#if [ "$DEQ" != none ]; then 
#	mm3d Tawny Ortho-MEC-Malt DEq=$DEQ
#else
##	mm3d Tawny Ortho-MEC-Malt DEq=1
#fi
mm3d Tawny PIMs-ORTHO/ RadiomEgal=1 Out=Orthophotomosaic.tif

#Making OUTPUT folder
mkdir OUTPUT


# When images are large they will be tiled 




mm3d ConvertIm PIMs-TmpBasc/PIMs-Merged_Prof.tif Out=OUTPUT/DSM.tif
cp PIMs-TmpBasc/PIMs-Merged_Prof.tfw OUTPUT/DSM.tfw
 
mm3d ConvertIm PIMs-ORTHO/Orthophotomosaic.tif Out=OUTPUT/OrthFinal.tif
cp PIMs-ORTHO/Orthophotomosaic.tfw OUTPUT/OrthFinal.tfw

mm3d Nuage2Ply PIMs-TmpBasc/PIMs-Merged.xml Attr=OUTPUT/OrthFinal.tif Out=pointcloud.ply



 
# TODO - Tawny is not great for a homogenous ortho

# OSSIM - BASED MOSAICING ----------------------------------------------------------------------------
# Just here as an alternative for putting together tiles 
# This need GNU parallel
# gdalwarp -overwrite -s_srs "+proj=utm +zone=30 +ellps=WGS84+datum=WGS84 +units=m +no_defs" -t_srs EPSG:4326 -srcnodata 0 -dstnodata 0 *Ort**.tif


 
 
# Create some image histograms for ossim  
#ossim-create-histo -i *Ort**.tif;

# Basic ortho with ossim is:
#ossim-orthoigen *Ort**.tif mosaic_plain.tif;

# Or more options
# Here am feathering edges and matching histogram to specific image - produced most pleasing result
# See https://trac.osgeo.org/ossim/wiki/orthoigen for really detailed cmd help
#ossim-orthoigen --combiner-type ossimBlendMosaic *Ort**.tif mosaic_blend.tif
#ossim-orthoigen --combiner-type ossimFeatherMosaic --hist-match Ort_DSC00698.tif *Ort**.tif mosaic.tif;
# back to utm 




#gdal_translate -a_srs "+proj=utm +zone=$UTM +ellps=WGS84 +datum=WGS84 +units=m +no_defs" PIMs-ORTHO/OrthFinal.tif OUTPUT/OrthoImage_geotif.tif
#gdal_translate -a_srs "+proj=utm +zone=$UTM +ellps=WGS84 +datum=WGS84 +units=m +no_defs" PIMs-Tmp-Basc/PIMs-Merged_Prof.tif OUTPUT/DEM_geotif.tif


