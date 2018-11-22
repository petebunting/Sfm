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

I have found it is best to install MicMac wthout the GPU as my main install and add it to the path 

Then I install a separate micmac with GPU support and add it as a variable in shell scripts or the absoulute path when needed

Install my fork of pymicmac which has bits modified for creating tiles

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
   
   chmod +x Drone.sh

Add to your .bashrc or .bash_profile if you wish to execute anywhere


Contents
~~~~~~~~~~~~~~~~~

**Drone.sh**

- A script to process photographs with complete exif information outputting orthomosaic, DSM and point cloud (.ply) file
Typically a DJI phantom or other such platform. This uses Malt for dense matching

**DronePIMs.sh**

- A script like the previous but using the PIMs algorithm

**gridproc.sh**

- Process a large dataset in tiles (this appears to be best for large ortho-mosaics)

**pims_subset.py**

- Similar to gpymicmac, this processes data in tiles/chunks using the PIMs algorithm, where GPU support is optional

Use
~~~~~~~~~~~~~~~~~

type -h to get help on each script e.g. :

.. code-block:: bash

   Drone.sh -help

Thanks
~~~~~~~~~~~~~~~~~

Thanks to devs and contributors at MicMac and it's forum, particularly L.Girod whose work inspired the basis of the shell scripts and pymicmac from which the tiling function was derived
