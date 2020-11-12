# -*- coding: utf-8 -*-
"""
Created on Wed Nov 11 22:24:18 2020

@author: awehling
"""
import tkinter as tk #needed to import UI Dir
import os #needed to query directories for files
 
MetaDataDirectory="ExperimentDir"

class qTLExperiment:
    def __init__(self,Directory):
        self.Directory = Directory
        
    def CheckExperimentType(self):
        self.FilesInDirectory= [fi for fi in os.listdir(self.Directory)]
        
        
        