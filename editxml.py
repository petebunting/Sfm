#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Jan 29 13:46:08 2018

@author: ciaran
"""

import xml.etree.ElementTree as ET


fle = ('/media/ciaran/645CEC7C5CEC49FE/03032016_Llanbedr/'
       '100MSDCF/FileImagesNeighbour.xml')


tree = ET.parse(fle)  
root = tree.getroot()

#newRoot = ET.Element('SauvegardeNamedRel')
#tree2 = ET.ElementTree(root)

for elem in root:
    entry = elem.text
    entlist = entry.split()
    entlist.reverse()
    newent = ' '.join(entlist)
    cple = ET.Element("Cple")
    cple.text = newent
    root.append(elem)
    root.append(cple)



newFle = fle[:-4]+'edited.xml'
tree.write(newFle)


#for elem in root.iter('item'):  
#    elem.set('name2', 'newitem2')

#make a small subset for calibration or testing


weeRoot = ET.Element('SauvegardeNamedRel')
weetree = ET.ElementTree(root)

for index, elem in enumerate(root):
    entry = elem.text
    entlist = entry.split()
    entlist.reverse()
    newent = ' '.join(entlist)
    cple = ET.Element("Cple")
    cple.text = newent
    newRoot.append(elem)
    newRoot.append(cple)
    if index > 24:
        break


newFle = fle[:-4]+'editedsmall.xml'
weetree.write(newFle)