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

parser = argparse.ArgumentParser()

parser.add_argument("-csv", "--cs", type=str, required=True, 
                    help="input csv")

parser.add_argument("-d", "--delim", type=str, required=False, default=None, 
                    help="delimeter for csv")
parser.add_argument("-kwp", "--ypr", type=str, required=False, default=None, 
                    help="inclusion of yaw pitch roll - not required")

args = parser.parse_args()

def make_xml(csvFile, delim=args.delim, yaw=args.ypr):
    
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

    
    csv = pd.read_table(csvFile, delimiter=delim)
#    if len(csv.columns) == 1:
#        csv = pd.read_table(csvFile, delimiter=" ")
        
    x = str(csv.X[0])
    y = str(csv.Y[0])
    z = str(csv.Z[0])
    
    # if we are including yaw pitch and roll (k,w,p)
    if yaw !=None:            
        k = str(csv.K[0])
        w = str(csv.W[0])
        p = str(csv.Z[0])          
    # Bloody hell this is better than etree at least       
        xmlDoc = (root(doc(f1('eTC_RTL'),f2(x),
                           f2(y),
                           f2(z), 
                           f2(k),
                           f2(w),
                           f2(p),),
                doc(f1('eTC_WGS84'),
                               f3('eUniteAngleDegre'))))
    else:
        xmlDoc = (root(doc(f1('eTC_RTL'),f2(x),
                       f2(y),
                       f2(z),), 
            doc(f1('eTC_WGS84'),
                           f3('eUniteAngleDegre'))))
    
    et = lxml.etree.ElementTree(xmlDoc)
    et.write('SysCoRTL.xml', pretty_print=True)
    





make_xml(args.cs)

