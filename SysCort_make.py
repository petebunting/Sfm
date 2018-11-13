#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Nov 13 15:06:06 2018

@author: ciaran

A script to create an relative coord system from the first entry in a csv


"""

import pandas as pd
import lxml.etree
import lxml.builder    
import argparse

def make_xml(csvFile):
    
    """
    Make an xml based for the rtl system in micmac
    
    Parameters
    ----------  
    
    csvFile : string
             csv file with coords to use
    """
    
    # I detest xml writing!!!!!!!!!!!!!!!
    E = lxml.builder.ElementMaker()
    
    root = E.SystemeCoord
    doc = E.BSC
    f1 = E.TypeCoord
    f2 = E.AuxR
    f3 = E.AuxRUnite

    
    csv = pd.read_table(csvFile)
    x = str(csv.X[0])
    y = str(csv.Y[0])
    z = str(csv.Z[0])    
    # Bloody hell this is better than etree at least
    
        
    xmlDoc = (root(doc(f1('eTC_RTL'),f2(x),
                       f2(y),
                       f2(z),),
            doc(f1('eTC_WGS84'),
                           f3('eUniteAngleDegre'))))
    
    
    et = lxml.etree.ElementTree(xmlDoc)
    et.write('SysCoRTL.xml', pretty_print=True)
    
parser = argparse.ArgumentParser()


parser.add_argument("-csv", "--cs", type=str, required=True, 
                    help="input dsm")
args = parser.parse_args()

make_xml(args.cs)

