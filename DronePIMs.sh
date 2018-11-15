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
resol_set=false
ZoomF=2  
DEQ=1
gpu=0
Algorithm=MicMac  
zreg=0.02
size=none 
prc=100
gpu=none
CSV=none
 
while getopts "e:a:csv:x:y:u:sz:spao:r:z:eq:g:proc:zr:h" opt; do
  case $opt in
    h) 
      echo "Run the workflow for drone acquisition at nadir (and pseudo nadir) angles)."
      echo "usage: DronePIMs.sh -e JPG -a MicMac -u 30 +north -r 0.1"
      echo "	-e EXTENSION     : image file type (JPG, jpg, TIF, png..., default=JPG)."
      echo "	-a Algorithm     : type of algo eg BigMac, MicMac, Forest, Statue etc"
      echo "	-csv CSV         : Whether to use a csv file."
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
      echo " -proc            : no chunks to split the data into for gpu processing"
      echo " -zr              : zreg term - context dependent - def is 0.02" 
      echo "	-h	             : displays this message and exits."
      echo " "
      exit 0 
      ;;    
	e)   
      EXTENSION=$OPTARG 
      ;;
    a)
      Algorithm=$OPTARG
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
      gpu=$OPTARG 
      ;; 
    proc)
      prc=$OPTARG
      ;; 
    zr)
      zreg=$OPTARG
      ;;
    \?)
      echo "DronePIMs.sh: Invalid option: -$OPTARG" >&1
      exit 1
      ;;
    :)
      echo "DronePIMs.sh: Option -$OPTARG requires an argument." >&1
      exit 1
      ;;
  esac
done
if [ "$utm_set" = false ]; then
	echo "UTM zone not set"
	exit 1
fi

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
      
 
#mm3d SetExif ."*JPG" F35=45 F=30 Cam=ILCE-6000  

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

mm3d Schnaps .*$EXTENSION MoveBadImgs=1 VeryStrict=1


#Compute Relative orientation (Arbitrary system)
mm3d Tapas Fraser .*$EXTENSION Out=Arbitrary SH=_mini

#Visualize relative orientation, if apericloud is not working, run  

mm3d AperiCloud .*$EXTENSION Arbitrary  
	
mm3d CenterBascule .*$EXTENSION Arbitrary RAWGNSS_N Ground_Init_RTL

# Either this or the next stage is ruining stuff

   
#Visualize Ground_RTL orientation   


   
#  
#Change system to final cartographic system  
if [ $CSV != none ]; then 
    mm3d Campari .*$EXTENSION Ground_Init_RTL Ground_UTM EmGPS=[RAWGNSS_N,1] AllFree=1 SH=_mini
    # For reasons unknown this screws it up from csv
    #mm3d ChgSysCo  .*$EXTENSION Ground_RTL SysCoRTL.xml@SysUTM.xml Ground_UTM
else
    mm3d Campari .*$EXTENSION Ground_Init_RTL Ground_RTL EmGPS=[RAWGNSS_N,1] AllFree=1 SH=_mini
    mm3d ChgSysCo  .*$EXTENSION Ground_RTL RTLFromExif.xml@SysUTM.xml Ground_UTM
    mm3d OriExport Ori-Ground_UTM/.*xml CameraPositionsUTM.txt AddF=1
fi
#Print out a text file with the camera positions (for use in external software, e.g. GIS)

 

# Important NOTE
 
 

if [ "$gpu" != none ]; then

    # The only thing I wonder here is whether it is worth building the whole 'master'
    # PIMs folder and simply moving the Ortho part for later (this still involves
    # repetition of the PIMs2Mnt though
    pims_subset.py -folder $PWD -algo $Algorithm -num $prc
    mkdir OUTPUT    

    #mm3d ConvertIm PIMs-ORTHO/Orthophotomosaic.tif Out=OUTPUT/OrthFinal.tif
    #cp PIMs-ORTHO/Orthophotomosaic.tfw OUTPUT/OrthFinal.tfw
    cd PIMsBatch
    for f in *list*/*PIMs-ORTHO/*Orthophotomosaic*.tif; do 
        gdal_edit.py -a_srs "+proj=utm +zone=$UTM  +ellps=WGS84 +datum=WGS84 +units=m +no_defs" "$f"; done
    
    find *list*/*PIMs-ORTHO/*Orthophotomosaic*.tif | parallel "ossim-create-histo -i {}"
    
    ossim-orthoigen --combiner-type ossimFeatherMosaic *list*/*PIMs-ORTHO/*Orthophotomosaic*.tif feather.tif

 
    # need if else for this  
    #mm3d ConvertIm PIMs-TmpBasc/PIMs-Merged_Prof.tif Out=OUTPUT/DSM.tif

    #cp PIMs-TmpBasc/PIMs-Merged_Prof.tfw OUTPUT/DSM.tfw
    #cp PIMs-TmpBasc/PIMs-Merged_Prof.tif OUTPUT/DSM.tif
    #cp PIMs-TmpBasc/PIMs-Merged_Masq.tif OUTPUT/Mask.tif
    #cp PIMs-TmpBasc/PIMs-Merged_Prof.tfw OUTPUT/Mask.tfw

    #gdal_edit.py -a_srs "+proj=utm +zone=$UTM  +ellps=WGS84 +datum=WGS84 +units=m +no_defs" DSM.tif
    #gdal_edit.py -a_srs "+proj=utm +zone=$UTM  +ellps=WGS84 +datum=WGS84 +units=m +no_defs" Mask.tif

    #mask_dsm.py -folder $PWD -pims 1 
else
    mm3d PIMs $Algorithm .*$EXTENSION Ground_UTM DefCor=0 SzW=1 ZoomF=$ZoomF ZReg=$zreg SH=_mini  
fi 
 


mm3d Pims2MNT $Algorithm ZReg=$zreg
 
 

#source deactivate pymicmac;
#if [ "$DEQ" != none ]; then 
#	mm3d Tawny Ortho-MEC-Malt DEq=$DEQ
#else
##	mm3d Tawny Ortho-MEC-Malt DEq=1
#fi

# When images are large they will be tiled 

mm3d Tawny PIMs-ORTHO/ RadiomEgal=1 Out=Orthophotomosaic.tif

#Making OUTPUT folder
mkdir OUTPUT

mm3d ConvertIm PIMs-ORTHO/Orthophotomosaic.tif Out=OUTPUT/OrthFinal.tif
cp PIMs-ORTHO/Orthophotomosaic.tfw OUTPUT/OrthFinal.tfw
gdal_edit.py -a_srs "+proj=utm +zone=$UTM  +ellps=WGS84 +datum=WGS84 +units=m +no_defs" OUTPUT/OrthFinal.tif

 
# need if else for this 
#mm3d ConvertIm PIMs-TmpBasc/PIMs-Merged_Prof.tif Out=OUTPUT/DSM.tif

cp PIMs-TmpBasc/PIMs-Merged_Prof.tfw OUTPUT/DSM.tfw
cp PIMs-TmpBasc/PIMs-Merged_Prof.tif OUTPUT/DSM.tif
cp PIMs-TmpBasc/PIMs-Merged_Masq.tif OUTPUT/Mask.tif
cp PIMs-TmpBasc/PIMs-Merged_Prof.tfw OUTPUT/Mask.tfw

gdal_edit.py -a_srs "+proj=utm +zone=$UTM  +ellps=WGS84 +datum=WGS84 +units=m +no_defs" DSM.tif
gdal_edit.py -a_srs "+proj=utm +zone=$UTM  +ellps=WGS84 +datum=WGS84 +units=m +no_defs" Mask.tif

mask_dsm.py -folder $PWD -pims 1 

# OSSIM - BASED MOSAICING ----------------------------------------------------------------------------
# Just here as an alternative for putting together tiles 
# This need GNU parallel
 
#for f in PIMs-ORTHO/*Ort_**.tif; 
#do      
# gdal_edit.py -a_srs "+proj=utm +zone=30 +north +ellps=WGS84 +datum=WGS84 +units=m +no_defs" "$f"; 
#done

 
# Create some image histograms for ossim  
#
#find PIMs-ORTHO/*Ort**.tif | parallel "ossim-create-histo -i {}" 
 

#ossim-orthoigen --combiner-type ossimMaxMosaic PIMs-ORTHO/**Ort**.tif OUTPUT/max.tif
# Or more options

#choices
#ossimBlendMosaic ossimMaxMosaic ossimImageMosaic ossimClosestToCenterCombiner ossimBandMergeSource ossimFeatherMosaic 



