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
    
    def __init__(self,Directory, MovieName, SegmentationMethod = 'Overlay', Wavelength_Segment = ['BF1', 'BF2'], Wavelength_Quant = []):
        self.Directory          = Directory
        self.MovieName          = MovieName
        self.Segmentation       = SegmentationMethod
        self.Wavelength_Segment = Wavelength_Segment
        self.Wavelength_Quant   = Wavelength_Quant
        
        if isinstance(self.Wavelength_Segment, str): #Convert to list to make interateable if only one was provided
            self.Wavelength_Segment = [self.Wavelength_Segment]
            
        if isinstance(self.Wavelength_Quant, str): #Convert to list to make interateable if only one was provided
            self.Wavelength_Quant   = [self.Wavelength_Quant]

    def CheckType(self): #Check wether TAT.XML is inside given Directory
        self.TATXML_File = [fi for fi in os.listdir(self.Directory) if 'TATexp.xml' in fi][0]
        
    ## retrieve TAT.XML    
    def ReadInMetaData(self):
        TATAvailable = not bool(self.TATXML_File)# False if TATexp.xml found
        
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
            
            ## Retrieve MetaData information from the TATXML
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
            
        ## Identify which WL should be used for Segmentation
        #Check if Comment Or Suffix was provided by User, also convert to lower case
        SegmentSuffix   =  [check.lower() for check in self.Wavelength_Segment if check.lower() in self.WavelengthSuffix] #provided as Wavelength file name suffix
        SegmentComment  =  [check for check in self.Wavelength_Segment if check in self.WavelengthComment] #provided as Channel naming comment in Youscope
        
        if SegmentSuffix: #False if empty
            self.WavelengthSuffix_Segment = SegmentSuffix #already in right format: Wavelength file suffix
        elif SegmentComment: #False if empty
            Comment_Idx= [i for i in range(0,len(self.WavelengthComment)) if self.WavelengthComment[i] in self.Wavelength_Segment]
            self.WavelengthSuffix_Segment = [self.WavelengthSuffix[i] for i in Comment_Idx]
        else:
            print('Error: Please Provide at least one available Wavelength in Movie for Segmentation with variable \'Wavelength_Segment\'! ' +
                  'Wavelengths available: ' + ', '.join(self.WavelengthComment))
        
        ## Identify which WL should be used for Quant
        #Check if Comment Or Suffix was provided by User, also convert to lower case
        QuantSuffix   =  [check.lower() for check in self.Wavelength_Quant if check.lower() in self.WavelengthSuffix] #provided as Wavelength file name suffix
        QuantComment  =  [check for check in self.Wavelength_Quant if check in self.WavelengthComment] #provided as Channel naming comment in Youscope
        
        if QuantSuffix: #False if empty
            self.WavelengthSuffix_Quant = QuantSuffix #already in right format: Wavelength file suffix
        elif QuantComment: #False if empty
            Comment_Idx= [i for i in range(0,len(self.WavelengthComment)) if self.WavelengthComment[i] in self.Wavelength_Quant]
            self.WavelengthSuffix_Quant = [self.WavelengthSuffix[i] for i in Comment_Idx]
        else:
            print('Error: Please Provide at least one available Wavelength in Movie for Quantification with variable \'Wavelength_Quant\'! ' +
                  'Wavelengths available: ' + ', '.join(self.WavelengthComment))


#ExperimentDir=filedialog.askdirectory(title="########### PLEASE SELECT Working Directory ###########") #Should contain MetaData File
MovieName   = '200708AW11_16bit'
MovieDir    = 'T:/TimelapseData/16bit/AW_donotdelete_16bit/200708AW11_16bit/'
Mov         = qTLExperiment(MovieDir, MovieName,   Wavelength_Segment= 'BF',Wavelength_Quant= ['Rab11-Al488', 'Itgb4-PE','LysobriteNIR'])

Mov.CheckType()
Mov.ReadInMetaData()
