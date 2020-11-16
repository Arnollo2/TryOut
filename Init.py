# -*- coding: utf-8 -*-
"""
Created on Wed Nov 11 22:24:18 2020

@author: awehling
"""
import tkinter as tk #needed to import UI Dir
from tkinter import filedialog  #To ask user to specify the Movie Directory
import os #needed to query directories for files
import xml.etree.ElementTree as ET #needed to read in XML
import glob
import time

class qTLExperiment:
    
    def __init__(self,Directory, MovieName = None, OutputDirectory = None,  SegmentationMethod = 'Overlay', Wavelength_Segment = ['BF1', 'BF2'], Wavelength_Quant = [], ImageFormat='.tiff'):
        self.Directory              = Directory
        self.MovieName              = MovieName
        self.Segmentation           = SegmentationMethod
        self.Wavelength_Segment     = Wavelength_Segment
        self.Wavelength_Quant       = Wavelength_Quant
        self.ImageFormat            = ImageFormat

        if isinstance(self.Wavelength_Segment, str): #Convert to list to make interateable if only one was provided
            self.Wavelength_Segment = [self.Wavelength_Segment]
            
        if isinstance(self.Wavelength_Quant, str): #Convert to list to make interateable if only one was provided
            self.Wavelength_Quant   = [self.Wavelength_Quant]

    def CheckType(self): #Check wether TAT.XML is inside given Directory
        self.TATXML_File = [fi for fi in os.listdir(self.Directory) if 'TATexp.xml' in fi][0]
        
    ## retrieve TAT.XML    
    def ReadInMetaData(self):
        TATAvailable = not bool(self.TATXML_File)                               #### Check if TATexp.xml found
        
        if TATAvailable:                                                        #### Alternative MetaData parsing ####
            print('No TATexp.XMLfound --> Alternative Parsing')
            
            self.PositionCount      = None
            self.PositionX          = None
            self.PositionY          = None
            self.PositionCondition  = None
            self.PositionName       = None
            self.PositionIndex      = None
            self.WavelengthCount    = None
            self.WavelengthComment  = None
            self.WavelengthSuffix   = None
            self.OutputDirectory    = None
        else:                                                                    #### Parse TATexp.XML ####                                                                   
            print('TATexp.XMLfound --> Parsing')
            self.OutputDirectory    = self.Directory + '/Analysis/OnlineMovieAnalysis/'
            
            if not os.path.isdir(self.OutputDirectory):
                try:
                    os.mkdir(self.OutputDirectory)
                except OSError:
                    print ("Creation of the directory %s failed" % self.OutputDirectory)
                else:
                    print ("Successfully created the directory %s " % self.OutputDirectory)
            
            self.WavelengthSuffix_standard   = 'w00'
            self.TimeSuffix_standard         = 't00000'
            self.ZstackSuffix_standard       = 'z000'
            self.PositionSuffix_standard     = 'p0000'
            
            self.TATXML = ET.parse(self.Directory + '/' + self.TATXML_File).getroot() #Parse XML strucutre as root
            root = self.TATXML                       
            self.PositionCount      = int(root.find('./PositionCount').attrib['count']) #Is dictionary
            self.PositionX          = [float(pos.attrib['posX']) for pos in root.findall('./PositionData/PositionInformation/')]
            self.PositionY          = [float(pos.attrib['posY']) for pos in root.findall('./PositionData/PositionInformation/')]  
            self.PositionCondition  = [pos.attrib['comments'].split('] ')[1] for pos in root.findall('./PositionData/PositionInformation/')] 
            self.PositionName       = [pos.attrib['comments'].split(' [')[0] for pos in root.findall('./PositionData/PositionInformation/')] 
            self.PositionIndex      = [int(pos.attrib['index']) for pos in root.findall('./PositionData/PositionInformation/')] 
            self.PositionSuffix     = [(self.PositionSuffix_standard[0:len(self.PositionSuffix_standard)-len(str(pos))] + str(pos)) for pos in self.PositionIndex]
            
            PositionDirs            = os.listdir(self.Directory)
            self.PositionDirs       = [(self.Directory + pos ) for pos in PositionDirs if  os.path.isdir(self.Directory + pos) & (sum((possuffix in pos) for possuffix in self.PositionSuffix)==1)] #only list psotions if dir and contains specified position suffix

            self.lastTPchecked      = [0 for i in self.PositionIndex] #to check last iterated TP per Position
            self.WavelengthCount    = int(root.find('./WavelengthCount').attrib['count']) 
            self.WavelengthComment  = [wl.attrib['Comment'] for wl in root.findall('./WavelengthData/WavelengthInformation/')]
            self.WavelengthSuffix   = [(self.WavelengthSuffix_standard[0:len(self.WavelengthSuffix_standard)-len(str(wl))] + str(wl)) for wl in range(0,self.WavelengthCount)]      

        #### which WL should be used for Segmentation or Quant ####
        #Check if Comment Or Suffix was provided by User
        SegmentSuffix   =  [check.lower() for check in self.Wavelength_Segment if check.lower() in self.WavelengthSuffix] #provided as Wavelength file name suffix
        QuantSuffix     =  [check.lower() for check in self.Wavelength_Quant if check.lower() in self.WavelengthSuffix] #provided as Wavelength file name suffix
        SegmentComment  =  [check for check in self.Wavelength_Segment if check in self.WavelengthComment] #provided as Channel naming comment in Youscope
        QuantComment    =  [check for check in self.Wavelength_Quant if check in self.WavelengthComment] #provided as Channel naming comment in Youscope
        
        if SegmentSuffix: #False if empty
            self.WavelengthSuffix_Segment   = SegmentSuffix #already in right format: Wavelength file suffix
        elif SegmentComment: #False if empty
            Comment_Idx                     = [i for i in range(0,len(self.WavelengthComment)) if self.WavelengthComment[i] in self.Wavelength_Segment]
            self.WavelengthSuffix_Segment   = [self.WavelengthSuffix[i] for i in Comment_Idx]
        else:
            print('Error: Please Provide at least one available Wavelength in Movie for Segmentation with variable \'Wavelength_Segment\'! ' +
                  'Wavelengths available: ' + ', '.join(self.WavelengthComment))
        
        if QuantSuffix: #False if empty
            self.WavelengthSuffix_Quant     = QuantSuffix #already in right format: Wavelength file suffix
        elif QuantComment: #False if empty
            Comment_Idx                     = [i for i in range(0,len(self.WavelengthComment)) if self.WavelengthComment[i] in self.Wavelength_Quant]
            self.WavelengthSuffix_Quant     = [self.WavelengthSuffix[i] for i in Comment_Idx]
        else:
            print('Error: Please Provide at least one available Wavelength in Movie for Quantification with variable \'Wavelength_Quant\'! ' +
                  'Wavelengths available: ' + ', '.join(self.WavelengthComment))
         
            
    def CreateIterable(self): 
        #Get Segmentation Images per position 
        #This will create a List with image names, or if multiple images found per position a list of lists, with a list for every position
        #self.Position2beIterated = [glob.glob(pos + '/*' + self.WavelengthSuffix_Segment[0] + '*' + self.ImageFormat) for pos in self.PositionDirs]
        self.Position2beIterated = [os.listdir(pos) for pos in self.PositionDirs]
        for i in range(0,len(self.Position2beIterated)):
            #only check for images to be segmented
            self.Position2beIterated[i] = [img for img in self.Position2beIterated[i] if (self.WavelengthSuffix_Segment[0] in img) & (self.ImageFormat in img) ]
           
    def TrackIterable(self, currentPosition_Index,currentTP):
        #currentTP will be parsed from image name
        #Register the lastTPChecked per Position and clear the respective Position2beIterated entry
        PositionPointer                             = [i for i in range(0,self.PositionCount) if self.PositionIndex[i] == currentPosition_Index]
        PositionPointer                             = PositionPointer[0]#still list get entry alone
        self.lastTPchecked[PositionPointer]         = currentTP
        
    def UpdateIterable(self):
        #Check images per Position 
        self.CreateIterable()
        #Remove all Images before and including latest lastTPchecked entry
        for i in range(0,len(self.Position2beIterated)):
            FilesFoundInPosition        = self.Position2beIterated[i]
            TPs2Exlcude                 = [(self.TimeSuffix_standard[0:len(self.TimeSuffix_standard)-len(str(tp))] + str(tp)) for tp in range(0,self.lastTPchecked[i]+1)]
            NewFilesFoundInPosition     = [img for img in FilesFoundInPosition if sum([(fi in img) for fi in TPs2Exlcude]) == 0] #only get images that do not belong to timepoints already seen.
            self.Position2beIterated[i] = NewFilesFoundInPosition


'''
def CreateIterator(self, currentPosition_Index):
    #given a CurrentPosition_Index
    if not currentPosition_Index in self.PositionIndex:
        print('Current position not selected from Positions available. Please chose \'currentPosition\' contained in \'PositionIndex\'!')
    else:
        #Create Dictionary that contains types, entries and names of internal variables ppased onto the FieldOfView Object
        print('currently at position ' + str(currentPosition_Index))

        PositionPointer = [i for i in range(0,self.PositionCount) if self.PositionIndex[i] == currentPosition_Index]
        keys   = [lastTP]
        Values = getattr(Mov)
        return(PositionPointer, keys)
 '''       
#ExperimentDir=filedialog.askdirectory(title="########### PLEASE SELECT Working Directory ###########") #Should contain MetaData File


#Test
MovieName   = '200708AW11_16bit'
MovieDir    = 'T:/TimelapseData/16bit/AW_donotdelete_16bit/200708AW11_16bit/'
Mov         = qTLExperiment(MovieDir, MovieName, ImageFormat='.png',  Wavelength_Segment= 'BF',Wavelength_Quant= ['Rab11-Al488', 'Itgb4-PE','LysobriteNIR'])


Mov.CheckType()
Mov.ReadInMetaData()

#Check for available images per position
start_time = time.time()
Mov.CreateIterable()
print("--- %s seconds ---" % (time.time() - start_time))

#Should be a full list with exactly one t00001 iamge w00 per entry
Mov.Position2beIterated

#update every postion as having just seen t00001
for currentPosition_Index in Mov.PositionIndex:
    Mov.TrackIterable(currentPosition_Index=currentPosition_Index,currentTP=1)
    
#Update Iterable
start_time = time.time()
Mov.UpdateIterable()
print("--- %s seconds ---" % (time.time() - start_time))

#Should be emptie now
Mov.Position2beIterated

#Works
