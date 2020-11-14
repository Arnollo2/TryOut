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
        TATAvailable = not bool(self.TATXML_File)# FALSE if TATexp.xml found
        if TATAvailable:                                                        #Alternative MetaData parsing
            print('Is not there')
        else:                                                                    #Parse TATexp.XML strucutre as root                                                                    
            self.TATXML = ET.parse(self.Directory + '/' + self.TATXML_File).getroot() #Parse XML strucutre as root
            
            #Retrieve MetaData information from the TATXML
            root = self.TATXML
            self.PositionCount      = int(root.find('./PositionCount').attrib['count']) #Is dictionary
            self.PositionX          = [float(pos.attrib['posX']) for pos in root.findall('./PositionData/PositionInformation/')]
            self.PositionY          = [float(pos.attrib['posY']) for pos in root.findall('./PositionData/PositionInformation/')]  
            self.PositionCondition  = [pos.attrib['comments'].split('] ')[1] for pos in root.findall('./PositionData/PositionInformation/')] 
            self.PositionName       = [pos.attrib['comments'].split(' [')[0] for pos in root.findall('./PositionData/PositionInformation/')] 
            self.PositionIndex      = [int(pos.attrib['index']) for pos in root.findall('./PositionData/PositionInformation/')] 

            self.WavelengthCount    = int(root.find('./WavelengthCount').attrib['count']) 
            self.WavelengthComment  = [wl.attrib['Comment'] for wl in root.findall('./WavelengthData/WavelengthInformation/')]
            SuffixTemplate          = 'w00'
            self.WavelengthSuffix   = [(SuffixTemplate[0:len(SuffixTemplate)-len(str(wl))] + str(wl)) for wl in range(0,self.WavelengthCount)]
            #PositionData       = int(self.TATXML.find('./PositionData').attrib['count']) #Is dictionary
                
            # Which channels for Segmentation, which for Quantification?
            
        
#ExperimentDir=filedialog.askdirectory(title="########### PLEASE SELECT Working Directory ###########") #Should contain MetaData File
        
Mov=qTLExperiment('T:/TimelapseData/16bit/AW_donotdelete_16bit/200708AW11_16bit/')
Mov.CheckType()
Mov.ReadInMetaData()
