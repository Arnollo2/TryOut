# -*- coding: utf-8 -*-
"""
Created on Wed Nov 11 22:24:18 2020

@author: awehling
"""
import tkinter as tk #needed to import UI Dir
from tkinter import filedialog  #To ask user to specify the Movie Directory
import os #needed to query directories for files
import xml.etree.ElementTree as ET #needed to read in XML


class qTLExperiment:
    def __init__(self,Directory):
        self.Directory = Directory
        
    def CheckType(self): #Check wether TAT.XML is inside
        self.TATXML_File = [fi for fi in os.listdir(self.Directory) if 'TATexp.xml' in fi][0]
        #retrieve TAT.XML
        
    def ReadInMetaData(self):
        TATAvailable = not bool(self.TATXML_File) #Evals to true if TATexp.xml is not found
        if TATAvailable:
            print('Is not there')
        else:
            #Parse XML strucutre as root
            self.TATXML = ET.parse(self.Directory + '/' + self.TATXML_File).getroot() #Parse XML strucutre as root
            
        #Now we can start retrieving the MetaData information from the TATXML
        self.PositionCount = int(self.TATXML.find('./PositionCount').attrib['count']) #Is dictionary
        PositionData       = int(self.TATXML.find('./PositionData').attrib['count']) #Is dictionary

        
#ExperimentDir=filedialog.askdirectory(title="########### PLEASE SELECT Working Directory ###########") #Should contain MetaData File
        
Mov=qTLExperiment('T:/TimelapseData/16bit/AW_donotdelete_16bit/200708AW11_16bit/')
Mov.CheckType()
Mov.ReadInMetaData()


for a in root.findall('./PositionData/PositionInformation/'):
    print(a.attrib)
    