#

#Created on Mon Oct  1 14:40:35 2018

#@author: Ciaran Robb
#""" 

# This is a workflow intended for processing very large UAV datasets (eg > 500 images) with MicMac
# Upon testing various configurations with the current version of MicMac,
# some limitations are evident in the use of GPU aided processing which speeds
# up processing considerably.

# This requires an install of MicMac with GPU support and an install of pymicmac to handle job allocation  
 
# (Do the following once MicMac is installed) 

# Install pycoeman dependencies 
#sudo apt-get install libfreetype6-dev libssl-dev libffi-dev
# Install pycoeman
#pip install git+https://github.com/NLeSC/pycoeman
# Install noodles
#pip install git+https://github.com/NLeSC/noodles
# Install pymicmac
#pip install git+https://github.com/ImproPhoto/pymicmac

# An issue with what I assume is shared memory between CPU & GPU results in only
# a linited number of CPU threads and images being useable without failure on large
# datasets.

# Consequently, an adaption of the pymicmac lib has been made to facilitate tile prcessing with GPU
# support within the limits of the current software on github


# Contains elements of L.Girod script - thanks 

# example:
# ./gpymicmac.sh -e JPG -u "30 +north" -g 6 -w 2 -prc 4 -b 4


 
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
obliqueFolder=none
grd=6 
proc=16  
win=2
batch=4
 
while getopts "e:x:y:u:sz:spao:r:z:eq:g:w:proc:b:h" opt; do  
  case $opt in
    h)
      echo "Run the workflow for drone acquisition at nadir (and pseudo nadir) angles)."
      echo "gpymicmac.sh -e JPG -u '30 +north' -g 6 -w 2 -prc 4 -b 4"
      echo "	-e EXTENSION     : image file type (JPG, jpg, TIF, png..., default=JPG)."
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
      echo " -g grd           : Grid dimension x and y"
      echo " -b batch           : no of jobs at any one time"
      echo " -w win           : Correl window size"
      echo " -prc proc        : no of CPU thread used (needed even when using GPU)"
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
      grd=$OPTARG
      ;;
	w)
      win=$OPTARG
      ;;
	prc)
      proc=$OPTARG  
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


echo "$proc CPU threads to be used during dense matching, be warned that this has limitations with respect to amount of images processed at a time"
echo "Using GPU support" 


  

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

#Get the GNSS data out of the images and convert it to a txt file (GpsCoordinatesFromExif.txt)
mm3d XifGps2Txt .*$EXTENSION

#Get the GNSS data out of the images and convert it to a xml orientation folder (Ori-RAWGNSS), also create a good RTL (Local Radial Tangential) system.
mm3d XifGps2Xml .*$EXTENSION RAWGNSS

#Use the GpsCoordinatesFromExif.txt file to create a xml orientation folder (Ori-RAWGNSS_N), and a file (FileImagesNeighbour.xml) detailing what image sees what other image (if camera is <50m away with option DN=50)
mm3d OriConvert "#F=N X Y Z" GpsCoordinatesFromExif.txt RAWGNSS_N ChSys=DegreeWGS84@RTLFromExif.xml MTD1=1 NameCple=FileImagesNeighbour.xml #DN=50

#Find Tie points using 1/2 resolution image (best value for RGB bayer sensor)
mm3d Tapioca File FileImagesNeighbour.xml $size


mm3d Schnaps .*$EXTENSION MoveBadImgs=1

#Compute Relative orientation (Arbitrary system)
mm3d Tapas FraserBasic .*$EXTENSION Out=Arbitrary SH=_mini

#Visualize relative orientation, if apericloud is not working, run 
#if [ "$do_AperiCloud" = true ]; then 
mm3d AperiCloud .*$EXTENSION Ori-Arbitrary SH=_mini
#fi

#Transform to  RTL system
mm3d CenterBascule .*$EXTENSION Arbitrary RAWGNSS_N Ground_Init_RTL

#This tends to screw things up - not required 
#Bundle adjust using both camera positions and tie points (number in EmGPS option is the quality estimate of the GNSS data in meters)
mm3d Campari .*$EXTENSION Ground_Init_RTL Ground_RTL EmGPS=[RAWGNSS_N,1] AllFree=1 SH=_mini

#Visualize Ground_RTL orientation
mm3d AperiCloud .*$EXTENSION Ori-Ground_RTL SH=_mini


#Change system to final cartographic system 
mm3d ChgSysCo  .*$EXTENSION Ground_RTL RTLFromExif.xml@SysUTM.xml Ground_UTM

#Print out a text file with the camera positions (for use in external software, e.g. GIS)
mm3d OriExport Ori-Ground_UTM/.*xml CameraPositionsUTM.txt AddF=1

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


#Correlation into DEM
# These args are used in grandleez 
# DirMEC=MEC DefCor=0 AffineLast=1 Regul=0.005 HrOr=0 LrOr=0 ZoomF=1
# Now we have figure out the GPU issue, it can become an optarg 

# Until the cuda internals of MicMac are sorted these tests worked whereas exceeding them did not!!!
# Successful test w/ 891 imgs
# NbProc=1, 3x3 grid, -n 4 (likely 4-5hrs)  
# NbProc=4, 5x5 grid, -n 3 (~2hrs) 
# NbProc=4, 6x6 grid, -n 4 (2hrs)  

rm -rf DMatch DistributedMatching.xml DSMs Mosaics DistGpu
 
micmac-distmatching-create-config -i Ori-Ground_UTM -e JPG -o DistributedMatching.xml -f DMatch -n $grd,$grd --maltOptions "DefCor=0 DoOrtho=1 UseGpu=1 SzW=$win NbProc=$proc ZoomF=1"




# The No of jobs going on here would suggest 16 threads that is how this is all actually working 
# Remember 1 batch is effectivelt sequential processing! This may be best when using lots of threads 
coeman-par-local -d . -c DistributedMatching.xml -e DistGpu  -n $batch

# Altered pymicmac writes seperate xml for Tawny as it is more efficient to run these all in parallel at the end as there
# is not the same constraints on batch numbers 
coeman-par-local -d . -c DistributedMatchingTawny.xml -e DistGpu  -n 20

# THIS LOT NOT TO BE USED YET....
#cd Mosaics
#for f in *.tif; do
#     gdal_translate -a_srs "+proj=utm +zone=$UTM +ellps=WGS84 +datum=WGS84 +units=m +no_defs" "$f" "${f%.*}final.tif"
#done 

#gdal_translate -a_srs "+proj=utm +zone=$UTM +ellps=WGS84 +datum=WGS84 +units=m +no_defs" MEC-Malt/$lastDEM OUTPUT/DEM_geotif.tif
 
# Create some image histograms for ossim
#ossim-create-histo -i *final.tif

#ossim-orthoigen --combiner-type ossimFeatherMosaic *final.tif feather.tif



