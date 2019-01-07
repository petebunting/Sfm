# This is for oblique imagery - a work in progress

# Author Ciaran Robb
# Little changed form L.Girod - credit to him!
# Aberystwyth University


# add default values
EXTENSION=JPG
Algorithm=Statue
wait_for_mask=true
ZOOM=2
dist=5
match=none

while getopts "e:a:m:s:d:msk:z:h" opt; do
  case $opt in
    h)
      echo "Run workflow for point cloud from culture 3d algo."
      echo "usage: Oblique.sh -e JPG -a Statue -d 10 -z 1"
      echo "	-e EXTENSION   : image file type (JPG, jpg, TIF, png..., default=JPG)."
      echo "	-a Algorithm   : type of algo eg BigMac, MicMac, Forest, Statue etc."
      echo "	-m match         : exaustive matching" 
      echo "	-s             : Do not use 'Schnaps' optimised homologous points (does by default)."
      echo "	-d             : distance between photos for image pairs"
      echo "	-msk             : Pause for Mask before correlation (does not by default)."
      echo "	-z ZOOM        : Zoom Level (default=2)"
      echo "	-h	  : displays this message and exits."
      echo " "
      exit 0
      ;;   
	e)
      EXTENSION=$OPTARG
      ;;
  algo)
      Algorithm=$OPTARG
      ;; 
    m)
      match=$OPTARG 
      ;;     
	z)
      ZOOM=$OPTARG
      ;;
	s)
      use_Schnaps=true
      ;; 
	d)
      dist=$OPTARG
      ;; 
	msk)
      wait_for_mask=true
      ;;  
    \?)
      echo "Oblique.sh: Invalid option: -$OPTARG" >&1
      exit 1
      ;;
    :)
      echo "Oblique.sh: Option -$OPTARG requires an argument." >&1
      exit 1
      ;; 
  esac
done


echo "using exif data"
mm3d XifGps2Txt .*$EXTENSION
#Get the GNSS data out of the images and convert it to a xml orientation folder (Ori-RAWGNSS), also create a good RTL (Local Radial Tangential) system.
mm3d XifGps2Xml .*$EXTENSION RAWGNSS_N
mm3d OriConvert "#F=N X Y Z" GpsCoordinatesFromExif.txt RAWGNSS_N ChSys=DegreeWGS84@RTLFromExif.xml MTD1=1 NameCple=FileImagesNeighbour.xml CalcV=1 DN=$dist

#Use the GpsCoordinatesFromExif.txt file to create a xml orientation folder (Ori-RAWGNSS_N), and a file (FileImagesNeighbour.xml) detailing what image sees what other image (if camera is <50m away with option DN=50)


#Find Tie points using 1/2 resolution image (best value for RGB bayer sensor)
#if [  "$size" != none ]; then
#    echo "resizing to $size for tie point detection"
##    mm3d Tapioca File FileImagesNeighbour.xml -1 @SFS
#else
#    echo "using a default re-size of 2000 long axis on imgs"
mogrify -resize 2000 *.JPG 
#    mm3d Tapioca File FileImagesNeighbour.xml -1 @SFS
#fi 
#File FileImagesNeighbour.xml

# If the camera positions are all over the shop its better to use the ALL option
if [  "$match" != none ]; then
    echo "exaustive matching"
    mm3d Tapioca All ".*JPG" -1 @SFS
else
    mm3d Tapioca File FileImagesNeighbour.xml -1 @SFS
fi


#if [ "use_Schnaps" = true ]; then
mm3d Schnaps .*$EXTENSION MoveBadImgs=1 

    #Compute Relative orientation (Arbitrary system) 
mm3d Tapas Fraser .*$EXTENSION Out=Arbitrary SH=_mini
#else
 #   mm3d Tapas Fraser .*$EXTENSION Out=Arbitrary
#fi

# This lot screws it up when not all nadir!!!! 
#Transform to  RTL system
mm3d CenterBascule .*$EXTENSION Arbitrary RAWGNSS_N Ground_Init_RTL

#Change system to final cartographic system  
#if [ $CSV != none ]; then 
   # mm3d Campari .*$EXTENSION Ground_Init_RTL Ground_UTM EmGPS=[RAWGNSS,1] AllFree=1 SH=_mini
    # For reasons unknown this screws it up from csv
    #mm3d ChgSysCo  .*$EXTENSION Ground_RTL SysCoRTL.xml@SysUTM.xml Ground_UTM
#    mm3d AperiCloud .*$EXTENSION Ori-Ground_RTL SH=_mini

#else

mm3d Campari .*$EXTENSION Ground_Init_RTL Ground_RTL EmGPS=[RAWGNSS_N,1] AllFree=1 SH=_mini 

# This lot here assumes a geographic coordinate system which we do not have with SaisieMasq output

#mm3d ChgSysCo  .*$EXTENSION Ground_RTL RTLFromExif.xml@SysUTM.xml Ground_UTM
#mm3d OriExport Ori-Ground_UTM/.*xml CameraPositionsUTM.txt AddF=1
mm3d AperiCloud .*$EXTENSION Ground_RTL SH=_mini Out=withcams.ply

mm3d AperiCloud .*$EXTENSION Ground_RTL  WithCam=0 SH=_mini

  
#HERE, MASKING COULD BE DONE!!!
if [ "$wait_for_mask" = true ]; then
    mm3d SaisieMasqQT AperiCloud_Ground_RTL__mini.ply
	read -rsp $'Press any key to continue...\n' -n1 key
fi 
	
#Do the correlation of the images

mm3d C3DC $Algorithm .*$EXTENSION Arbitrary ZoomF=$ZOOM Masq3D=AperiCloud_Ground_RTL__mini_polyg3d.xml

