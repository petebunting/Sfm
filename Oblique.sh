# This is for oblique imagery - a work in progress
# The main difference here is using the C3DC algorithm at the end of the process to produce a point cloud
# It has been written with testing things out in mind, with hefty datasets covered by the other scripts

# Author Ciaran Robb
# Based on a L.Girod script - credit to him!
# Aberystwyth University


# add default values
EXTENSION=JPG
Algorithm=Statue
wait_for_mask=true
ZOOM=2
dist=5
match=none
CSV=0
sz=none

while getopts "e:a:m:csv:u:sz:s:d:msk:z:h" opt; do
  case $opt in
    h)
      echo "Run workflow for point cloud from culture 3d algo."
      echo "usage: Oblique.sh -e JPG -a Statue -d 10 -u "30 +north" -z 1"
      echo "	-e EXTENSION   : image file type (JPG, jpg, TIF, png..., default=JPG)."
      echo "	-a Algorithm   : type of algo eg BigMac, MicMac, Forest, Statue etc."
      echo "	-m match         : exaustive matching" 
      echo "	-csv CSV         : Whether to use a csv file."
      echo "	-u UTM         : UTM zone."
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
    a)
      Algorithm=$OPTARG
      ;; 
    m)
      match=$OPTARG 
      ;;     
    csv)
      match=$OPTARG 
      ;;
	u)
      UTM=$OPTARG 
      ;; 
 	sz)
      size=$OPTARG 
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

 
#create UTM file (after deleting any existing one) Only required for csv option but hey
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

if [  "$CSV"=1  ]; then 

    echo "using csv file"
    cs=*.csv
    mm3d OriConvert OriTxtInFile $cs RAWGNSS_N ChSys=DegreeWGS84@SysUTM.xml MTD1=1 NameCple=FileImagesNeighbour.xml CalcV=1   
    sysCort_make.py -csv $cs 
else
    echo "using exif data"
    mm3d XifGps2Txt .*$EXTENSION
    #Get the GNSS data out of the images and convert it to a xml orientation folder (Ori-RAWGNSS), also create a good RTL (Local Radial Tangential) system.
    mm3d XifGps2Xml .*$EXTENSION RAWGNSS_N
    mm3d OriConvert "#F=N X Y Z" GpsCoordinatesFromExif.txt RAWGNSS_N ChSys=DegreeWGS84@RTLFromExif.xml MTD1=1 NameCple=FileImagesNeighbour.xml CalcV=1 DN=$dist
fi
#Use the GpsCoordinatesFromExif.txt file to create a xml orientation folder (Ori-RAWGNSS_N), and a file (FileImagesNeighbour.xml) detailing what image sees what other image (if camera is <50m away with option DN=50)

if [  "$size"!=none ]; then
    echo "resizing to $size for tie point detection"
    mogrify -resize $size *.JPG
    # mogrify -path Sharp -sharpen 0x3  *.JPG # this sharpens very well worth doing
else
    echo "using a default re-size of 2000 long axis on imgs"
    mogrify -resize 2000 *.JPG 
fi 

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


mm3d Schnaps .*$EXTENSION MoveBadImgs=1 

#Compute Relative orientation (Arbitrary system)
mm3d Tapas Fraser .*$EXTENSION Out=Arbitrary SH=_mini

# This lot screws it up when not all nadir!!!! 
#Transform to  RTL system
mm3d CenterBascule .*$EXTENSION Arbitrary RAWGNSS_N Ground_Init_RTL

#Change system to final cartographic system  

 
mm3d Campari .*$EXTENSION Ground_Init_RTL Ground_RTL EmGPS=[RAWGNSS_N,1] AllFree=1 SH=_mini 

mm3d AperiCloud .*$EXTENSION Arbitrary WithCam=0 SH=_mini Out=Arbitrary.ply
mm3d AperiCloud .*$EXTENSION Ground_RTL SH=_mini Out=withcams.ply

mm3d AperiCloud .*$EXTENSION Ground_RTL  WithCam=0 SH=_mini

  
#HERE, MASKING COULD BE DONE!!!
if [ "$wait_for_mask" = true ]; then
    mm3d SaisieMasqQT Arbitrary.ply
	read -rsp $'Press any key to continue...\n' -n1 key
fi 
	
#Do the correlation of the images

mm3d C3DC $Algorithm .*$EXTENSION Arbitrary ZoomF=$ZOOM Masq3D=Arbitrary_polyg3d.xml Out=Dense.ply

mm3d TiPunch Dense.ply Mode=$Algorithm Out=MeshOot.ply Pattern=.*$EXTENSION

mm3d Tequila .*$EXTENSION Forest MeshOot.ply Filter=1