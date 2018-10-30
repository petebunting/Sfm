.. -*- mode: rst -*-

Structure from Motion workflows
============

A series of python and shell scripts for processing data from drones, originally for the the C-Astral Bramour PPX platform


Dependencies
~~~~~~~~~~~~

Sfm requires:

- GNU/Linux or Mac OS only 

- Python 3

- MicMac


https://micmac.ensg.eu/index.php/Accueil

User installation
~~~~~~~~~~~~~~~~~

See MicMac install instructions here:

https://micmac.ensg.eu/index.php/Install

Install my fork of pymicmac which has bits modified for the gpymicmac script

- Install pycoeman dependencies 
.. code-block:: bash

   sudo apt-get install libfreetype6-dev libssl-dev libffi-dev
   
- Install pycoeman
.. code-block:: bash

    pip install git+https://github.com/NLeSC/pycoeman
    
- Install noodles

.. code-block:: bash

    pip install git+https://github.com/NLeSC/noodles
    
-  Install pymicmac

.. code-block:: bash

    pip install git+https://github.com/Ciaran1981/pymicmac

Clone or download then make the folder or files executable in a terminal

.. code-block:: bash
   
   chmod +x PPX.sh

Add to your .bashrc or .bash_profile if you wish to execute anywhere


Contents
~~~~~~~~~~~~~~~~~

**PPX.sh**

- A script to process a GNSS and associated photographs outputting orthomosaic, DSM and point cloud (.ply) file
Will process anything with a csv GNSS (in the correct format) and photos. This uses Malt for dense matching

**Drone.sh**

- A script to process photographs with complete exif information outputting orthomosaic, DSM and point cloud (.ply) file
Typically a DJI phantom or other such platform. This uses Malt for dense matching

**DronePIMs.sh**

- A script like the 2 previous but using the PIMs algorithm

**write_tiles.py**

- A python script using GDAL which writes the georeferencing information to Tawny mosaic tiled output

**tie.sh**

- Part one of a 2 stage process for PPX-based Sfm, the output includes the delay between GNSS and camera which can be inputted into the sequel script dense_cloud.sh

**dense_cloud.sh**

- Part two of aformentioned workflow where the GNSS - camera delay is inputted prior to the output of Ortho, DSM and point cloud. 

**gpymicmac.sh**

- Using a modification of pymicmac functionallity, this script subdivides large datasets into a grid of overlapping tiles and processes either in parallel or sequentially

**pims_subset.py**

- Similar to gpymicmac, this processes data using the PIMs dense matching with the facility to control the amount of image pairs processed at any one time
- This has been written to expolit GPU processing, but it is probably quicker to use CPU processing overall with larger datsets
- This scripts calls the MicMac PIMs function in chunks to ensure GPU memory is not overloaded
- Tends to overload 11gb GPU with around 30 images+
- This takes advantage of the fact it all gets written to the PIMs folder without overwrite

Use
~~~~~~~~~~~~~~~~~

type -h to get help on each script e.g. :

.. code-block:: bash

   PPX.sh

Thanks
~~~~~~~~~~~~~~~~~

Thanks to devs and contributors at MicMac and it's forum, particularly L.Girod whose work forms the basis of the workflow scripts here
