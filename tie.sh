#!/bin/bash


EXTENSION=JPG 
CSV=*.csv 
 
utm_set=false 
use_Schnaps=true
resol_set=true

while getopts "e:csv:u:r:s:h" opt; do
  case $opt in
    h)
      echo "Run the workflow for drone acquisition at nadir (and pseudo nadir) angles)."
      echo "usage: PPXNadir.sh -u \"32 +north\" -p true -r 0.05"
      echo "	-csv CSV         : csv of image coords"
      echo "	-u UTMZONE       : UTM Zone of area of interest. Takes form 'NN +north(south)'"
      echo "	-r RESOL         : the resize on images to use for Tapioca."
      echo "	-s SH            : Do not use 'Schnaps' optimised homologous points."
      echo "	-h	             : displays this message and exits."
      echo " " 
      exit 0
      ;;    
	e)
      EXTENSION=$OPTARG
      ;;    
	csv)
      CSV=$OPTARG
      ;;
	u)
      UTM=$OPTARG
      utm_set=true
      ;;  
	r)
      RESOL=$OPTARG
      resol_set=true
      ;; 
	s)
      use_Schnaps=false
      ;;   	
    \?)
      echo "PPXtie.sh: Invalid option: -$OPTARG" >&1
      exit 1
      ;;
    :)
      echo "PPXtie.sh: Option -$OPTARG requires an argument." >&1
      exit 1
      ;;
  esac
done

if [ "$utm_set" = false ]; then
	echo "UTM zone not set" 
	exit 1
fi
if [ "$use_schnaps" = true ]; then
	echo "Using Schnaps!"
	SH="_mini"
else
	echo "Not using Schnaps!"
	SH=""
fi

# Create the proj 4 xml 
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

mm3d OriConvert OriTxtInFile $CSV Nav-Brut-RTL ChSys=DegreeWGS84@SysCoRTL.xml MTD1=1  NameCple=FileImagesNeighbour.xml CalcV=1;



mm3d Tapioca File FileImagesNeighbour.xml $RESOL
if [ "$use_schnaps" = true ]; then
	# filter TiePoints  
	mm3d Schnaps .*$EXTENSION MoveBadImgs=1
fi

mm3d Tapas FraserBasic ".*JPG" Out=All-Rel SH=_mini

mm3d AperiCloud ".*JPG" All-Rel;
 

# Next calculate the movement during camera execution to edit the cloud in next command
# this is for lever arm compensation
# TODO - require automatic extraction of stdout figure

mm3d CenterBascule ".*JPG" All-Rel Nav-Brut-RTL tmp CalcV=1;

echo "Enter the last output figure into the dense_cloud script to adjust for GNSS - camera delay"

