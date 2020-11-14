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
    
    def __init__(self,Directory, MovieName, SegmentationMethod = 'Overlay', SegmentationChannel = ['BF1', 'BF2'], QuantificationChannel = ['PE','NIR','Al488']):
        self.Directory          = Directory
        self.MovieName          = MovieName
        self.Segmentation       = SegmentationMethod
        
        if type(SegmentationChannel) == 'str': #Convert to list to make interateable
            self.Wavelength_Segment = [SegmentationChannel]
            
        if type(QuantificationChannel) == 'str': #Convert to list to make interateable
            self.Wavelength_Quant   = [QuantificationChannel]

    def CheckType(self): #Check wether TAT.XML is inside given Directory
        self.TATXML_File = [fi for fi in os.listdir(self.Directory) if 'TATexp.xml' in fi][0]
        #retrieve TAT.XML
        
    def ReadInMetaData(self):
        TATAvailable = not bool(self.TATXML_File)# FALSE if TATexp.xml found
        
        if TATAvailable:                                                        #Alternative MetaData parsing
            print('Is not there')
            
            self.PositionCount      = None
            self.PositionX          = None
            self.PositionY          = None
            self.PositionCondition  = None
            self.PositionName       = None
            self.PositionIndex      = None
            self.WavelengthCount    = None
            self.WavelengthComment  = None
            self.WavelengthSuffix   = None
            
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
            self.WavelengthSuffix   = [('w00'[0:len('w00')-len(str(wl))] + str(wl)) for wl in range(0,self.WavelengthCount)]        
            # Which channels for Segmentation, which for Quantification?
            
        # Identify which WL should be used for Segmentation, Check if Comment Or Suffix was provided
        SegmentSuffix   =  [check for check in self.Segmentation if check in self.WavelengthSuffix]
        SegmentComment  =  [check for check in self.Segmentation if check in self.WavelengthComment]

        if SegmentSuffix: #Evals to False if empty
            blabla
            
        if SegmentComment: #Evals to False if empty
            blabla

        self.Wavelength_Segment_Suffix =  self.WavelengthSuffix
#ExperimentDir=filedialog.askdirectory(title="########### PLEASE SELECT Working Directory ###########") #Should contain MetaData File
MovieName   = '200708AW11_16bit'
MovieDir    = 'T:/TimelapseData/16bit/AW_donotdelete_16bit/200708AW11_16bit/'
Mov         = qTLExperiment(MovieDir, MovieName)

Mov.CheckType()
Mov.ReadInMetaData()
