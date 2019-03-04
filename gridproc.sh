#

#Created on Mon Oct  1 14:40:35 2018
# Author Ciaran Robb
# Aberystwyth University
#""" 

# This is a workflow intended for processing very large UAV datasets (eg > 500 images) with MicMac
# Upon testing various configurations with the current version of MicMac,
# some limitations are evident in the use of GPU aided processing which speeds
# up processing considerably.

# This requires an install of MicMac with  potional GPU support if you wish to use that
  

# A parallel processing tool for large scale Malt processing, uses single threads per tile with optional GPU support


# Contains elements of L.Girod script - thanks 

# example:
# ./gridproc.sh -e JPG -u "30 +north" -g 6,6 -w 2 -gpu 1 -b 6


 
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
win=1
batch=4
gpu=none
sz=none
CSV=none


 
while getopts "e:x:y:u:sz:spao:r:z:eq:g:gpu:b:w:prc:csv:h" opt; do  
  case $opt in
    h)
      echo "Run the workflow for drone acquisition at nadir (and pseudo nadir) angles)."
      echo "gridproc.sh -e JPG -u '30 +north' -g 6 -w 2 -prc 4 -b 4"
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
      echo " -gpu gp          : GPU support 1 for use"
      echo " -b batch         : no of jobs at any one time"
      echo " -w win           : Correl window size"
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
     b)
      batch=$OPTARG 
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
    SysCort_make.py -csv $cs   
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
    # mogrify -path Sharp -sharpen 0x3  *.JPG # this sharpens very well worth doing
    mm3d Tapioca File FileImagesNeighbour.xml -1 @SFS
else
    echo "using a default re-size of 2000 long axis on imgs"
    mogrify -resize 3000 *.JPG 
    mm3d Tapioca File FileImagesNeighbour.xml -1 @SFS
fi 

mm3d Schnaps .*$EXTENSION MoveBadImgs=1

#Compute Relative orientation (Arbitrary system)
mm3d Tapas Fraser .*$EXTENSION Out=Arbitrary SH=_mini

#Transform to  RTL system
mm3d CenterBascule .*$EXTENSION Arbitrary RAWGNSS_N Ground_Init_RTL



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

#fi
 
 
# Parallel processing - best for a decent ortho later 
if [ "$gp" != none ]; then
    MaltBatch.py -folder $PWD -algo UrbanMNE -num $grd -zr 0.02 -g 1 -nt $batch 
else
    MaltBatch.py -folder $PWD -algo UrbanMNE -num $grd -zr 0.02 -nt $batch 

#correct_mosaics.py -folder DistGpu
 
orthomosaic.sh -f $PWD -u $UTM -mt ossimFeatherMosaic

dsmmosaic.sh -f $PWD -u $UTM -mt ossimMaxMosaic

#choices
#ossimBlendMosaic ossimMaxMosaic ossimImageMosaic ossimClosestToCenterCombiner ossimBandMergeSource ossimFeatherMosaic 
 




