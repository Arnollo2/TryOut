
% This script is first envoked when 5 frames have been acquired.
% it generates the dataframe rawdatatableCATallFiles that is the pivot
% variable for tracking 

% its information is retrieved from the CurrentwindowCSVs created by
% running ReadInCSVs

% the tracking itself is just centroid based tracking performed on the
% euclidean distance in XY and if not sufficient also on intensities

TrackedName=[position,'_tracked'];

%% TP
TP=currentTP-CenterofWindow+1; %Dirk assumed currenTP to be centered in window, when this is first performed (FIRST PASS) it is at end of window!

%% minTP
minTP=StartingTP;

%% PrimaryTrackingparameters
TrackingParameter1string  = 'CentroidX';
TrackingParameter2string  = 'CentroidY';
TrackingParameter1logical = strcmp(cHeader, TrackingParameter1string);
TrackingParameter2logical = strcmp(cHeader, TrackingParameter2string);
primaryTrackingParameter1        = find(TrackingParameter1logical == 1);
primaryTrackingParameter2        = find(TrackingParameter2logical == 1);

%% SumBgCorrectedChannelColumn
s=strfind(cHeader,'SumBgCorrected');
SumBgCorrectedChannelColumn=find(~cellfun(@isempty, s));

%% AreaPercentile & StdSumCh00Percentile 
AreaPercentile=150;
StdSumCh00Percentile=0.1;

%% currentPosition
currentPosition = pos;

%% rawdatatableCATallFiles

%% initialize when the first X Files have been analysed(X=BinsizeTP)
if FirstPass 
   cHeader2=cHeader;

   TimePointColumn=find(~cellfun(@isempty,strfind(cHeader,'TimePoint')));
    
    %% CatchUp Tracking
    for catchup=1:CenterofWindow %catch up in tracking. Start from  Starting TP at Position1 in CurrentWindow at time of FirstPass
       
        %Update TP
        tp = TP - CenterofWindow + catchup; %So in First iteration actual TP is at CenterofWindow, Set to ) and iterate to center
        
        if tp == minTP %if we just started tracking --> Initialize, so we skip the firstTPCSV --> ATILA MOVES TP-1 TP TP+1 TP+2 TP) does not exist          
            
            %%"LastTP" table
            %does not exist yet
            
            %%"currenTP" table
            FirstCSV=CurrentWindowCSVs{catchup,1}; 
            if ~isempty(FirstCSV)
                Colony=zeros(size(FirstCSV,1),1); %how many objects detected in the beginning? 
                Colony=mat2cell(Colony,ones(size(Colony,1),1),1);
                FirstCSV=horzcat(FirstCSV,Colony);
                %Add another column for TrackNumber and assign mother cell status
                TrackNumber=zeros(size(FirstCSV,1),1);
                TrackNumber=mat2cell(TrackNumber,ones(size(TrackNumber,1),1),1);
                FirstCSV=horzcat(FirstCSV,TrackNumber);%not actually Colo
                %Initially all objects are active!
                ActiveLogicalCell=ones(size(FirstCSV,1),1);
                ActiveLogicalCell=mat2cell(ActiveLogicalCell,ones(size(ActiveLogicalCell,1),1),1);
                FirstCSV=horzcat(FirstCSV,ActiveLogicalCell);
            end
            
            %%"nextTP" table
            SecondCSV=CurrentWindowCSVs{catchup+1,1};
            if ~isempty(SecondCSV)
                Colony=zeros(size(SecondCSV,1),1); %how many objects detected in the beginning? 
                Colony=mat2cell(Colony,ones(size(Colony,1),1),1);
                SecondCSV=horzcat(SecondCSV,Colony);
                TrackNumber=zeros(size(SecondCSV,1),1);
                TrackNumber=mat2cell(TrackNumber,ones(size(TrackNumber,1),1),1);
                SecondCSV=horzcat(SecondCSV,TrackNumber);
                ActiveLogicalCell=ones(size(SecondCSV,1),1);
                ActiveLogicalCell=mat2cell(ActiveLogicalCell,ones(size(ActiveLogicalCell,1),1),1);
                SecondCSV=horzcat(SecondCSV,ActiveLogicalCell);
            end
            
            %%"secondnextTP" table           
            ThirdCSV=CurrentWindowCSVs{catchup+2,1}; %should be in center of window now
            if ~isempty(ThirdCSV)
                Colony=zeros(size(ThirdCSV,1),1); %how many objects detected in the beginning? 
                Colony=mat2cell(Colony,ones(size(Colony,1),1),1);
                ThirdCSV=horzcat(ThirdCSV,Colony);
                TrackNumber=zeros(size(ThirdCSV,1),1);
                TrackNumber=mat2cell(TrackNumber,ones(size(TrackNumber,1),1),1);
                ThirdCSV=horzcat(ThirdCSV,TrackNumber);
                ActiveLogicalCell=TrackingWindowActive{catchup+2,1};
                ActiveLogicalCell=mat2cell(ActiveLogicalCell,ones(size(ActiveLogicalCell,1),1),1);
                ThirdCSV=horzcat(ThirdCSV,ActiveLogicalCell);
            end
            
            %%assemble the table 
            rawdatatableCATallFiles=vertcat(FirstCSV,SecondCSV,ThirdCSV);
            %Create Header for table on which tracking is based 
            cHeader2{end+1}='Colony';
            cHeader2{end+1}='TrackNumber';
            cHeader2{end+1}='active';
            a=cellfun(@str2num,rawdatatableCATallFiles(:,1:numel(cHeader2)-3));
            b=cellfun(@isempty,rawdatatableCATallFiles(:,(numel(cHeader2)-2):end));
            subsetindex=find(b==0);
            c=rawdatatableCATallFiles(:,(numel(cHeader2)-2):end);
            d=nan(size(c));
            d(subsetindex)=cellfun(@sum,c(subsetindex));
            numberOfRows=size(d,1);
            
            if (~isempty(d) && ~isempty(a))
                rawdatatableCATallFiles=array2table([a,d],'VariableNames',cHeader2);

                %what variables are already in table?
                CurrentlyLoadedVariables=cHeader2;

                % Identifies column no. of AssignedEuclideanDistanceXY
                AssignedEuclideanDistanceXYcolumnNumber = strcmp(CurrentlyLoadedVariables,'AssignedEuclideanDistanceXY');
                if sum(AssignedEuclideanDistanceXYcolumnNumber) == 0
                    AssignedEuclideanDistanceXY                         = single(zeros(numberOfRows,1));
                    rawdatatableCATallFiles.AssignedEuclideanDistanceXY = AssignedEuclideanDistanceXY;
                end

                % Identifies column no. of AssignedEuclideanDistanceFL
                AssignedEuclideanDistanceFLcolumnNumber = strcmp(CurrentlyLoadedVariables,'AssignedEuclideanDistanceFL');
                if sum(AssignedEuclideanDistanceFLcolumnNumber) == 0
                    AssignedEuclideanDistanceFL                         = single(zeros(numberOfRows,1));
                    rawdatatableCATallFiles.AssignedEuclideanDistanceFL = AssignedEuclideanDistanceFL;
                end

                % Identifies column no. of NoOfAssignableCellsNextTP
                NoOfAssignableCellsNextTPcolumnNumber = strcmp(CurrentlyLoadedVariables,'NoOfAssignableCellsNextTP');
                if sum(NoOfAssignableCellsNextTPcolumnNumber) == 0
                    NoOfAssignableCellsNextTP                         = single(zeros(numberOfRows,1));
                    rawdatatableCATallFiles.NoOfAssignableCellsNextTP = NoOfAssignableCellsNextTP;
                end

                % Identifies column no. of NoOfAssignableCellsSecondNextTP
                NoOfAssignableCellsSecondNextTPcolumnNumber = strcmp(CurrentlyLoadedVariables,'NoOfAssignableCellsSecondNextTP');
                if sum(NoOfAssignableCellsSecondNextTPcolumnNumber) == 0
                    NoOfAssignableCellsSecondNextTP                         = single(zeros(numberOfRows,1));
                    rawdatatableCATallFiles.NoOfAssignableCellsSecondNextTP = NoOfAssignableCellsSecondNextTP;
                end

                % Identifies column no. of BetterFluorescenceIntensityFitAvailable
                BetterFluorescenceIntensityFitAvailableColumnNumber = strcmp(CurrentlyLoadedVariables,'BetterFluorescenceIntensityFitAvailable');
                if sum(BetterFluorescenceIntensityFitAvailableColumnNumber) == 0
                    BetterFluorescenceIntensityFitAvailable                         = false(numberOfRows,1);
                    rawdatatableCATallFiles.BetterFluorescenceIntensityFitAvailable = BetterFluorescenceIntensityFitAvailable;
                end

                % Identifies column no. of FluorescenceIntensityTrackOutlier
                FluorescenceIntensityTrackOutlierColumnNumber = strcmp(CurrentlyLoadedVariables,'FluorescenceIntensityTrackOutlier');
                if sum(FluorescenceIntensityTrackOutlierColumnNumber) == 0
                    FluorescenceIntensityTrackOutlier                         = false(numberOfRows,1);
                    rawdatatableCATallFiles.FluorescenceIntensityTrackOutlier = FluorescenceIntensityTrackOutlier;
                end

                % Identifies column no. of Apoptosis
                FluorescenceIntensityTrackOutlierColumnNumber = strcmp(CurrentlyLoadedVariables,'Apoptosis');
                if sum(FluorescenceIntensityTrackOutlierColumnNumber) == 0
                    Apoptosis                         = false(numberOfRows,1);
                    rawdatatableCATallFiles.Apoptosis = Apoptosis;
                end

                % Identifies column no. of Division
                FluorescenceIntensityTrackOutlierColumnNumber = strcmp(CurrentlyLoadedVariables,'Division');
                if sum(FluorescenceIntensityTrackOutlierColumnNumber) == 0
                    Division                         = false(numberOfRows,1);
                    rawdatatableCATallFiles.Division = Division;
                end

                % Identifies column no. of Lost
                FluorescenceIntensityTrackOutlierColumnNumber = strcmp(CurrentlyLoadedVariables,'Lost');
                if sum(FluorescenceIntensityTrackOutlierColumnNumber) == 0
                    Lost                         = false(numberOfRows,1);
                    rawdatatableCATallFiles.Lost = Lost;
                end


                % Identifies column no. of Error
                FluorescenceIntensityTrackOutlierColumnNumber = strcmp(CurrentlyLoadedVariables,'Error');
                if sum(FluorescenceIntensityTrackOutlierColumnNumber) == 0
                    Error                         = false(numberOfRows,1);
                    rawdatatableCATallFiles.Error = Error;
                end

                % Identifies column no. of OverSegmented
                FluorescenceIntensityTrackOutlierColumnNumber = strcmp(CurrentlyLoadedVariables,'OverSegmented');
                if sum(FluorescenceIntensityTrackOutlierColumnNumber) == 0
                    OverSegmented                         = false(numberOfRows,1);
                    rawdatatableCATallFiles.OverSegmented = OverSegmented;
                end

                % Identifies column no. of Undersegmented
                FluorescenceIntensityTrackOutlierColumnNumber = strcmp(CurrentlyLoadedVariables,'Undersegmented');
                if sum(FluorescenceIntensityTrackOutlierColumnNumber) == 0
                    Undersegmented                         = false(numberOfRows,1);
                    rawdatatableCATallFiles.Undersegmented = Undersegmented;
                end

                % Identifies column no. of Undersegmented added by AW 180530
                FluorescenceIntensityTrackOutlierColumnNumber = strcmp(CurrentlyLoadedVariables,'Undersegmented');
                if sum(FluorescenceIntensityTrackOutlierColumnNumber) == 0
                    currentTrackNumberLength                         = false(numberOfRows,1);
                    rawdatatableCATallFiles.currentTrackNumberLength = currentTrackNumberLength;
                end



                rawdatatableCATallFiles.Colony(:)                                  = 0; %resets data
                rawdatatableCATallFiles.TrackNumber(:)                             = 0; %resets data
                rawdatatableCATallFiles.AssignedEuclideanDistanceXY(:)             = 0; %resets data
                rawdatatableCATallFiles.AssignedEuclideanDistanceFL(:)             = 0; %resets data
                rawdatatableCATallFiles.NoOfAssignableCellsNextTP(:)               = 0; %resets data
                rawdatatableCATallFiles.NoOfAssignableCellsSecondNextTP(:)         = 0; %resets data
                rawdatatableCATallFiles.BetterFluorescenceIntensityFitAvailable(:) = 0; %resets data
                rawdatatableCATallFiles.FluorescenceIntensityTrackOutlier(:)       = 0; %resets data
                rawdatatableCATallFiles.Apoptosis(:)                               = 0; %resets data
                rawdatatableCATallFiles.Division(:)                                = 0; %resets data
                rawdatatableCATallFiles.Lost(:)                                    = 0; %resets data
                rawdatatableCATallFiles.Error(:)                                   = 0; %resets data
                rawdatatableCATallFiles.OverSegmented(:)                           = 0; %resets data
                rawdatatableCATallFiles.Undersegmented(:)                          = 0; %resets data
                rawdatatableCATallFiles.currentTrackNumberLength(:)                = 0; %resets data added by AW 180530

                %Update what variables are added to the table
                CurrentlyLoadedVariables = rawdatatableCATallFiles.Properties.VariableNames;

                %Intialize for tracking
                colonyCount                                                              = rawdatatableCATallFiles.TimePoint == minTP;
                Colony                                                                   = 1:sum(colonyCount);
                rawdatatableCATallFiles.Colony(colonyCount)                              = Colony';
                %assigns initial cell numbers in all colonies
                rawdatatableCATallFiles.TrackNumber(rawdatatableCATallFiles.Colony ~= 0) = 1;

                %% Now Track
                rawdatatableCATallFiles=ATILAautotrackingperTP(rawdatatableCATallFiles,...
                                                                minTP,tp,primaryTrackingParameter1,primaryTrackingParameter2,...
                                                                SumBgCorrectedChannelColumn,AreaPercentile,StdSumCh00Percentile,currentPosition);
            end
        else % we have already intialized the programm of tracking
        
            % Due to Catchup iteartion TP will now have updated once further
            % we just initialized tracking --> TP-1 does now esist and is the inital frame 
            % rawdatatableCATallFiles does exist now and needs to be appended with fourthCSV!
                  
            %%new "SecondnextTP" table           
            nextCSV=CurrentWindowCSVs{catchup+2,1}; %should be in center of window now
            if (~isempty(nextCSV))
                Colony=zeros(size(nextCSV,1),1); %how many objects detected in the beginning? 
                Colony=mat2cell(Colony,ones(size(Colony,1),1),1);
                nextCSV=horzcat(nextCSV,Colony);
                TrackNumber=zeros(size(nextCSV,1),1);
                TrackNumber=mat2cell(TrackNumber,ones(size(TrackNumber,1),1),1);
                nextCSV=horzcat(nextCSV,TrackNumber);
                ActiveLogicalCell=TrackingWindowActive{catchup+2,1};
                ActiveLogicalCell=mat2cell(ActiveLogicalCell,ones(size(ActiveLogicalCell,1),1),1);
                nextCSV=horzcat(nextCSV,ActiveLogicalCell);

                %%assemble the table 
                a=cellfun(@str2num,nextCSV(:,1:numel(cHeader2)-3));
                b=cellfun(@isempty,nextCSV(:,(numel(cHeader2)-2):end));
                subsetindex=find(b==0);
                c=nextCSV(:,(numel(cHeader2)-2):end);
                d=nan(size(c));
                d(subsetindex)=cellfun(@sum,c(subsetindex));
                numberOfRows=size(d,1);
                nextCSV=array2table([a,d],'VariableNames',cHeader2);

                %what variables are already in table?
                CurrentlyLoadedVariables=cHeader2;

                % Identifies column no. of AssignedEuclideanDistanceXY
                AssignedEuclideanDistanceXYcolumnNumber = strcmp(CurrentlyLoadedVariables,'AssignedEuclideanDistanceXY');
                if sum(AssignedEuclideanDistanceXYcolumnNumber) == 0
                    AssignedEuclideanDistanceXY                         = single(zeros(numberOfRows,1));
                    nextCSV.AssignedEuclideanDistanceXY = AssignedEuclideanDistanceXY;
                end

                % Identifies column no. of AssignedEuclideanDistanceFL
                AssignedEuclideanDistanceFLcolumnNumber = strcmp(CurrentlyLoadedVariables,'AssignedEuclideanDistanceFL');
                if sum(AssignedEuclideanDistanceFLcolumnNumber) == 0
                    AssignedEuclideanDistanceFL                         = single(zeros(numberOfRows,1));
                    nextCSV.AssignedEuclideanDistanceFL = AssignedEuclideanDistanceFL;
                end

                % Identifies column no. of NoOfAssignableCellsNextTP
                NoOfAssignableCellsNextTPcolumnNumber = strcmp(CurrentlyLoadedVariables,'NoOfAssignableCellsNextTP');
                if sum(NoOfAssignableCellsNextTPcolumnNumber) == 0
                    NoOfAssignableCellsNextTP                         = single(zeros(numberOfRows,1));
                    nextCSV.NoOfAssignableCellsNextTP = NoOfAssignableCellsNextTP;
                end

                % Identifies column no. of NoOfAssignableCellsSecondNextTP
                NoOfAssignableCellsSecondNextTPcolumnNumber = strcmp(CurrentlyLoadedVariables,'NoOfAssignableCellsSecondNextTP');
                if sum(NoOfAssignableCellsSecondNextTPcolumnNumber) == 0
                    NoOfAssignableCellsSecondNextTP                         = single(zeros(numberOfRows,1));
                    nextCSV.NoOfAssignableCellsSecondNextTP = NoOfAssignableCellsSecondNextTP;
                end

                % Identifies column no. of BetterFluorescenceIntensityFitAvailable
                BetterFluorescenceIntensityFitAvailableColumnNumber = strcmp(CurrentlyLoadedVariables,'BetterFluorescenceIntensityFitAvailable');
                if sum(BetterFluorescenceIntensityFitAvailableColumnNumber) == 0
                    BetterFluorescenceIntensityFitAvailable                         = false(numberOfRows,1);
                    nextCSV.BetterFluorescenceIntensityFitAvailable = BetterFluorescenceIntensityFitAvailable;
                end

                % Identifies column no. of FluorescenceIntensityTrackOutlier
                FluorescenceIntensityTrackOutlierColumnNumber = strcmp(CurrentlyLoadedVariables,'FluorescenceIntensityTrackOutlier');
                if sum(FluorescenceIntensityTrackOutlierColumnNumber) == 0
                    FluorescenceIntensityTrackOutlier                         = false(numberOfRows,1);
                    nextCSV.FluorescenceIntensityTrackOutlier = FluorescenceIntensityTrackOutlier;
                end

                % Identifies column no. of Apoptosis
                FluorescenceIntensityTrackOutlierColumnNumber = strcmp(CurrentlyLoadedVariables,'Apoptosis');
                if sum(FluorescenceIntensityTrackOutlierColumnNumber) == 0
                    Apoptosis                         = false(numberOfRows,1);
                    nextCSV.Apoptosis = Apoptosis;
                end

                % Identifies column no. of Division
                FluorescenceIntensityTrackOutlierColumnNumber = strcmp(CurrentlyLoadedVariables,'Division');
                if sum(FluorescenceIntensityTrackOutlierColumnNumber) == 0
                    Division                         = false(numberOfRows,1);
                    nextCSV.Division = Division;
                end

                % Identifies column no. of Lost
                FluorescenceIntensityTrackOutlierColumnNumber = strcmp(CurrentlyLoadedVariables,'Lost');
                if sum(FluorescenceIntensityTrackOutlierColumnNumber) == 0
                    Lost                         = false(numberOfRows,1);
                    nextCSV.Lost = Lost;
                end


                % Identifies column no. of Error
                FluorescenceIntensityTrackOutlierColumnNumber = strcmp(CurrentlyLoadedVariables,'Error');
                if sum(FluorescenceIntensityTrackOutlierColumnNumber) == 0
                    Error                         = false(numberOfRows,1);
                    nextCSV.Error = Error;
                end

                % Identifies column no. of OverSegmented
                FluorescenceIntensityTrackOutlierColumnNumber = strcmp(CurrentlyLoadedVariables,'OverSegmented');
                if sum(FluorescenceIntensityTrackOutlierColumnNumber) == 0
                    OverSegmented                         = false(numberOfRows,1);
                    nextCSV.OverSegmented = OverSegmented;
                end

                % Identifies column no. of Undersegmented
                FluorescenceIntensityTrackOutlierColumnNumber = strcmp(CurrentlyLoadedVariables,'Undersegmented');
                if sum(FluorescenceIntensityTrackOutlierColumnNumber) == 0
                    Undersegmented                         = false(numberOfRows,1);
                    nextCSV.Undersegmented = Undersegmented;
                end

                % Identifies column no. of currentTrackNumberLength added by AW 180530
                FluorescenceIntensityTrackOutlierColumnNumber = strcmp(CurrentlyLoadedVariables,'Undersegmented');
                if sum(FluorescenceIntensityTrackOutlierColumnNumber) == 0
                    currentTrackNumberLength                         = false(numberOfRows,1);
                    nextCSV.currentTrackNumberLength = currentTrackNumberLength;
                end


                nextCSV.Colony(:)                                  = 0; %resets data
                nextCSV.TrackNumber(:)                             = 0; %resets data
                nextCSV.AssignedEuclideanDistanceXY(:)             = 0; %resets data
                nextCSV.AssignedEuclideanDistanceFL(:)             = 0; %resets data
                nextCSV.NoOfAssignableCellsNextTP(:)               = 0; %resets data
                nextCSV.NoOfAssignableCellsSecondNextTP(:)         = 0; %resets data
                nextCSV.BetterFluorescenceIntensityFitAvailable(:) = 0; %resets data
                nextCSV.FluorescenceIntensityTrackOutlier(:)       = 0; %resets data
                nextCSV.Apoptosis(:)                               = 0; %resets data
                nextCSV.Division(:)                                = 0; %resets data
                nextCSV.Lost(:)                                    = 0; %resets data
                nextCSV.Error(:)                                   = 0; %resets data
                nextCSV.OverSegmented(:)                           = 0; %resets data
                nextCSV.Undersegmented(:)                          = 0; %resets data
                nextCSV.currentTrackNumberLength(:)                = 0; %resets data added by AW 180530

                %Update what variables are added to the table
                CurrentlyLoadedVariables = nextCSV.Properties.VariableNames;
            end
            
            %append ForuthCSV to rawcarawdatatableCATallFiles
            if (size(rawdatatableCATallFiles,2)==size(nextCSV,2)) %might be that nextCSV Exist but not the others
                rawdatatableCATallFiles=vertcat(rawdatatableCATallFiles,nextCSV);
                %% continue tracking
                if(~isempty(rawdatatableCATallFiles))
                    if length(unique(rawdatatableCATallFiles.Position))== 1
                        if unique(rawdatatableCATallFiles.Position)== pos
                        rawdatatableCATallFiles=ATILAautotrackingperTP(rawdatatableCATallFiles,...
                                                            minTP,tp,primaryTrackingParameter1,primaryTrackingParameter2,...
                                                            SumBgCorrectedChannelColumn,AreaPercentile,StdSumCh00Percentile,currentPosition);
                        end
                    end
                end
            end
            
        end % checked if tracking had to be initialized
        
    
    end %next step of catchup

 
    %Write out Tracking results, When writing out for first time, we can
    %write out from first to 4th timepoint!
    textHeader2= [CurrentlyLoadedVariables;repmat({';'},1,numel(CurrentlyLoadedVariables))]; %insert commaas
    textHeader2 = textHeader2(:)';
    textHeader2 = cell2mat(textHeader2); %cHeader in text with commas

    fid = fopen([OutputFolder,TrackedName,'.csv'],'w'); 
    fprintf(fid,'%s\n',textHeader2);
    fclose(fid);

    %make rawdatatableCATallFiles ready for next round by popping the first tp, when appending next currentTP
    %in the following iteration on the other end of the window, it is like sliding
    Data2bepoped=CurrentWindowCSVs{1,1};
    if ~isempty(Data2bepoped)
        Timepoint2pop=unique(str2num(Data2bepoped{1,TimePointColumn}));
        Timepoint2popLogical=rawdatatableCATallFiles.TimePoint==Timepoint2pop;
    
        %currentTP is secondNextTP in CSVWindow and not tracked
        tobewrittenout=rawdatatableCATallFiles(rawdatatableCATallFiles.TimePoint~=currentTP,:);
        dlmwrite([OutputFolder,TrackedName,'.csv'],table2array(tobewrittenout) ,'-append','delimiter',';');

        %Pop the data from rawdatatableCATallFiles
        rawdatatableCATallFiles=rawdatatableCATallFiles(rawdatatableCATallFiles.TimePoint~=Timepoint2pop,:);
    end
    
    %if we have initialized rawdatatableCatallFiles for the first time, we need to save it and reload it again for every future visit of this position
    save([OutputFolder,'rawdatatableCATallFiles.mat'],'rawdatatableCATallFiles');
    
else %this is passed  for first time  when for second time there were more than BinsizeTP Images analysed and tracking has been initialized 

    %% Proceed but for every additional Timepoint coming in, pop first timepoint in window and append to csv in Online File
    
    % first we have to reload the rawdatatableCATallFiles file specific to
    % the current position
    load([OutputFolder,'\rawdatatableCATallFiles.mat']);
    
    %%new "SecondnextTP" table           
    nextCSV=CurrentWindowCSVs{BinSizeTPs,1}; %should be in center of window now
    if ~(isempty(nextCSV))
        Colony=zeros(size(nextCSV,1),1); %how many objects detected in the beginning? 
        Colony=mat2cell(Colony,ones(size(Colony,1),1),1);
        nextCSV=horzcat(nextCSV,Colony);
        TrackNumber=zeros(size(nextCSV,1),1);
        TrackNumber=mat2cell(TrackNumber,ones(size(TrackNumber,1),1),1);
        nextCSV=horzcat(nextCSV,TrackNumber);
        ActiveLogicalCell=TrackingWindowActive{BinSizeTPs,1};
        ActiveLogicalCell=mat2cell(ActiveLogicalCell,ones(size(ActiveLogicalCell,1),1),1);
        nextCSV=horzcat(nextCSV,ActiveLogicalCell);

        %%assemble the table 
        a=cellfun(@str2num,nextCSV(:,1:numel(cHeader2)-3));
        b=cellfun(@isempty,nextCSV(:,(numel(cHeader2)-2):end));
        subsetindex=find(b==0);
        c=nextCSV(:,(numel(cHeader2)-2):end);
        d=nan(size(c));
        d(subsetindex)=cellfun(@sum,c(subsetindex));
        numberOfRows=size(d,1);
        nextCSV=array2table([a,d],'VariableNames',cHeader2);

        %what variables are already in table?
        CurrentlyLoadedVariables=cHeader2;

        % Identifies column no. of AssignedEuclideanDistanceXY
        AssignedEuclideanDistanceXYcolumnNumber = strcmp(CurrentlyLoadedVariables,'AssignedEuclideanDistanceXY');
        if sum(AssignedEuclideanDistanceXYcolumnNumber) == 0
            AssignedEuclideanDistanceXY                         = single(zeros(numberOfRows,1));
            nextCSV.AssignedEuclideanDistanceXY = AssignedEuclideanDistanceXY;
        end

        % Identifies column no. of AssignedEuclideanDistanceFL
        AssignedEuclideanDistanceFLcolumnNumber = strcmp(CurrentlyLoadedVariables,'AssignedEuclideanDistanceFL');
        if sum(AssignedEuclideanDistanceFLcolumnNumber) == 0
            AssignedEuclideanDistanceFL                         = single(zeros(numberOfRows,1));
            nextCSV.AssignedEuclideanDistanceFL = AssignedEuclideanDistanceFL;
        end

        % Identifies column no. of NoOfAssignableCellsNextTP
        NoOfAssignableCellsNextTPcolumnNumber = strcmp(CurrentlyLoadedVariables,'NoOfAssignableCellsNextTP');
        if sum(NoOfAssignableCellsNextTPcolumnNumber) == 0
            NoOfAssignableCellsNextTP                         = single(zeros(numberOfRows,1));
            nextCSV.NoOfAssignableCellsNextTP = NoOfAssignableCellsNextTP;
        end

        % Identifies column no. of NoOfAssignableCellsSecondNextTP
        NoOfAssignableCellsSecondNextTPcolumnNumber = strcmp(CurrentlyLoadedVariables,'NoOfAssignableCellsSecondNextTP');
        if sum(NoOfAssignableCellsSecondNextTPcolumnNumber) == 0
            NoOfAssignableCellsSecondNextTP                         = single(zeros(numberOfRows,1));
            nextCSV.NoOfAssignableCellsSecondNextTP = NoOfAssignableCellsSecondNextTP;
        end

        % Identifies column no. of BetterFluorescenceIntensityFitAvailable
        BetterFluorescenceIntensityFitAvailableColumnNumber = strcmp(CurrentlyLoadedVariables,'BetterFluorescenceIntensityFitAvailable');
        if sum(BetterFluorescenceIntensityFitAvailableColumnNumber) == 0
            BetterFluorescenceIntensityFitAvailable                         = false(numberOfRows,1);
            nextCSV.BetterFluorescenceIntensityFitAvailable = BetterFluorescenceIntensityFitAvailable;
        end

        % Identifies column no. of FluorescenceIntensityTrackOutlier
        FluorescenceIntensityTrackOutlierColumnNumber = strcmp(CurrentlyLoadedVariables,'FluorescenceIntensityTrackOutlier');
        if sum(FluorescenceIntensityTrackOutlierColumnNumber) == 0
            FluorescenceIntensityTrackOutlier                         = false(numberOfRows,1);
            nextCSV.FluorescenceIntensityTrackOutlier = FluorescenceIntensityTrackOutlier;
        end

        % Identifies column no. of Apoptosis
        FluorescenceIntensityTrackOutlierColumnNumber = strcmp(CurrentlyLoadedVariables,'Apoptosis');
        if sum(FluorescenceIntensityTrackOutlierColumnNumber) == 0
            Apoptosis                         = false(numberOfRows,1);
            nextCSV.Apoptosis = Apoptosis;
        end

        % Identifies column no. of Division
        FluorescenceIntensityTrackOutlierColumnNumber = strcmp(CurrentlyLoadedVariables,'Division');
        if sum(FluorescenceIntensityTrackOutlierColumnNumber) == 0
            Division                         = false(numberOfRows,1);
            nextCSV.Division = Division;
        end

        % Identifies column no. of Lost
        FluorescenceIntensityTrackOutlierColumnNumber = strcmp(CurrentlyLoadedVariables,'Lost');
        if sum(FluorescenceIntensityTrackOutlierColumnNumber) == 0
            Lost                         = false(numberOfRows,1);
            nextCSV.Lost = Lost;
        end


        % Identifies column no. of Error
        FluorescenceIntensityTrackOutlierColumnNumber = strcmp(CurrentlyLoadedVariables,'Error');
        if sum(FluorescenceIntensityTrackOutlierColumnNumber) == 0
            Error                         = false(numberOfRows,1);
            nextCSV.Error = Error;
        end

        % Identifies column no. of OverSegmented
        FluorescenceIntensityTrackOutlierColumnNumber = strcmp(CurrentlyLoadedVariables,'OverSegmented');
        if sum(FluorescenceIntensityTrackOutlierColumnNumber) == 0
            OverSegmented                         = false(numberOfRows,1);
            nextCSV.OverSegmented = OverSegmented;
        end

        % Identifies column no. of Undersegmented
        FluorescenceIntensityTrackOutlierColumnNumber = strcmp(CurrentlyLoadedVariables,'Undersegmented');
        if sum(FluorescenceIntensityTrackOutlierColumnNumber) == 0
            Undersegmented                         = false(numberOfRows,1);
            nextCSV.Undersegmented = Undersegmented;
        end

        % Identifies column no. of currentTrackNumberLength added by AW 180530
        FluorescenceIntensityTrackOutlierColumnNumber = strcmp(CurrentlyLoadedVariables,'Undersegmented');
        if sum(FluorescenceIntensityTrackOutlierColumnNumber) == 0
            currentTrackNumberLength                         = false(numberOfRows,1);
            nextCSV.currentTrackNumberLength = currentTrackNumberLength;
        end


        nextCSV.Colony(:)                                  = 0; %resets data
        nextCSV.TrackNumber(:)                             = 0; %resets data
        nextCSV.AssignedEuclideanDistanceXY(:)             = 0; %resets data
        nextCSV.AssignedEuclideanDistanceFL(:)             = 0; %resets data
        nextCSV.NoOfAssignableCellsNextTP(:)               = 0; %resets data
        nextCSV.NoOfAssignableCellsSecondNextTP(:)         = 0; %resets data
        nextCSV.BetterFluorescenceIntensityFitAvailable(:) = 0; %resets data
        nextCSV.FluorescenceIntensityTrackOutlier(:)       = 0; %resets data
        nextCSV.Apoptosis(:)                               = 0; %resets data
        nextCSV.Division(:)                                = 0; %resets data
        nextCSV.Lost(:)                                    = 0; %resets data
        nextCSV.Error(:)                                   = 0; %resets data
        nextCSV.OverSegmented(:)                           = 0; %resets data
        nextCSV.Undersegmented(:)                          = 0; %resets data
        nextCSV.currentTrackNumberLength(:)                = 0; %resets data added by AW 180530

        %Update what variables are added to the table
        CurrentlyLoadedVariables = nextCSV.Properties.VariableNames;


        %append nextCSV to rawcarawdatatableCATallFiles
        if(~isempty(rawdatatableCATallFiles))
            if length(unique(rawdatatableCATallFiles.Position))== 1
            
                if unique(rawdatatableCATallFiles.Position)== pos
                    rawdatatableCATallFiles=vertcat(rawdatatableCATallFiles,nextCSV);


                    %now pop data and append the data
                    Data2bepoped=CurrentWindowCSVs{1,1};
                    if ~isempty(Data2bepoped)
                        Timepoint2pop=unique(str2num(Data2bepoped{1,TimePointColumn}));
                        Timepoint2pop=Timepoint2pop-1;%because currentwindow is already one step further than rawdatatableCATallFiles
                        Timepoint2popLogical=rawdatatableCATallFiles.TimePoint==Timepoint2pop;
                        %tobewrittenout=rawdatatableCATallFiles(rawdatatableCATallFiles.TimePoint==Timepoint2pop,:);
                    end


                %Pop the data from rawdatatableCATallFiles
                    rawdatatableCATallFiles=rawdatatableCATallFiles(rawdatatableCATallFiles.TimePoint~=Timepoint2pop,:);

                    %% continue tracking
                    rawdatatableCATallFiles=ATILAautotrackingperTP(rawdatatableCATallFiles,...
                                                    minTP,TP,primaryTrackingParameter1,primaryTrackingParameter2,...
                                                    SumBgCorrectedChannelColumn,AreaPercentile,StdSumCh00Percentile,currentPosition);

                    tobewrittenout=rawdatatableCATallFiles(rawdatatableCATallFiles.TimePoint==currentTP-1,:);
                    dlmwrite([OutputFolder,TrackedName,'.csv'],table2array(tobewrittenout) ,'-append','delimiter',';');
                end
            end
        end
    end
    
    %if we have initialized rawdatatableCatallFiles for the first time, we need to save it and reload it again for every future visit of this position
    save([OutputFolder,'rawdatatableCATallFiles.mat'],'rawdatatableCATallFiles');

end
 