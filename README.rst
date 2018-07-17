.. -*- mode: rst -*-

Structure from Motion workflows
============

A series of python and shell scripts for processing data from the C-Astral Bramour PPX platform


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

Clone or download then make the folder or files executable in a terminal

.. code-block:: bash
   
   chmod +x PPXNadir.sh

Add to your .bashrc or .bash_profile if you wish to execute anywhere


Contents
~~~~~~~~~~~~~~~~~

PPXNadir.sh

- A script to process a GNSS and associated photographs outputting orthomosaic, DSM and point cloud (.ply) file

**DroneNadir.sh**

- A script to process photographs with complete exif information outputting orthomosaic, DSM and point cloud (.ply) file
Typically a DJI phantom or other such platform

**write_tiles.py**

- A python script using GDAL which writes the georeferencing information to Tawny mosaic tiled output

**tie.sh**

- Part one of a 2 stage process for PPX-based Sfm, the output includes the delay between GNSS and camera which can be inputted into the sequel script dense_cloud.sh

**dense_cloud.sh**

- Part two of aformentioned workflow where the GNSS - camera delay is inputted prior to the output of Ortho, DSM and point cloud. 


Use
~~~~~~~~~~~~~~~~~

type -h to get help on each script e.g. :

.. code-block:: bash

   PPXNadir.sh

Thanks
~~~~~~~~~~~~~~~~~

Thanks to devs and contributors at MicMac and it's forum, particularly L.Girod whose work forms the basis of the workflow scripts here
