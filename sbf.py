#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Jul 20 14:52:16 2018

@author: ciaran
"""

import matplotlib.pyplot as plt
import numpy as np
import pysbf as sbf
    
with open('rover_20180719_104538.sbf') as sbf_fobj:
 cpuload = ( '{} {}\n'.format(b['TOW'], b['CPULoad']) for bn, b in sbf.load(sbf_fobj, 100, {'ReceiverStatus_v2'}) )
 data = np.loadtxt(cpuload)
 plt.xlabel('Time (ms)')
 plt.ylabel('CPU Load (%)')
 plt.plot(data[:,0], data[:,1])
 plt.show()
 
with open('rover_20180719_104538.sbf') as sbf_fobj:
 for blockName, block in sbf.load(sbf_fobj, limit=100, blocknames={'SatVisibility'}):
  for satInfo in block['SatInfo']:
   print(satInfo['SVID'], satInfo['Azimuth'], satInfo['Elevation'])