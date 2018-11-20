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
# ./gpymicmac.sh -e JPG -u "30 +north" -g 6 -w 2 -prc 4 -gpu 1 -b 4


 
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
proc=1  
win=1
batch=4
gpu=none
sz=none
CSV=none


 
while getopts "e:x:y:u:sz:spao:r:z:eq:g:gpu:b:w:prc:csv:h" opt; do  
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
      echo " -gpu gp          : Grid dimension x and y"
      echo " -b batch         : no of jobs at any one time"
      echo " -w win           : Correl window size"
      echo " -prc proc        : no of CPU thread used (needed even when using GPU)"
      echo " -csv CSV         : a csv file of gnsss etc - default none - something if needed"
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
    gpu)
      gp=$OPTARG
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
      echo "gpymicmac.sh: Invalid option: -$OPTARG" >&1
      exit 1
      ;;
    :)
      echo "gpymicmac.sh: Option -$OPTARG requires an argument." >&1
      exit 1
      ;;
  esac
done
if [ "$utm_set" = false ]; then
	echo "UTM zone not set"
	exit 1
fi
#mm3d SetExif ."*JPG" F35=45 F=30 Cam=ILCE-6000  
# mogrify -resize 2000 *.JPG


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

#mm3d SetExif ."*JPG" F35=45 F=30 Cam=ILCE-6000  
# magick convert .*$EXTENSION -resize 50% .*$EXTENSION 
#Get the GNSS data out of the images and convert it to a txt file (GpsCoordinatesFromExif.txt)
if [  "$CSV" != none  ]; then 
        echo "using csv file"  
    cs=*.csv   
    mm3d OriConvert OriTxtInFile $cs RAWGNSS_N ChSys=DegreeWGS84@SysUTM.xml MTD1=1  NameCple=FileImagesNeighbour.xml CalcV=1
    SysCort_make.py(cs)   
else
    echo "using exif data"
    mm3d XifGps2Txt .*$EXTENSION
    #Get the GNSS data out of the images and convert it to a xml orientation folder (Ori-RAWGNSS), also create a good RTL (Local Radial Tangential) system.
    mm3d XifGps2Xml .*$EXTENSION RAWGNSS
    mm3d OriConvert "#F=N X Y Z" GpsCoordinatesFromExif.txt RAWGNSS_N ChSys=DegreeWGS84@RTLFromExif.xml MTD1=1 NameCple=FileImagesNeighbour.xml CalcV=1
fi 
#Use the GpsCoordinatesFromExif.txt file to create a xml orientation folder (Ori-RAWGNSS_N), and a file (FileImagesNeighbour.xml) detailing what image sees what other image (if camera is <50m away with option DN=50)


#Find Tie points using 1/2 resolution image (best value for RGB bayer sensor)
if [  "$size" != none ]; then
    echo "resizing to $size for tie point detection"
    mogrify -resize $size *.JPG
    mm3d Tapioca File FileImagesNeighbour.xml -1 @SFS
else
    echo "using a default re-size of 2000 long axis on imgs"
    mogrify -resize 2000 *.JPG 
    mm3d Tapioca File FileImagesNeighbour.xml -1 @SFS
fi 

mm3d Schnaps .*$EXTENSION MoveBadImgs=1

#Compute Relative orientation (Arbitrary system)
mm3d Tapas FraserBasic .*$EXTENSION Out=Arbitrary SH=_mini

#Transform to  RTL system
mm3d CenterBascule .*$EXTENSION Arbitrary RAWGNSS_N Ground_Init_RTL

#This tends to screw things up - not required 
#Bundle adjust using both camera positions and tie points (number in EmGPS option is the quality estimate of the GNSS data in meters)


#Visualize Ground_RTL orientation


#Change system to final cartographic system  
if [ $CSV != none ]; then 
    mm3d Campari .*$EXTENSION Ground_Init_RTL Ground_UTM EmGPS=[RAWGNSS_N,1] AllFree=1 SH=_mini
    # For reasons unknown this screws it up from csv
    #mm3d ChgSysCo  .*$EXTENSION Ground_RTL SysCoRTL.xml@SysUTM.xml Ground_UTM
    mm3d AperiCloud .*$EXTENSION Ori-Ground_RTL SH=_mini

else
    mm3d Campari .*$EXTENSION Ground_Init_RTL Ground_RTL EmGPS=[RAWGNSS_N,1] AllFree=1 SH=_mini
    mm3d ChgSysCo  .*$EXTENSION Ground_RTL RTLFromExif.xml@SysUTM.xml Ground_UTM
    mm3d OriExport Ori-Ground_UTM/.*xml CameraPositionsUTM.txt AddF=1
    mm3d AperiCloud .*$EXTENSION Ori-Ground_RTL SH=_mini

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

rm -rf DMatch DistributedMatching.xml DistGpu 
 
if [ "$gp" != none ]; then
    micmac-distmatching-create-config -i Ori-Ground_UTM -e JPG -o DistributedMatching.xml -f DMatch -n $grd,$grd -t Homol_mini --maltOptions "DefCor=0 DoOrtho=1 UseGpu=1 Regul=0.02 EZA=1 SzW=$win NbProc=$proc ZoomF=$ZoomF" 
    
else
    micmac-distmatching-create-config -i Ori-Ground_UTM -e JPG -o DistributedMatching.xml -f DMatch -n $grd,$grd -t Homol_mini --maltOptions "DefCor=0 DoOrtho=1 SzW=$win Regul=0.02 EZA=1 NbProc=$proc ZoomF=$ZoomF"
      
fi
  

# Altered pymicmac writes seperate xml for Tawny as it is more efficient to run these all in parallel at the end as there
# is not the same constraints on batch numbers 
coeman-par-local -d . -c DistributedMatching.xml -e DistGpu  -n 8

correct_mosaics.py -folder DistGpu
 
# Here we loop through all the mosaic and add georef which is lost by MicMac
echo "geo-reffing Orthos"
for f in *tile*/*Ortho-MEC-Malt/*Mosaic*.tif; do
    gdal_edit.py -a_srs "+proj=utm +zone=$UTM  +ellps=WGS84 +datum=WGS84 +units=m +no_defs" "$f"; done
done 
  
# this works 
find *tile*/*Ortho-MEC-Malt/*Mosaic*.tif | parallel "ossim-create-histo -i {}" 
 
# Max seems best
ossim-orthoigen --combiner-type ossimMaxMosaic  *tile*/*Ortho-MEC-Malt/*Mosaic*.tif Orthomax.tif

#--writer-prop threads=20 
#choices
#ossimBlendMosaic ossimMaxMosaic ossimImageMosaic ossimClosestToCenterCombiner ossimBandMergeSource ossimFeatherMosaic 

# Just background info here
#tfw is :
#5.000000000000	(size of pixel in x direction)
#0.000000000000	(rotation term for row)
#0.000000000000	(rotation term for column) 
#-5.000000000000	(size of pixel in y direction)
#492169.690845528910	(x coordinate of centre of upper left pixel in map units)
#5426523.318065105000	(y coordinate of centre of upper left pixel in map units)



# georef the dsms.....
echo "geo-reffing DSMs"  
#finalDEMs=($(ls Z_Num*_DeZoom*_STD-MALT.tif)) 
for f in *tile*/*MEC-Malt/Z_Num7_DeZoom2_STD-MALT.tif; do
    gdal_edit.py -a_srs "+proj=utm +zone=$UTM  +ellps=WGS84 +datum=WGS84 +units=m +no_defs" "$f"; done
done 

# mask_dsm.py -folder $PWD -n 20 -z 1 -m 1
#  This will assume a zoom level 2 
mask_dsm.py -folder DistGpu 


find *tile*/*MEC-Malt/Z_Num7_DeZoom2_STD-MALT.tif | parallel "ossim-create-histo -i {}" 

ossim-orthoigen --combiner-type ossimMaxMosaic  *tile*/*MEC-Malt/Z_Num7_DeZoom2_STD-MALT.tif DSMmax.tif


