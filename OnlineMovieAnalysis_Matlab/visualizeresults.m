%for pos=1:5%NumberPositions

     %position=Positionfolders(pos).name;
     %TrackedName=[position,'_tracked'];
     %OutputFolder=[movieID,'\Analysis\Online_Segmentation\',position,'\'];
     %AllImages=dir([movieID,'\',position]);
     %AllImages=AllImages(3:end);%first two are simply reference to current and higher folder
     %AllImagesNames={AllImages.name};
     %AllImagesBF1=AllImages(contains(AllImagesNames,[BF1,'.png']));
     %BF1image=imread([AllImagesBF1(end).folder,'\',AllImagesBF1(currentTP).name]); 
     %ahisteq=(imgaussfilt(histeq(BF1image),2));
     
    %% read in csv of tracked results
    TrackedData=read_mixed_csv([OutputFolder,TrackedName,'.csv'],';');
    %trim last column, seems to be an artifact
    Header=TrackedData(1,1:end-1);
    TrackedData=TrackedData(2:end,1:end-1);%get rid of last column and header!
    %convert entire TrackData to numeric and then to table
    TrackedData=cellfun(@str2num,TrackedData);
    TrackedData=array2table(TrackedData,'VariableNames',Header);



    %% Find out which cells have divided once in this particular position and make them plotable

    %FOR ARNE 
    %only report on those that have divided one and are in generation 1
    ColoniesfoundinMingen1=unique(TrackedData.Colony(TrackedData.TrackNumber>1 & ~(TrackedData.TrackNumber>3) & TrackedData.TimePoint==currentTP-1));
    Coloniesfoundingen2=unique(TrackedData.Colony( TrackedData.TrackNumber>3 & TrackedData.TimePoint==currentTP-1));
    Coloniesfoundingen1=ColoniesfoundinMingen1(~ismember(ColoniesfoundinMingen1,Coloniesfoundingen2));
	Coloniesfound=Coloniesfoundingen1(Coloniesfoundingen1>0);
    
    %FOR JEFF
    %Coloniesfound=unique(TrackedData.Colony(TrackedData.TrackNumber>1 & TrackedData.TimePoint==currentTP-1));
    

    AllColoniesInPosition=cell(numel(Coloniesfound),1);%make cell array to store each colonyarray


    
    
    for col=1:numel(Coloniesfound)

        current=Coloniesfound(col);
        ColonyLogical=TrackedData.Colony==current;
        Colonydata=TrackedData(ColonyLogical,:);
        TrackNumbers=Colonydata.TrackNumber;

        %for SumBGcorrectedPE and APC but also both Centroids and last one for lineage tree
        ColonyArray=nan(max(Colonydata.TimePoint),max(TrackNumbers),5);

        %now construct array, timepoints are equivalent to rownumbers, columns to tracknumbers and stacks to channels

        for j=1:7 %only show the first 2 generations plus mother
            track=(j);
                tracklogical=Colonydata.TrackNumber==track;
            if sum(tracklogical)>0
                trackdata=Colonydata(tracklogical,:);
                ColonyArray(trackdata.TimePoint,track,1)=trackdata.SumBgCorrectedPE;
                ColonyArray(trackdata.TimePoint,track,2)=trackdata.SumBgCorrectedAPC;
                ColonyArray(trackdata.TimePoint,track,3)=trackdata.CentroidX;
                ColonyArray(trackdata.TimePoint,track,4)=trackdata.CentroidY;
                ColonyArray(trackdata.TimePoint,track,5)=trackdata.CentroidY(1);
            end
        end
       AllColoniesInPosition{col,1}=ColonyArray;

    end




    %% Generate Output File for every Colony

    % check if folder already exists
    DetectedFolder=[movieID,'\Analysis\Online_Segmentation\Detected\'];
    if exist(DetectedFolder)<1
        mkdir(DetectedFolder);
    end

    %delete all those that are in current position, will be replaced anyway by new ones
    allfilesdetected=dir(DetectedFolder);
    for rep=1:length(allfilesdetected)
        if contains(allfilesdetected(rep).name,position)
           delete([DetectedFolder,allfilesdetected(rep).name]);
        end
    end


    for col=1:numel(Coloniesfound)
        

        
        % Retrieve Colony data 
        Colonydata=AllColoniesInPosition{col,1}; 

        if size(Colonydata,2)>=3
            
            
            %CD71AsymmLevel
            sister1CD71=Colonydata(end-1,2,1);
            sister2CD71=Colonydata(end-1,3,1);
            if sister1CD71<=sister2CD71
                CD71Level=sister2CD71/sister1CD71;
            else
                CD71Level=sister1CD71/sister2CD71;
            end

            if ~isnan(CD71Level)
                LevelSuffix= sprintf('%.4f', CD71Level);
                LevelSuffix=strsplit(LevelSuffix,'.');
                LevelSuffix=[LevelSuffix{1},'_',LevelSuffix{2}];
            else
                LevelSuffix='NaN';
            end

           
            if ~strcmp(LevelSuffix,'NaN') %only plot if something is there to show
                % Show Position of Field Of View in Position Viewer
                h=subplottight(3,2,1);
                for i=1:NumberPositions %comes from GetMetaData.m
                    rectangle('Position',[Positions_XY(i,1), -Positions_XY(i,2), 2048*MicrometerPerPixel, 2048*MicrometerPerPixel])
                end
                offset=[Positions_XY(pos,1), -Positions_XY(pos,2)];     %Origin position of pos in um coordinated for BIGGER PICTURE
                rectangle('Position',[offset, 2048*MicrometerPerPixel,2048*MicrometerPerPixel],'EdgeColor','r','FaceColor','r')


                % Mark identified cells on the last tracked BF1 image
                subplottight(3,2,2);
                imshow(ahisteq)
                hold on
                scatter(Colonydata(end-1,2,3),Colonydata(end-1,2,4),'red')
                scatter(Colonydata(end-1,3,3),Colonydata(end-1,3,4),'yellow') % use last tracked TP 


                % Show CD71 and Lysosome Dynamics, CD71 Asymmetry Level will be written into file header for quick sorting 
                subplottight(3,2,3); 
                plot(Colonydata(:,:,1))
                text(20,min(min(Colonydata(:,:,1))),'CD71 Expression','HorizontalAlignment','left')
                subplottight(3,2,4); 
                plot(Colonydata(:,:,2))
                text(20,min(min(Colonydata(:,:,2))),'Lysosome Level','HorizontalAlignment','left')


                % Show Centroid X and Y over time for User to quickly dismiss tracking mistakes
                subplottight(3,2,5); 
                plot(Colonydata(:,:,3))
                text(20,min(min(Colonydata(:,:,3))),'Centroid X','HorizontalAlignment','left')
                subplottight(3,2,6); 
                plot(Colonydata(:,:,4))
                text(20,min(min(Colonydata(:,:,4))),'Centroid Y','HorizontalAlignment','left')



                %Outputname
                Detectionoutput=[DetectedFolder,LevelSuffix,'_',position,'_',num2str(Coloniesfound(col)),'.png'];


                %save the figure to png
                saveas(gcf,Detectionoutput)
                close all 

            end
        end         
    end

%end









%Plot where the colony is in position
    %Colorpanel={'black','blue','red'};%black=mother, blue=cell2, red=cell3 important to map migration to expression for picking buy user
    %for track=1:3
        %if track < size(Colonydata,2)
            %MigrationpatternPixels=[Colonydata(:,track,3),Colonydata(:,track,4)];
            %MigrationpatternMicrons=MigrationpatternPixels.*MicrometerPerPixel;
            %MigrationpatternMicronsPLUSoffset=MigrationpatternMicrons+offset;
            %line(MigrationpatternMicronsPLUSoffset(:,1),MigrationpatternMicronsPLUSoffset(:,2),'color',Colorpanel{track});
            
       % end


    


