# -*- coding: utf-8 -*-
"""
Created on Wed Nov 11 22:24:18 2020

@author: awehling
"""
import tkinter as tk                #needed to import UI Dir
from tkinter import filedialog      #To ask user to specify the Movie Directory
import re                           # must have for regex to retrieve infos from filenames
import os                           # to query directories for files
import xml.etree.ElementTree as ET  # to read in TATexp.xml if needed
import csv                          # to read in MetaData.txt if needed
import time

class qTLExperiment:
    
    def __init__(self,Directory, MovieName = None, SegmentationMethod = 'Overlay', Wavelength_Segment = ['BF1', 'BF2'], Wavelength_Quant = [], ImageFormat='.tiff', delimiter = ';'):
        #Directory must either contain File ending with MetaData.txt or be a YouScope Experiment with TATexp.xml
        self.Directory              = Directory      
        self.Segmentation           = SegmentationMethod
        self.Wavelength_Segment     = Wavelength_Segment
        self.Wavelength_Quant       = Wavelength_Quant
        self.ImageFormat            = ImageFormat
        self.Delimiter              = delimiter
        
        # These attributes are created either from Dirs or files in MovieDirectory, needed for tracking
        self.PositionIndex          = None
        self.lastTPchecked          = None
        self.PositionDirs           = None
        
        # These attributes can only be assigned when provided specifically. Not necessary for general operation
        self.PositionX              = None
        self.PositionY              = None
        self.PositionCondition      = None
        self.PositionName           = None   
        
        if isinstance(self.Wavelength_Segment, str): #Convert to list to make interateable if only one was provided
            self.Wavelength_Segment = [self.Wavelength_Segment]
            
        if isinstance(self.Wavelength_Quant, str): #Convert to list to make interateable if only one was provided
            self.Wavelength_Quant   = [self.Wavelength_Quant]
                      
        #Parse MetaData   
        self.ReadMetaData()
        
        
    def ReadMetaData(self): #Check wether TAT.XML is inside given Directory
        self.TATXML_File     = [fi for fi in os.listdir(self.Directory) if 'TATexp.xml' in fi]
        
        TATAvailable = not bool(self.TATXML_File)                               #### Check if TATexp.xml found, will eval to False if found
        
        if TATAvailable:                                                        #### Alternative MetaData parsing ####
            
            print('No TATexp.XMLfound, searching for MetaData.txt')
            self.MetaData_File = [fi for fi in os.listdir(self.Directory) if 'MetaData.txt' in fi]
            if not bool(self.MetaData_File):
                print('Error: No MetaData.txt file found, please provide in specified directory')
            else:
                print('MetaData.txt file found --> start Alternative Parsing')
                self.ReadMetaData_Alternative()
                
        else:                                                                   #### Parse TATexp.XML ####
            print('TATexp.XMLfound --> Parsing')
            self.ReadMetaData_TATXML()
            
    
    
    
    def ReadMetaData_TATXML(self):                                              
        #### Parse TATexp.XML ####
        self.MovieDirectory             = self.Directory                                                                                                                                      
        self.OutputDirectory            = self.MovieDirectory + '/Analysis/OnlineMovieAnalysis/'
        self.WavelengthSuffix_standard  = 'w00'
        self.TimeSuffix_standard        = 't00000'
        self.ZstackSuffix_standard      = 'z000'
        self.PositionSuffix_standard    = 'p0000'
        self.WavelengthCount_Start      = 0
        
        MovieNameSplit                  = self.MovieDirectory.split('/')
        MovieNameSplit                  =[i for i in MovieNameSplit if i !=''] #'' is created for a '/' not followed by alphanumerical
        self.MovieName                  =MovieNameSplit[len(MovieNameSplit)-1]   #After split and clean, the last entry should be MovieID
        
        #Create Ouput Directory        
        self.CreateOutputdirectory()
        
        #actual parsing        
        self.TATXML = ET.parse(self.Directory + '/' + self.TATXML_File[0]).getroot()
        root = self.TATXML                       
        self.PositionCount      = int(root.find('./PositionCount').attrib['count'])
        self.PositionX          = [float(pos.attrib['posX']) for pos in root.findall('./PositionData/PositionInformation/')]
        self.PositionY          = [float(pos.attrib['posY']) for pos in root.findall('./PositionData/PositionInformation/')]  
        self.PositionCondition  = [pos.attrib['comments'].split('] ')[1] for pos in root.findall('./PositionData/PositionInformation/')]
        self.PositionName       = [pos.attrib['comments'].split(' [')[0] for pos in root.findall('./PositionData/PositionInformation/')] 
        
        ## Append another None Entry so no matter if positions in Alternative Experiment start with 0 or 1, lists will ahave same index starting at 0
        self.PositionCondition  = [None] + self.PositionCondition
        self.PositionX          = [None] + self.PositionX
        self.PositionY          = [None] + self.PositionY
        self.PositionName       = [None] + self.PositionName
        self.PositionIndex      = None
        # self.PositionIndex      = [int(pos.attrib['index']) for pos in root.findall('./PositionData/PositionInformation/')] 
        
        self.WavelengthCount    = int(root.find('./WavelengthCount').attrib['count']) 
        self.WavelengthComment  = [wl.attrib['Comment'] for wl in root.findall('./WavelengthData/WavelengthInformation/')]
        self.WavelengthSuffix   = [(self.WavelengthSuffix_standard[0:len(self.WavelengthSuffix_standard)-len(str(wl))] + str(wl)) for wl in range(self.WavelengthCount_Start,self.WavelengthCount + self.WavelengthCount_Start)]        #has to start subsetting WavelengthSuffix_standard at 1 not 0 because intial char is suffix for recognition
        
        #Get WL suffix for Segment and Quantifications
        self.GetWLsuffix_SegmentAndQuant()
    
        
    def ReadMetaData_Alternative(self): 
        #### Alternative MetaData parsing ####
        #We already checked that MetaData.txt is available
        #so read it in
        with open(self.Directory + '/' + self.MetaData_File[0]) as csvfile:
            reader = csv.reader(csvfile, delimiter = self.Delimiter)
            for row in reader:
                if row[0] == 'MovieName':
                    self.MovieName                  = row[1]
                if row[0] == 'ImageFormat':
                    self.ImageFormat                = row[1]
                if row[0] == 'MovieDirectory':
                    self.MovieDirectory             = row[1]
                if row[0] == 'OutputDirectory':
                    self.OutputDirectory            = row[1]
                if row[0] == 'WavelengthCount':
                    self.WavelengthCount            = int(row[1])
                if row[0] == 'WavelengthCount_Start':
                    self.WavelengthCount_Start      = int(row[1])
                if row[0] == 'WavelengthComment':
                    self.WavelengthComment          = row[1].split(', ')
                if row[0] == 'WavelengthSuffix_standard':
                    self.WavelengthSuffix_standard  = row[1]
                if row[0] == 'TimeSuffix_standard':
                    self.TimeSuffix_standard        = row[1]
                if row[0] == 'PositionSuffix_standard':
                    self.PositionSuffix_standard    = row[1]
                    
                    
        #Check if wavelengthSuffix is parsed with or without 0 place holders  and get Segment and QUant suffixes   
        NumberOfPlaceholders_WLSuffix    = self.WavelengthSuffix_standard.count('0')
        if NumberOfPlaceholders_WLSuffix == 0:
            self.WavelengthSuffix           = [(self.WavelengthSuffix_standard + str(wl)) for wl in range(self.WavelengthCount_Start,self.WavelengthCount + self.WavelengthCount_Start)]       
        else:
            self.WavelengthSuffix           = [(self.WavelengthSuffix_standard[0:len(self.WavelengthSuffix_standard)-len(str(wl))] + str(wl)) for wl in range(self.WavelengthCount_Start,self.WavelengthCount + self.WavelengthCount_Start)]       
        
        if len(self.WavelengthComment) != self.WavelengthCount:
            print('Error: Please provide names of acquired channels with \'WavelengthComment\' in MetaData.txt. Must be same amount of names as Number of Channels in \'WavelengthCount\'. Expected number of Names: %s ' %str(self.WavelengthCount))
        else: # Match Segmentation and Quantification Channels
            self.GetWLsuffix_SegmentAndQuant()

    def GetWLsuffix_SegmentAndQuant(self):
        #### which WL should be used for Segmentation or Quant ####
        #Check if Comment Or Suffix was provided by User
        SegmentSuffix   =  [check.lower() for check in self.Wavelength_Segment if check.lower() in self.WavelengthSuffix] #provided as Wavelength file name suffix
        QuantSuffix     =  [check.lower() for check in self.Wavelength_Quant if check.lower() in self.WavelengthSuffix] #provided as Wavelength file name suffix
        SegmentComment  =  [check for check in self.Wavelength_Segment if check in self.WavelengthComment] #provided as Channel naming comment in Youscope
        QuantComment    =  [check for check in self.Wavelength_Quant if check in self.WavelengthComment] #provided as Channel naming comment in Youscope
        
        if bool(SegmentSuffix): #False if empty
            self.WavelengthSuffix_Segment   = SegmentSuffix #already in right format: Wavelength file suffix
        elif bool(SegmentComment): #False if empty
            Comment_Idx                     = [i for i in range(0,len(self.WavelengthComment)) if self.WavelengthComment[i] in self.Wavelength_Segment]
            self.WavelengthSuffix_Segment   = [self.WavelengthSuffix[i] for i in Comment_Idx]
        else:
            print('Error: Please Provide at least one available Wavelength in Movie for Segmentation with variable \'Wavelength_Segment\'! ' +
                  'Wavelengths available: ' + ', '.join(self.WavelengthComment))
        
        if bool(QuantSuffix): #False if empty
            self.WavelengthSuffix_Quant     = QuantSuffix #already in right format: Wavelength file suffix
        elif bool(QuantComment): #False if empty
            Comment_Idx                     = [i for i in range(0,len(self.WavelengthComment)) if self.WavelengthComment[i] in self.Wavelength_Quant]
            self.WavelengthSuffix_Quant     = [self.WavelengthSuffix[i] for i in Comment_Idx]
        else:
            print('Error: Please Provide at least one available Wavelength in Movie for Quantification with variable \'Wavelength_Quant\'! ' +
                  'Wavelengths available: ' + ', '.join(self.WavelengthComment))          
         
    def CreateOutputdirectory(self):
        if not os.path.isdir(self.OutputDirectory):
            try:
                os.mkdir(self.OutputDirectory)
            except OSError:
                print ("Creation of Output directory %s failed" % self.OutputDirectory)
            else:
                print ("Successfully created Output directory %s " % self.OutputDirectory)
                
    def ScanPositionsAndCreateIterable(self):      
        ### Create PositionDirs             
        #needed to check if pos dirs are actually position dirs
        NumberOfPlaceholders_PosSuffix  = self.PositionSuffix_standard.count('0')
        PosSuffix_Stripped              = self.PositionSuffix_standard[0:(len(self.PositionSuffix_standard)-NumberOfPlaceholders_PosSuffix)]
        
        #Create PositonFolder list
        self.Positionsfound                    = os.listdir(self.MovieDirectory)
        #only list positions if pos is actually a dir and contains specified position suffix
        self.Positionsfound                 = [(self.MovieDirectory +'/'+ pos ) for pos in self.Positionsfound   if  os.path.isdir(self.MovieDirectory + '/' + pos) & (PosSuffix_Stripped in pos)] 
            
        #First check if Positions are folders within MovieDirectory or if all images are dumped in one directory
        if bool(self.Positionsfound): # True if position dirs found
            self.CreatePositionIterableFromDirs()
        else:
            self.CreatePositionIterableFromFiles()
                

    def CreatePositionIterableFromDirs(self):
        #Get Segmentation Images per position 
        #This will create a List with image names, or if multiple images found per position a list of lists, with a list for every position
      
        #Need to strip TP suffix from potential place holders for the following regex to sort tps numerically
        NumberOfPlaceholders_TPSuffix       = self.TimeSuffix_standard.count('0') 
        TPSuffix_Stripped                   = self.TimeSuffix_standard[0:(len(self.TimeSuffix_standard)-NumberOfPlaceholders_TPSuffix)]
        
        #Need to strip Pos from potential place holders for regex to sort positions numerically
        NumberOfPlaceholders_PosSuffix      = self.PositionSuffix_standard.count('0')
        PosSuffix_Stripped                  = self.PositionSuffix_standard[0:(len(self.PositionSuffix_standard)-NumberOfPlaceholders_PosSuffix)]
        
        #Sort PositionDirs numerically
        PositionDirs2beIterated                   = self.Positionsfound  
        ToBeSorted_Positions                      = [re.findall(PosSuffix_Stripped+'[0-9]+',pos)[0] for pos in PositionDirs2beIterated]
        ToBeSorted_Positions                      = [int(tp.replace(PosSuffix_Stripped,'')) for tp in ToBeSorted_Positions]
        #"decorate, sort, undecorate" idiom
        self.Pos_Sorted, self.PositionDirs_Sorted = (list(t) for t in zip(*sorted(zip(ToBeSorted_Positions, PositionDirs2beIterated))))
        
        #Now Create or Append Position Index list
        if not bool(self.PositionIndex): #not yet intialized, create positionwise tracker
            
            self.PositionIndex = [pos for pos in range(0,max(self.Pos_Sorted)+1)]
            self.lastTPchecked = [-1 for idx in self.PositionIndex]
            self.PositionDirs  = [None for idx in self.PositionIndex]
            
            for k in range(0,len(self.Pos_Sorted)):
                self.PositionDirs[self.Pos_Sorted[k]] =  self.PositionDirs_Sorted[k]
            
        else: # if already exists, check if new Positions were found
            
            #Identify new Position Indices and Directories to add them 
            NewPositions_Index = [pos for pos in self.Pos_Sorted if not (pos in self.PositionIndex)] 

            if bool(NewPositions_Index): #True if new Positions are found
                NewPositions_dirs            = [self.PositionDirs_Sorted[i] for i in range(0,len(self.Pos_Sorted)) if self.Pos_Sorted[i] in NewPositions_Index ] 
                #if new positions have been added, append them to lastTPchecked, PositionDirs_Sorted and PositionsIndex 
                ExtendedPositionIndex        = [pos for pos in range(min(self.PositionIndex + NewPositions_Index),max(self.PositionIndex + NewPositions_Index)+1)]
                ExtendedlastTPChecked        = [-1 for pos in ExtendedPositionIndex]
                ExtendedPositionDirs         = [None for pos in ExtendedPositionIndex]
                
                for i in self.PositionIndex:                            #transfer old positionwise data
                    ExtendedlastTPChecked[i] = self.lastTPchecked[i]
                    ExtendedPositionDirs[i]  = self.PositionDirs[i]
                    
                for j in range(0,len(NewPositions_Index)):            #Add new positionwise data
                    ExtendedPositionDirs[NewPositions_Index[j]] = NewPositions_dirs[j]
                
                
                ##### These three lists + Positions2beIteratred MUST have same length ######
                self.PositionIndex = ExtendedPositionIndex
                self.lastTPchecked = ExtendedlastTPChecked
                self.PositionDirs  = ExtendedPositionDirs
                
                #Transfer old lastTPchecked 
       
        #create Iterable             
        self.Position2beIterated = [os.listdir(pos) if pos is not None else [] for pos in self.PositionDirs]
        
        #check if images were found
        if not sum([bool(pos) for pos in self.Position2beIterated]): #False if Position2beIterated is list of emtpy lists
            print('Warning: No images found for Segmentation with channel {} = {}'.format(self.WavelengthSuffix_Segment[0] , self.Wavelength_Segment[0]))
        else: #order positionwise iterable alphanumerically
            for i in range(0,len(self.Position2beIterated)):
                
                #Only if position dir exists and contains images
                if bool(self.Position2beIterated[i]): #false if emtpy
                    #only check for images to be segmented
                    self.Position2beIterated[i]         = [img for img in self.Position2beIterated[i] if (self.WavelengthSuffix_Segment[0] in img) & (self.ImageFormat in img) ]
                    ImagesInPosition2beIterated         = self.Position2beIterated[i]
                    #sort them increasingly by timepoint after extracting tp info from filename using regular expression
                    ToBeSorted_TimePoints               =  [re.findall(TPSuffix_Stripped+'[0-9]+',tp)[0] for tp in ImagesInPosition2beIterated]
                    #get rid of tp suffix for numerical sorting and convert to int
                    ToBeSorted_TimePoints               =  [int(tp.replace(TPSuffix_Stripped,'')) for tp in ToBeSorted_TimePoints]
                    #"decorate, sort, undecorate" idiom
                    TPs_Sorted, ImagesInPosition_Sorted = (list(t) for t in zip(*sorted(zip(ToBeSorted_TimePoints, ImagesInPosition2beIterated))))
                    
                    #Only use Images whose TPs that have not been tracked yet]
                    lastseenTPofPosition        = self.lastTPchecked[i] 
                    TPs_Sorted_SubsetIndex      = [idx for idx in range(0,len(TPs_Sorted)) if TPs_Sorted[idx] > lastseenTPofPosition ]
                    #Reassign sorted entry that is now in correct temporal order
                    ImagesInPosition_Sorted     = [ImagesInPosition_Sorted[idx] for idx in TPs_Sorted_SubsetIndex]
                    self.Position2beIterated[i] = ImagesInPosition_Sorted



    def CreatePositionIterableFromFiles(self):
        #Find Segmentation Images per position if all images are dumped in same folder
        # and sort them in lists of lists --> This will be your Iterable
        
        #Need to strip TP suffix from potential place holders for the following regex for sortin tps numerically
        NumberOfPlaceholders_TPSuffix   = self.TimeSuffix_standard.count('0') 
        TPSuffix_Stripped               = self.TimeSuffix_standard[0:(len(self.TimeSuffix_standard)-NumberOfPlaceholders_TPSuffix)]
        
        #Need to strip Pos from potential place holders for regex to sort positions numerically
        NumberOfPlaceholders_PosSuffix  = self.PositionSuffix_standard.count('0')
        PosSuffix_Stripped              = self.PositionSuffix_standard[0:(len(self.PositionSuffix_standard)-NumberOfPlaceholders_PosSuffix)]
        
        AllFilesFound                   = os.listdir(self.MovieDirectory)
        AllPositionsFound               = [re.findall(PosSuffix_Stripped+'[0-9]+',fi)[0] for fi in AllFilesFound if PosSuffix_Stripped in fi]
        AllPositionsFound_Unique        = list(set(AllPositionsFound))
        
        #These two now have same length and order
        AllPositionsFound_Unique.sort()
        AllPositionsFound_Index         = [int(re.findall('[0-9]+',pos)[0]) for pos in AllPositionsFound_Unique]
        
        #Now Create or Append Position Index list
        if not bool(self.PositionIndex): #not yet intialized, create positionwise tracker
            self.PositionIndex      = [pos for pos in range(0,max(AllPositionsFound_Index)+1)]
            self.lastTPchecked      = [-1 for idx in self.PositionIndex]
            self.PositionDirs       = [None if pos not in AllPositionsFound_Index else '' for pos in self.PositionIndex] #when '' we kan just add it to DIrectory string later, for reading the data an.           
        else: # if already exists, check if new Positions were found
            NewPositions_Index      = [pos for pos in AllPositionsFound_Index if pos not in self.PositionIndex]
            #if new positions have been added, append them to lastTPchecked, PositionDirs_Sorted and PositionsIndex 
            ExtendedPositionIndex   = [pos for pos in range(min(self.PositionIndex + NewPositions_Index),max(self.PositionIndex + NewPositions_Index)+1)]
            ExtendedlastTPChecked   = [-1 for pos in ExtendedPositionIndex]
            ExtendedPositionDirs    = [None for pos in ExtendedPositionIndex]
            
            for i in self.PositionIndex:                            #transfer old positionwise data
                ExtendedlastTPChecked[i] = self.lastTPchecked[i]
                ExtendedPositionDirs[i]  = self.PositionDirs[i]
                
            for j in range(0,len(NewPositions_Index)):            #Add new positionwise data
                ExtendedPositionDirs[NewPositions_Index[j]] = ''
            
            
            ##### These three lists + Positions2beIteratred MUST have same length ######
            self.PositionIndex = ExtendedPositionIndex
            self.lastTPchecked = ExtendedlastTPChecked
            self.PositionDirs  = ExtendedPositionDirs    
                
        #create Iterable
        self.Position2beIterated = [[] for idx in self.PositionIndex]
        
        for pos in self.PositionIndex:
            possuffix                       = PosSuffix_Stripped + '0'*NumberOfPlaceholders_PosSuffix 
            possuffix                       = possuffix[0:(len(possuffix)-NumberOfPlaceholders_PosSuffix)] + str(pos)
            self.Position2beIterated[pos]  = [img for img in AllFilesFound if possuffix in img]
            
        
        #Now make sure that files are in correct order
        for i in range(0,len(self.Position2beIterated)):
            #Use Possuffix to grep and then order images per FoV
            #Only if position dir exists and contains images
            if bool(self.Position2beIterated[i]): #false if emtpy
                #only check for images to be segmented
                self.Position2beIterated[i]         = [img for img in self.Position2beIterated[i] if (self.WavelengthSuffix_Segment[0] in img) & (self.ImageFormat in img) ]
                ImagesInPosition2beIterated         = self.Position2beIterated[i]
                #sort them increasingly by timepoint after extracting tp info from filename using regular expression
                ToBeSorted_TimePoints               =  [re.findall(TPSuffix_Stripped+'[0-9]+',tp)[0] for tp in ImagesInPosition2beIterated]
                #get rid of tp suffix for numerical sorting and convert to int
                ToBeSorted_TimePoints               =  [int(tp.replace(TPSuffix_Stripped,'')) for tp in ToBeSorted_TimePoints]
                #"decorate, sort, undecorate" idiom
                TPs_Sorted, ImagesInPosition_Sorted = (list(t) for t in zip(*sorted(zip(ToBeSorted_TimePoints, ImagesInPosition2beIterated))))
                
                #Only use Images whose TPs that have not been tracked yet]
                lastseenTPofPosition        = self.lastTPchecked[i] 
                TPs_Sorted_SubsetIndex      = [idx for idx in range(0,len(TPs_Sorted)) if TPs_Sorted[idx] > lastseenTPofPosition ]
                #Reassign sorted entry that is now in correct temporal order
                ImagesInPosition_Sorted     = [ImagesInPosition_Sorted[idx] for idx in TPs_Sorted_SubsetIndex]
                self.Position2beIterated[i] = ImagesInPosition_Sorted
        
        
        
        
    def TrackIterable(self, currentPosition_Index,currentTP):
        #currentTP will be parsed from image name
        #Register the lastTPChecked per Position and clear the respective Position2beIterated entry
        PositionPointer                             = [i for i in range(0,self.PositionCount) if self.PositionIndex[i] == currentPosition_Index]
        PositionPointer                             = PositionPointer[0]#still list get entry alone
        self.lastTPchecked[PositionPointer]         = currentTP
        
    def UpdateIterable(self):
        #Check images per Position 
        self.ScanPositionsAndCreateIterable()
        #Remove all Images before and including latest lastTPchecked entry
        for i in range(0,len(self.Position2beIterated)):
            FilesFoundInPosition        = self.Position2beIterated[i]
            TPs2Exlcude                 = [(self.TimeSuffix_standard[0:len(self.TimeSuffix_standard)-len(str(tp))] + str(tp)) for tp in range(0,self.lastTPchecked[i]+1)]
            NewFilesFoundInPosition     = [img for img in FilesFoundInPosition if sum([(fi in img) for fi in TPs2Exlcude]) == 0] #only get images that do not belong to timepoints already seen.
            self.Position2beIterated[i] = NewFilesFoundInPosition


#ExperimentDir=filedialog.askdirectory(title="########### PLEASE SELECT Working Directory ###########") #Should contain MetaData File

#Test for Alternative.xml
Directory   ='N:/schroeder/Data/AW/PAPER-OMAwithDS/Leica/200301GC50'
Mov1         = qTLExperiment(Directory, delimiter='\t',Wavelength_Segment= 'BF',Wavelength_Quant= ['BF','APC'])
Mov1.ScanPositionsAndCreateIterable()
#Works and can be updated

Directory   ='N:/schroeder/Data/AW/PAPER-OMAwithDS/NIS TIFF series/nd002'
Mov2         = qTLExperiment(Directory, delimiter='\t',Wavelength_Segment= 'BF',Wavelength_Quant= ['BF','APC'])
Mov2.ScanPositionsAndCreateIterable()
Mov2.Position2beIterated
#Works and can be updated


#Test for TATexp.xml
MovieDir    = 'T:/TimelapseData/16bit/AW_donotdelete_16bit/200708AW11_16bit/'
Mov3         = qTLExperiment(MovieDir, ImageFormat='.png',  Wavelength_Segment= 'BF',Wavelength_Quant= ['Rab11-Al488', 'Itgb4-PE','LysobriteNIR'])
Mov3.ScanPositionsAndCreateIterable()
Mov3.Position2beIterated



#Check for available images per position
start_time = time.time()
Mov2.ScanPositionsAndCreateIterable()
print("--- %s seconds ---" % (time.time() - start_time))
#Works and can be updated

