# This is a generic workflow for UAV platforms etc with embedded GNSS data
# # Author Ciaran Robb
# Aberystwyth University


#https://github.com/Ciaran1981/Sfm

# example:
# ./DronePIMs.sh -e JPG -a Forest -u "30 +north" -t mycsv.csv -z = 0.03 -x 1 -p 2,2

# Important NOTE - MicMac CPU based is FAR quicker than using the GPU,
#  as it's memory management limits GPU processing to small chunks
 
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
Algorithm=Forest  
zreg=0.01
size=none 
prc=3,3
gpu_set=false
tile_set=false
csv_set=false
CSV=0
match=none
EG=0
 
while getopts ":e:a:m:c:x:y:u:s:p:z:e:d:g:p:z:t:h" opt; do
  case $opt in
    h)  
      echo "Run the workflow for drone acquisition at nadir (and pseudo nadir) angles)."
      echo "usage: DronePIMs.sh -e JPG -a MicMac -u 30 +north -r 0.1"
      echo "	-e EXTENSION     : image file type (JPG, jpg, TIF, png..., default=JPG)."
      echo "	-a Algorithm     : type of algo eg BigMac, MicMac, Forest, Statue etc"
      echo "	-m match         : exaustive matching" 
      echo "	-c CSV         : Whether to use a csv file."
      echo "	-x X_OFF         : X (easting) offset for ply file overflow issue (default=0)."
      echo "	-y Y_OFF         : Y (northing) offset for ply file overflow issue (default=0)."
      echo "	-u UTMZONE       : UTM Zone of area of interest. Takes form 'NN +north(south)'"
      echo "	-s size         : resize of imagery eg - 2000"
      echo "	-r RESOL         : Ground resolution (in meters)"
      echo "	-z ZoomF         : Last step in pyramidal dense correlation (default=2, can be in [8,4,2,1])"
      echo "	-d DEQ          : Degree of equalisation between images during mosaicing (See mm3d Tawny)"
      echo " -g gpu           : Whether to use GPU support, default false"
      echo " -p            : no chunks to split the data into for gpu processing"
      echo " -z              : zreg term - context dependent - def is 0.02" 
      echo "	-h	             : displays this message and exits."
      echo " "
      exit 0 
      ;;    
	e)   
      EXTENSION=${OPTARG} 
      ;;
    a)
      Algorithm=${OPTARG}
      ;;
    c)
      CSV=${OPTARG}
      ;;    
	u)
      UTM=${OPTARG}

      ;;
 	s)
      size=${OPTARG} 
      ;;        
	z)
      ZoomF=${OPTARG}
      ;;
	d)
      DEQ=${OPTARG}  
      ;;
	g)
      gpu=${OPTARG}
      ;; 
    p)
      prc=${OPTARG}
      ;; 
    z)
      zreg=${OPTARG}
      ;;
    t)
      tile=${OPTARG}
      ;;
    \?)
      echo "DronePIMs.sh: Invalid option: -${OPTARG}" >&1
      exit 1
      ;;
    :)
      echo "DronePIMs.sh: Option -${OPTARG} requires an argument." >&1
      exit 1
      ;;
  esac
done


 
echo "Using $Algorithm algorithm for PIMs dense matching"  

#create UTM file (after deleting any existing one)
if [  -n "${CSV}" ]; then 
    Orientation.sh -e JPG -u ${UTMZONE} -c Fraser -s ${size} -t ${CSV}
else
    Orientation.sh -e JPG -u ${UTMZONE} -c Fraser -s ${size}
#Print out a text file with the camera positions (for use in external software, e.g. GIS)
 
 
if [ -n "${tile}" ]; then
    
    if [ "$gpu_set" = true ]; then
    
        # The only thing I wonder here is whether it is worth building the whole 'master'
         # PIMs folder and simply moving the Ortho part for later (this still involves
        # repetition of the PIMs2Mnt though
        PimsBatch.py -folder $PWD -algo ${Algorithm} -num ${prc} -zr ${zreg} -g 1
        mkdir OUTPUT    
    
        #mm3d ConvertIm PIMs-ORTHO/Orthophotomosaic.tif Out=OUTPUT/OrthFinal.tif
        #cp PIMs-ORTHO/Orthophotomosaic.tfw OUTPUT/OrthFinal.tfw
        
        # Process the DSM--------------------------------------------
        for f in PIMsBatch/*tile*/PIMs-TmpBasc/PIMs-Merged_Prof.tif; do 
            gdal_edit.py -a_srs "+proj=utm +zone=$UTM  +ellps=WGS84 +datum=WGS84 +units=m +no_defs" "$f"; done
        
        for f in PIMsBatch/*tile*/PIMs-TmpBasc/PIMs-Merged_Masq.tif; do 
            gdal_edit.py -a_srs "+proj=utm +zone=$UTM  +ellps=WGS84 +datum=WGS84 +units=m +no_defs" "$f"; done
         
        mask_dsm.py -folder $PWD -pims True 
        
        find PIMsBatch/*tile*/PIMs-TmpBasc/PIMs-Merged_Prof.tif | parallel "ossim-create-histo -i {}"      
        
        ossim-orthoigen --combiner-type ossimMaxMosaic PIMsBatch/*tile*/PIMs-TmpBasc/PIMs-Merged_Prof.tif  PIMsBatch/DSM_final.tif
        #ossim-orthoigen --combiner-type ossimFeatherMosaic PIMsBatch/*tile*/PIMs-TmpBasc/PIMs-Merged_Prof.tif  PIMsBatch/DSM_final_feather.tif
         
        # Process the Ortho-------------------------------------------- 
        # Probably better to use Malt-Batch for this as it is MVS which works better for ortho
        for f in PIMsBatch/*list*/*PIMs-TmpMnt/*Orthophotomosaic*.tif; do 
            gdal_edit.py -a_srs "+proj=utm +zone=$UTM  +ellps=WGS84 +datum=WGS84 +units=m +no_defs" "$f"; done
        
        find PIMsBatch/*tile*/*PIMs-TmpMnt/*Orthophotomosaic*.tif | parallel "ossim-create-histo -i {}"
        
        ossim-orthoigen --combiner-type ossimMaxMosaic PIMsBatch/*tile*/*PIMs-TmpMnt/*Orthophotomosaic*.tif PIMsBatch/Max.tif
                
        echo 'Everything done - take a look!' 
        return
    
        #mask_dsm.py -folder $PWD -pims 1 
    else 
        PimsBatch.py -folder $PWD -algo $Algorithm -num $prc -zr $zreg 
        
        # Process the DSM-------------------------------------------- 
    
        for f in PIMsBatch/*tile*/PIMs-TmpBasc/PIMs-Merged_Prof.tif; do 
            gdal_edit.py -a_srs "+proj=utm +zone=$UTM  +ellps=WGS84 +datum=WGS84 +units=m +no_defs" "$f"; done
            
        for f in PIMsBatch/*tile*/PIMs-TmpBasc/PIMs-Merged_Masq.tif; do 
            gdal_edit.py -a_srs "+proj=utm +zone=$UTM  +ellps=WGS84 +datum=WGS84 +units=m +no_defs" "$f"; done
        
        mask_dsm.py -folder $PWD -pims True
         
        find PIMsBatch/*tile*/PIMs-TmpBasc/PIMs-Merged_Prof.tif | parallel "ossim-create-histo -i {}"      
        
        ossim-orthoigen --combiner-type ossimMaxMosaic PIMsBatch/*tile*/PIMs-TmpBasc/PIMs-Merged_Prof.tif  PIMsBatch/DSM_final.tif
        # Process the Ortho-------------------------------------------- 
        # Probably better to use Malt-Batch for this as it is MVS which works better for ortho
        
        for f in PIMsBatch/*list*/*PIMs-ORTHO/*Orthophotomosaic*.tif; do 
            gdal_edit.py -a_srs "+proj=utm +zone=$UTM  +ellps=WGS84 +datum=WGS84 +units=m +no_defs" "$f"; done
        
        find PIMsBatch/*tile*/*PIMs-ORTHO/*Orthophotomosaic*.tif | parallel "ossim-create-histo -i {}"
        
        ossim-orthoigen --combiner-type ossimFeatherMosaic PIMsBatch/*tile*/*PIMs-ORTHO/*Orthophotomosaic*.tif PIMsBatch/feather.tif
        
        echo 'Everything done - take a look!' 
       return
    fi
else

    mm3d PIMs $Algorithm .*${EXTENSION} Ground_UTM DefCor=0 SzW=1 ZoomF=$ZoomF ZReg=$zreg SH=_mini  

    mm3d Pims2MNT $Algorithm ZReg=$zreg DoOrtho=1
	 

    mm3d Tawny PIMs-ORTHO/ RadiomEgal=0 Out=Orthophotomosaic.tif
    #TawnyBatch.py -folder $PWD -num 20,20 -nt -1


    mm3d ConvertIm PIMs-ORTHO/Orthophotomosaic.tif Out=OUTPUT/OrthFinal.tif
    cp PIMs-ORTHO/Orthophotomosaic.tfw OUTPUT/OrthFinal.tfw

    cp PIMs-TmpBasc/PIMs-Merged_Prof.tfw OUTPUT/DSM.tfw
    cp PIMs-TmpBasc/PIMs-Merged_Prof.tif OUTPUT/DSM.tif
    cp PIMs-TmpBasc/PIMs-Merged_Masq.tif OUTPUT/Mask.tif
    cp PIMs-TmpBasc/PIMs-Merged_Prof.tfw OUTPUT/Mask.tfw

    gdal_edit.py -a_srs "+proj=utm +zone=${UTM}  +ellps=WGS84 +datum=WGS84 +units=m +no_defs" DSM.tif
    gdal_edit.py -a_srs "+proj=utm +zone=${UTM}  +ellps=WGS84 +datum=WGS84 +units=m +no_defs" Mask.tif
   
    #for f in TawnyBatch/**Orthophotomosaic*.tif; do     
    gdal_edit.py -a_srs "+proj=utm +zone=$UTM +ellps=WGS84 +datum=WGS84 +units=m +no_defs" OUTPUT/OrthFinal.tif

 
    # Create some image histograms for ossim  
    #
    #find TawnyBatch/**Orthophotomosaic*.tif | parallel "ossim-create-histo -i {}" 
 

    #ossim-orthoigen --combiner-type ossimMaxMosaic TawnyBatch/**Orthophotomosaic*.tif OUTPUT/max.tif
fi 
    #mask_dsm.py -folder $PWD -pims 1 
    
    

#choices
#ossimBlendMosaic ossimMaxMosaic ossimImageMosaic ossimClosestToCenterCombiner ossimBandMergeSource ossimFeatherMosaic 



