# This script detects tie/key points, orients imagery in relative space then
# adjusts using GNSS data 

# Author Ciaran Robb
# Aberystwyth University

#https://github.com/Ciaran1981/Sfm
# example:
# ./Orientation.sh -e JPG -u "30 +north" -cal Fraser

 

# add default values 
EXTENSION=JPG
X_OFF=0;
Y_OFF=0;
utm_set=false
obliqueFolder=none
sz=none
CSV=none
CALIB=Fraser
 
while getopts "e:m:x:y:u:sz:cal:csv:h" opt; do  
  case $opt in
    h)
      echo "Run the workflow for drone acquisition at nadir (and pseudo nadir) angles)."
      echo "Usage: Orientation.sh -e JPG -u 30 +north" 
      echo "	-e EXTENSION     : image file type (JPG, jpg, TIF, png..., default=JPG)."
      echo "	-m match         : exaustive matching" 
      echo "	-u UTMZONE       : UTM Zone of area of interest. Takes form 'NN +north(south)'"
      echo "	-sz size         : resize of imagery eg - 2000"
      echo "	-cal CALIB        : Camera calibration model - e.g. RadialBasic, Fraser etc"
      echo " -csv -CSV        : whether to use a separate csv "
      echo "	-h	             : displays this message and exits."
      echo " "  
      exit 0
      ;;    
	e)
      EXTENSION=$OPTARG
      ;;
    m)
      match=$OPTARG 
      ;;
	u)
      UTM=$OPTARG
      utm_set=true
      ;;
 	sz)
      size=$OPTARG
      ;; 
 	cal)
      CALIB=$OPTARG
      ;;        
    csv)
      CSV=$OPTARG 
      ;;         
    \?)
      echo "Orientation.sh: Invalid option: -$OPTARG" >&1
      exit 1
      ;;
    :)
      echo "Orientation.sh: Option -$OPTARG requires an argument." >&1
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
# magick mogrify -resize 50%

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
# mogrify -resize 30% *.JPG
#mogrify -resize 2000 *.JPG
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
#Find Tie points using 1/2 resolution image (best value for RGB bayer sensor)
if [  "$size" != none ]; then
    echo "resizing to $size for tie point detection"
    # mogrify -path Sharp -sharpen 0x3  *.JPG # this sharpens very well worth doing
    mogrify -resize $size *.JPG
else
    echo "using a default re-size of 3000 long axis on imgs"
    mogrify -resize 3000 *.JPG 
fi 

if [  "$match" != none ]; then
    echo "exaustive matching"
    mm3d Tapioca All ".*JPG" -1 @SFS
else
    mm3d Tapioca File FileImagesNeighbour.xml -1 @SFS
fi


mm3d Schnaps .*$EXTENSION MoveBadImgs=1

#Compute Relative orientation (Arbitrary system)
mm3d Tapas $CALIB .*$EXTENSION Out=Arbitrary SH=_mini | tee RelBundle.txt

#Visualize relative orientation, if apericloud is not working, run 

mm3d AperiCloud .*$EXTENSION Ori-Arbitrary SH=_mini


#Transform to  RTL system
mm3d CenterBascule .*$EXTENSION Arbitrary RAWGNSS_N Ground_Init_RTL

#This tends to screw things up - not required 
#Bundle adjust using both camera positions and tie points (number in EmGPS option is the quality estimate of the GNSS data in meters)

#Visualize Ground_RTL orientation
mm3d AperiCloud .*$EXTENSION Ori-Ground_RTL SH=_mini

#Change system to final cartographic system  
if [ $CSV != none ]; then 
    mm3d Campari .*$EXTENSION Ground_Init_RTL Ground_UTM EmGPS=[RAWGNSS_N,1] AllFree=1 SH=_mini | tee GnssBundle.txt
    # For reasons unknown this screws it up from csv
    #mm3d ChgSysCo  .*$EXTENSION Ground_RTL SysCoRTL.xml@SysUTM.xml Ground_UTM
else
    mm3d Campari .*$EXTENSION Ground_Init_RTL Ground_RTL EmGPS=[RAWGNSS_N,1] AllFree=1 SH=_mini | tee | tee GnssBundle.txt
    mm3d ChgSysCo  .*$EXTENSION Ground_RTL RTLFromExif.xml@SysUTM.xml Ground_UTM
    mm3d OriExport Ori-Ground_UTM/.*xml CameraPositionsUTM.txt AddF=1
fi


mm3d AperiCloud .*$EXTENSION Ground_UTM SH=_mini
