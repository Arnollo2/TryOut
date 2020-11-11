%This script will ask the user to CD into the diretory of the currently acquired movie
%it will get the meta data from TATexp.xml which is craeted by YouScope
%during acquisition and is also in the Movie Directory


%% INITIALIZATION %%
clear all
%Select Movie and Extract MetaData
GetMetaData %gets wavelength information, Position and other data from Tat XML file

StartingTP=1; %should be 1 normally

%Filters
BinSizePixel=2000; % Really large and defacto deactivated, because BinSize Filtering is infeasible.
BinSizeTPs=5; %has to be an odd value for Tracking to always have middle time oint for tracking!!!
ExcludeEdge=0.03;
NonMotileThreshold=5;


%% ITERATE TRHOUGH Positions and perform Online Movie Analysis (OMA) %%

files=dir(movieID); 
Filenames={files.name};
PositionfoldersIndex=find(contains(Filenames,'_p'));
Positionfolders=files(PositionfoldersIndex);
lastTPchecked=cell(NumberPositions,1);%store the last timepoint that was used to create mask for tracking
keepRunning=true; % For now I can stop the process by creating a file called STOP_OMA.txt in the MovieFolder
FirstpassPerpos=ones(NumberPositions,1);%used for initialization of Autotracking

while keepRunning

files=dir(movieID);
Filenames={files.name};
StopCriterion=sum(contains(Filenames,'STOP_OMA.txt'));
if StopCriterion %should be one if STOP_OMA is found in Movie Folder
    keepRunning=false;
end

    for pos=1:NumberPositions 
        
        %check which is the newest file in folder
        position=Positionfolders(pos).name;
        AllImages=dir([movieID,'\',position]);
        AllImages=AllImages(3:end);%first two are simply reference to current and higher folder
        AllImagesNames={AllImages.name};
        AllImagesBF1=AllImages(contains(AllImagesNames,[BF1,'.png']));
        AllImagesBF2=AllImages(contains(AllImagesNames,[BF2,'.png']));
        AllImagesPE=AllImages(contains(AllImagesNames,[PE,'.png']));
        AllImagesAPC=AllImages(contains(AllImagesNames,[APC,'.png']));

        
        checkBF1=struct2table(AllImagesBF1);

        if isempty(lastTPchecked{pos}) 
            %start with earliest and work through entire list
            templateStartingTP='t00000'; 
            NumofDigits=length(num2str(StartingTP));
            templateStartingTP((7-NumofDigits):6)=num2str(StartingTP);
            StartingTPindex=find(contains(checkBF1.name,templateStartingTP));
            Still2CheckBF1=AllImagesBF1(StartingTPindex:end);
        else
            lastTPcheckedtemplate='t00000'; 
            NumofDigits=length(num2str(lastTPchecked{pos}));
            lastTPcheckedtemplate((7-NumofDigits):6)=num2str(lastTPchecked{pos});
            lastTPcheckedindex=find(contains(checkBF1.name,lastTPcheckedtemplate));
            AlreadyChecked=AllImagesBF1(1:lastTPcheckedindex);%check subset of images to be check in addition
            Still2CheckBF1=AllImagesBF1(~ismember({AllImagesBF1.name},{AlreadyChecked.name}));
        end

       % ITERATE TRHOUGH TIMEPOINTS

       %Start with first new image to segment but check if all images are already uploaded 
       if isequal(length(AllImagesBF1),length(AllImagesBF2),length(AllImagesPE),length(AllImagesAPC)) && (~isempty(Still2CheckBF1))
           for check=1:length(Still2CheckBF1) %images are ordered as they were acquired 

                FirstPass=FirstpassPerpos(pos);%already started tracking?

                %update current TP counter
                currentFile=Still2CheckBF1(check).name;
                currentTPstrings=strsplit(currentFile,'_');
                currentTP=currentTPstrings{3};
                currentTP=currentTP(2:end);
                currentTP=str2double(currentTP);
                lastTPchecked{pos}=currentTP;        %Update to know which timepoints were already checked.


                %% Read in Data %%           

                %Read BF images, BF1 slightly over and BF2 slightly under focussed                  
                currentTPtemplate='t00000'; 
                NumofDigits=length(num2str(currentTP));
                currentTPtemplate((7-NumofDigits):6)=num2str(currentTP);
                currentTPindex=find(contains(checkBF1.name,currentTPtemplate));
                BF1image=imread([AllImagesBF1(currentTPindex).folder,'\',AllImagesBF1(currentTPindex).name]); 
                BF2image=imread([AllImagesBF2(currentTPindex).folder,'\',AllImagesBF2(currentTPindex).name]); 
                PEimage=imread([AllImagesPE(currentTPindex).folder,'\',AllImagesPE(currentTPindex).name]); 
                APCimage=imread([AllImagesAPC(currentTPindex).folder,'\',AllImagesAPC(currentTPindex).name]); 

                %% Segmentation %%
                
                UB=1000;%ADJUST
                LB=20; %ADJUST
                ahisteq=(imgaussfilt(histeq(BF1image),2));
                bhisteq=(imgaussfilt(histeq(BF2image),2));
                detected=ahisteq(:)>65535*0.6 & bhisteq(:)<65535*0.4;
                [m,n]=size(BF1image);
                detectedmask=zeros(m,n);
                detectedmask(detected)=1;
                bw =xor(bwareaopen(detectedmask,LB),  bwareaopen(detectedmask,UB));


                %% Quantify and write to csv --> Imitate Faster Output
                
                applymask %outputs cHeader variable, creates csv files immitating fastER csv

                %% Filtering & and Checking if Window can be used
                
                PixelRange = 1:BinSizePixel:2049; %our images are usually 2048 pixels wide, split them in windows for counts
                CurrentWindow=cell(BinSizeTPs,3); %to map back from histogram to Centroids and cells we need to keep track of read in centroids
                CurrentWindowCSVs=cell(3,2); %to save the csv files for later filtering
                BinnedXYmatrix = zeros(numel(PixelRange)-1,numel(PixelRange)-1,BinSizeTPs); %preallocate but do not exceed windowsize in time

                %In order to filter and track we need to be able to look 4 TP into the past. check If they are available before that, window too big
                CheckifAvailable=cell(BinSizeTPs,1);
                for jj = BinSizeTPs:-1:1 %read in outputed segmentation csvs into sliding window

                    %read in the corresponding csv
                    TP2ReadIn         = currentTP-jj+1; %which csv has to be read in now? <-- We look back in time!
                    templateTP='t00000'; 
                    NumofDigits=length(num2str(TP2ReadIn));
                    templateTP((7-NumofDigits):6)=num2str(TP2ReadIn);
                    templateZ='z001';
                    templateM='m00';
                    position=Positionfolders(pos).name;
                    Outputname=[position,'_',templateTP,'_',templateZ,'_','w00','_',templateM,'_','mask'];
                    OutputFolder=[movieID,'\Analysis\Online_Segmentation\',position,'\'];
                    CheckifAvailable{jj}=exist([OutputFolder,Outputname,'.csv'])==2; %must be a file in folder
                    
                end

                AllFilesThere=sum(cell2mat(CheckifAvailable))== BinSizeTPs; %at least as many consecutive files as windowsize

                if AllFilesThere %we can start filtering and tracking! 

                    %% ReadInCSVs looking back in Time %%   
                    ReadInCSVs % produces BinnedXYmatrix

                    %% Filter for isolated Events %%    currently inactivted
                    FilterInTime %creates CurrentFileactiveIsolated

                    %% Filter non motile Events %%      currently inactivted
                    FilterStatic %creates CurrentFileactiveStatic

                    %% Combine both filters and apply to csv file
                    CombineFiltersAndApply %writes out FilteredCSV and Logical Filter produces CurrentWindowCSVs which has all info

                    %% Tracking
                    Tracking %writes out and updates tracked.csv

                    %% Report Findings
                    % Was command given t perform reporting?
                    files=dir(movieID);
                    Filenames={files.name};
                    StartCriterion=sum(contains(Filenames,'DO_PLOT.txt'));
                    if StartCriterion %should be one if DO_PLOT is found in Movie Folder
                        visualize=true;
                    else
                       visualize=false;
                    end

                    if visualize
                        visualizeresults %This script actually ouptuts reporting sheets
                    end
                    
                    FirstpassPerpos(pos)=0; %update as soon as first time filtering was done and tracking was initialized   
                end %if AllFilesThere
           end %for check=1:length(Still2CheckBF1)
       end %check if something to track and if all images acquired
    end %for pos=1:NumberPositions

end %keep looping until stopped
   
 
   




