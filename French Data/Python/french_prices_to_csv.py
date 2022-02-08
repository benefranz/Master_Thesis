#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Jul  9 21:55:48 2020

"""
import os.path
import sys
import csv
from xml.etree import cElementTree


def csv_to_xml(infile,outfile):
    with open(outfile, 'w', newline='') as f:

        writer = csv.writer(f)
        tree = cElementTree.parse(infile)
        pdvs = tree.getroot()
        for pdv in pdvs:
            id_pdv = pdv.attrib['id']
            pop = pdv.attrib['pop']
            lat = pdv.attrib['latitude']
            lon = pdv.attrib['longitude']
            cp_pdv = pdv.attrib['cp']
            #print(id_pdv)
            for prix in pdv.iter('prix'):
                date = prix.attrib['maj'] if 'maj' in prix.keys() else ''
                id_prix = prix.attrib['id'] if 'id' in prix.keys() else ''
                valeur = prix.attrib['valeur'] if 'valeur' in prix.keys() else ''
                nom = prix.attrib['nom'] if 'nom' in prix.keys() else ''
                row = [id_pdv, cp_pdv, pop, lat, lon, date, id_prix, nom, valeur]
                #print(id_pdv)
                #print(valeur)
                #print(row)
                writer.writerow(row)
    return

years = ["2019", "2020", "2021"]

for i in years:
    print(i)
    infile = "PrixCarburants_annuel_{}.xml".format(i)
    outfile = "/Users/benediktfranz/OneDrive - bwedu/Studium/Master/MasterThesis/Empirical Analysis/Replication/Data Input/PrixCarburants_annuel_{}.csv".format(i)
    csv_to_xml(infile,outfile)
