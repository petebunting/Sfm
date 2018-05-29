#!/bin/bash




# IMPORTAMT--------------------------------------------------------------------
# Very memory hungry!!! On a 64gb ram machine, I am rinsing the RAM with 8 cores
# and chunks of 10 images!!!
# Shame cos there 32 available, but you need A LOT OF RAM to parallelise this 
# effectively locally
# One work around is to reduce the imagery input size
# (eg to half the current or there), but then you risk poorer per image 
# feature matching
# The other is to distribute over lots of machines which complicates things
# slightly more!
#------------------------------------------------------------------------------
# Some test settings that worked
# Used 30% memory so about 5gb per chunk (though this may not increase in 
# linear manner)
# micmac-disttapioca-create-config -i FileImagesNeighbour.xml -o DistributedTapioca.xml -f ChunksData -n 10
# coeman-par-local -d . -c DistributedTapioca.xml -e DTap -n 4
# increaing -n to 6 used ~75% memory at peak - perhaps this is about the limit then...

# Create the chunks
micmac-disttapioca-create-config -i FileImagesNeighbour.xml -o DistributedTapioca.xml -f ChunksData -n 50

# Execute the para cmd
coeman-par-local -d . -c DistributedTapioca.xml -e DTap -n 20

# have done a 2k resize one
# Using 16 cores maxs RAM out just
# micmac-disttapioca-create-config -i FileImagesNeighbour.xml -o DistributedTapioca.xml -f ChunksData -n 30
# coeman-par-local -d . -c DistributedTapioca_2k.xml -e DTap2k -n 12

#Distributed Tapiaoca results (plot in figures folder on storage1)
#
#Chunks of 50 images processed on 20 cores (resized to 1000)
#
#Elapsed time: 7200.0 120 minutes 
#Avg. CPU: 2545.16
#Avg. MEM [GB]: 6.04
#Number used hosts: 1
#Avail. CPU: 3200.00 (32 threads)
#Avail. MEM [GB]: 62.84


# Combine to a single Homol folder
micmac-disttapioca-combine -i DTap -o Homol

# Plot the CPU usage
coeman-mon-plot-cpu-mem -i DistributedTapiocaAllOutputs -r 20

# Reduce the tie points with micmac Schnapps the output folder is 'mini' by default

mm3d Schnaps ".*JPG" 

# -help for args, the website api is out of date

# handy args:  #HomolOut=mini MoveBadImgs=True OutTrash=where the bad shit goes
# Schnaps_poubelle.txt has the list of potentially dodgy 


# Calculate relative Orientations


#mm3d Tapas Fraser ".*JPG" Out=All-Rel
# OR
# Hence the use of Schnapps and explicit Homol_mini 
mm3d Tapas Fraser ".*JPG" Out=All-Rel SH=_mini

# At this point I'm unclear as to whether this will work parallel as I favour
# the new commands

mm3d CenterBascule .*JPG All-Rel Nav-Brut-RTL tmp CalcV=1

mm3d OriConvert OriTxtInFile boats.csv Nav-adjusted-RTL  MTD1=1 Delay=0.0464031

# Now for distributed matching - this is tiling the output mind!

#micmac-distmatching-create-config -i Ori-GCPBOut -e JPG -o DistributedMatching.xml -f DMatch -n 60,60


#coeman-par-local -d . -c DistributedMatching.xml -e DMatch -n 20

# RECOMMENDED
# Use the newer MicMac functions PIMs and Pims2MNT----------------------------------------------
# Check out the micmac site for mandatory and named args

mm3d Pims MicMac ".*JPG" All-RTL;

# DEM (PIMs-Merged_Prof.tif) is produced in the  PIMS-Tmp-Basc folder 
mm3d Pims2MNT MicMac DoOrtho=1;

# MICMAC - based mosaicing 
# RadiomEgal=1 means match the image hists or whatever

Tawny PIMs-ORTHO/ RadiomEgal=1 Out=Orthophotomosaic.tif

# VODKA cmd get rid of vignetting TODO

#-----------------------------------------------------------------------------------------------------

# Create a dense coloured point cloud
mm3d Nuage2Ply PIMs-TmpBasc/PIMs-Merged.xml Attr=PIMs-ORTHO/Orthophotomosaic.tif Out=pointcloud.ply;
