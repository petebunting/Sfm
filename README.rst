.. -*- mode: rst -*-

Structure from Motion workflows
============

A series of python and shell scripts for processing data from drones, originally for the the C-Astral Bramour PPX platform


Dependencies
~~~~~~~~~~~~

Sfm requires:

- GNU/Linux or Mac OS for full functionality (python scripts are not platform dependent)

- Python 3

- MicMac

- OSSIM


https://micmac.ensg.eu/index.php/Accueil

User installation
~~~~~~~~~~~~~~~~~

**MicMac**

See MicMac install instructions here:

https://micmac.ensg.eu/index.php/Install

- I have found it is best to install MicMac wthout the GPU as my main install and add it to the path 

- Then I install a separate micmac with GPU support and add it as a variable in shell scripts or the absoulute path when needed

With reference to GPU supported compilation specifically, the following may help:

- Replace the GpGpu.cmake file with the one supplied here as I have added the later Pascal 6.1 architecture

- Make sure you install and use an older gcc compiler such as 5 or 6 for the cmake bit

- Replace k with no of threads 

.. code-block:: bash
    
    cmake -DWITH_OPEN_MP=OFF
          -DCMAKE_C_COMPILER=/usr/bin/gcc-5
          -DCMAKE_CXX_COMPILER=/usr/bin/g++-5
          -DCUDA_ENABLED=1
          -DCUDA_SDK_ROOT_DIR=/path/to/NVIDIA_CUDA-9.2_Samples/common 
          -DCUDA_SAMPLE_DIR=/path/to/NVIDIA_CUDA-9.2_Samples 
          -DCUDA_CPP11THREAD_NOBOOSTTHREAD=ON ..

    make install -j k

**OSSIM**

Install OSSIM via tha ubuntu GIS or equivalent repo 

- Ensure the OSSIM preferences file is on you path, otherwise it will not recognise different projections

- see here https://trac.osgeo.org/ossim/wiki/ossimPreferenceFile

**The scripts**
Clone or download then make the folder or files executable in a terminal

.. code-block:: bash
   
   chmod +x Sfm/*.sh Sfm/*.py 

Add to your .bashrc or .bash_profile if you wish to execute anywhere


**QGIS plugin**

To enable use of MicMac and scripts for those who fear the command line...

This is just a front-end for the native MicMac QT menus at present. The scaled versions that utilise the script functionality are not done as yet, but will be added in due course. 

NOT FINISHED!!! Please wait until I upload to the repo.....

... Unles you wish to manually paste it into your plugin folder and alter the mm3d variable to your own micmac bin path

Contents
~~~~~~~~~~~~~~~~~

**Drone.sh**

- A script to process photographs with complete exif information outputting orthomosaic, DSM and point cloud (.ply) file
Typically a DJI phantom or other such platform. This uses Malt for dense matching

**gridproc.sh**

- Process a large dataset (typically 100s-1000s of images) in tiles (this appears to be best for large ortho-mosaics)

**MaltBatch.py**

- This processes data in tiles/chunks using the Malt algorithm, where GPU support is optional

- It is internal to gridproc

**DronePIMs.sh**

- A script like the previous but using the PIMs algorithm

**PimsBatch.py**

- This processes data in tiles/chunks using the PIMs algorithm, where GPU support is optional

- this script is an internal option in DronePIMs.sh

**TawnyBatch.py - DO NOT USE -NOT FINISHED**

- This will process mosaic data in tiles/chunks in preparation for using ossim for a near-seamless mosaic

- this script is an internal option in DronePIMs.sh

**MicMac-LocalChantierDescripteur.xml**
- This is a local descriptor of the camera in the C-Astral Bramor - alter the params for your own camera

The folder ContrastEnhanceChant includes parameters to high pass imagery internally prior to key points (SIFT)

It does not permanently alter the images - but this is possible (look up MicMac docs)



Use
~~~~~~~~~~~~~~~~~

type -h to get help on each script e.g. :

.. code-block:: bash

   Drone.sh -help

Thanks
~~~~~~~~~~~~~~~~~

Thanks to devs and contributors at MicMac and it's forum, particularly L.Girod whose work inspired the basis of the shell scripts and pymicmac from which the tiling function was derived
