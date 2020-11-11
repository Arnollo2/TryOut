function [rawdatatableCATallFiles] = ATILAautotrackingperTP(rawdatatableCATallFiles,minTP,TP,primaryTrackingParameter1,primaryTrackingParameter2,SumBgCorrectedChannelColumn,AreaPercentile,StdSumCh00Percentile,currentPosition)
%%
pushbutton_ExcludeCloseColoniesAtStart=1;
pushbutton_ExcludeEdgeColonies=1;
minColonyDistanceAtStart=50;
maxTrackDistance=50;
maxTPperCellCycle=2;
maxColonyCellNumber=64;
PercentageFromEdgeToExclude=2;
ImageHeight=2048;
ImageWidth=2048;
CurrentlyLoadedVariables=rawdatatableCATallFiles.Properties.VariableNames;

AssignedEuclideanDistanceXYcolumnNumber = strcmp(CurrentlyLoadedVariables,'AssignedEuclideanDistanceXY');
AssignedEuclideanDistanceFLcolumnNumber = strcmp(CurrentlyLoadedVariables,'AssignedEuclideanDistanceFL');
%NoOfAssignableCellsNextTPcolumnNumber = strcmp(CurrentlyLoadedVariables,'NoOfAssignableCellsNextTP');
%NoOfAssignableCellsSecondNextTPcolumnNumber = strcmp(CurrentlyLoadedVariables,'NoOfAssignableCellsSecondNextTP');
%BetterFluorescenceIntensityFitAvailableColumnNumber = strcmp(CurrentlyLoadedVariables,'BetterFluorescenceIntensityFitAvailable');



%excludes colony that are in close proimity at minTP in order
%to exclude them from tracking
if pushbutton_ExcludeCloseColoniesAtStart == 1 && TP == minTP
    fprintf('Position %03d TimePoint %03d - APPLY FILTER - remove starting cells in close proximity to each other...\n', currentPosition, TP);

    rawdatatableCATallFilesFirstTPlogical = rawdatatableCATallFiles.TimePoint == minTP;
    rawdatatableCATallFilesFirstTP        = rawdatatableCATallFiles(rawdatatableCATallFilesFirstTPlogical,:);
    rawdatatableCATallFilesFirstTParray   = table2array(rawdatatableCATallFilesFirstTP);

    DistanceEuclideanColonyDistanceXYfirstTP = pdist(rawdatatableCATallFilesFirstTParray(:,[primaryTrackingParameter1 primaryTrackingParameter2]),'euclidean');
    EuclideanTrackDistanceXYfirstTP          = squareform(DistanceEuclideanColonyDistanceXYfirstTP);
    EuclideanTrackDistanceXYfirstTP(logical(eye(size(EuclideanTrackDistanceXYfirstTP)))) = 99999; % assing 99999 to central diagonal of matrix to get rid of 0

    % identifies rows of cells that are close to other cell at
    % TP0
    EuclideanTrackDistanceXYfirstTPtoBeExcludedValuesLogical = EuclideanTrackDistanceXYfirstTP < minColonyDistanceAtStart;
    [rowToCloseColonyFirstTP,columnToCloseColonyFirstTP]     = find(tril(EuclideanTrackDistanceXYfirstTPtoBeExcludedValuesLogical));

    % set Colony and TrackNumber of to dense cells at TP1 to 0
    % and excludes them from further processing
    rawdatatableCATallFiles.Colony(rowToCloseColonyFirstTP,:)      = 0;
    rawdatatableCATallFiles.TrackNumber(rowToCloseColonyFirstTP,:) = 0;

    rawdatatableCATallFiles.Colony(columnToCloseColonyFirstTP,:)      = 0;
    rawdatatableCATallFiles.TrackNumber(columnToCloseColonyFirstTP,:) = 0;
end


%%
%excludes colony that are in close proimity at minTP in order
%to exclude them from tracking
if pushbutton_ExcludeEdgeColonies == 1 && TP == minTP
    fprintf('Position %03d TimePoint %03d - APPLY FILTER - remove starting cells in close proximity to edge...\n', currentPosition, TP);
    UpperPixelCoordinateThresholdImageHeight = ImageHeight - round(ImageHeight/100 * PercentageFromEdgeToExclude);   % calculate upper limit of image pixel dimension height
    UpperPixelCoordinateThresholdImageWidth  = ImageWidth  - round(ImageWidth/100  * PercentageFromEdgeToExclude);   % calculate upper limit of image pixel dimension width
    LowerPixelCoordinateThresholdImageWidth  = round(ImageWidth/100  * PercentageFromEdgeToExclude);                 % calculate lower limit of image pixel dimension height
    LowerPixelCoordinateThresholdImageHeight = round(ImageHeight/100 * PercentageFromEdgeToExclude);                 % calculate lower limit of image pixel dimension width

    rawdatatableCATallFilesFirstTPandColonyToCloseToEdgelogical = rawdatatableCATallFiles.TimePoint == minTP & rawdatatableCATallFiles.Colony ~= 0 & rawdatatableCATallFiles{:,primaryTrackingParameter1} > UpperPixelCoordinateThresholdImageHeight ...
        | rawdatatableCATallFiles.TimePoint == minTP & rawdatatableCATallFiles.Colony ~= 0 & rawdatatableCATallFiles{:,primaryTrackingParameter1} < LowerPixelCoordinateThresholdImageHeight ...
        | rawdatatableCATallFiles.TimePoint == minTP & rawdatatableCATallFiles.Colony ~= 0 & rawdatatableCATallFiles{:,primaryTrackingParameter2} > UpperPixelCoordinateThresholdImageHeight ...
        | rawdatatableCATallFiles.TimePoint == minTP & rawdatatableCATallFiles.Colony ~= 0 & rawdatatableCATallFiles{:,primaryTrackingParameter2} < LowerPixelCoordinateThresholdImageHeight ...
        | rawdatatableCATallFiles.TimePoint == minTP & rawdatatableCATallFiles.Colony ~= 0 & rawdatatableCATallFiles{:,primaryTrackingParameter1} > UpperPixelCoordinateThresholdImageWidth ...
        | rawdatatableCATallFiles.TimePoint == minTP & rawdatatableCATallFiles.Colony ~= 0 & rawdatatableCATallFiles{:,primaryTrackingParameter1} < LowerPixelCoordinateThresholdImageWidth ...
        | rawdatatableCATallFiles.TimePoint == minTP & rawdatatableCATallFiles.Colony ~= 0 & rawdatatableCATallFiles{:,primaryTrackingParameter2} > UpperPixelCoordinateThresholdImageWidth ...
        | rawdatatableCATallFiles.TimePoint == minTP & rawdatatableCATallFiles.Colony ~= 0 & rawdatatableCATallFiles{:,primaryTrackingParameter2} < LowerPixelCoordinateThresholdImageWidth;

    rawdatatableCATallFiles.Colony(rawdatatableCATallFilesFirstTPandColonyToCloseToEdgelogical,:)      = 0; % set Colony and TrackNumber of to dense cells at TP1 to 0 and excludes them from further processing
    rawdatatableCATallFiles.TrackNumber(rawdatatableCATallFilesFirstTPandColonyToCloseToEdgelogical,:) = 0; % set Colony and TrackNumber of to dense cells at TP1 to 0 and excludes them from further processing
end






%%

lastTPlogical       = rawdatatableCATallFiles.TimePoint == TP - 1 & rawdatatableCATallFiles.active == 1;
lastTP              = rawdatatableCATallFiles(lastTPlogical,:);

% extracts next Time Point data table
currentTPlogical    = rawdatatableCATallFiles.TimePoint == TP & rawdatatableCATallFiles.active == 1;
currentTP           = rawdatatableCATallFiles(currentTPlogical,:);

% extracts next Time Point data table
nextTPlogical       = rawdatatableCATallFiles.TimePoint == TP + 1 & rawdatatableCATallFiles.active == 1;
nextTParray         = rawdatatableCATallFiles(nextTPlogical,:);

% extracts second next Time Point data table
secondNextTPlogical = rawdatatableCATallFiles.TimePoint == TP + 2 & rawdatatableCATallFiles.active == 1;
secondNextTParray   = rawdatatableCATallFiles(secondNextTPlogical,:);

% extracts all inactive TP to append them in the end again so
% that they are not removed during tracking
AllTPinactiveLogical = rawdatatableCATallFiles.active == 0;
AllTPinactive        = rawdatatableCATallFiles(AllTPinactiveLogical,:);


% extract current and last 2 TP for comparison of local and
% recent features with feature of next TP to identify
% outliers
last3TPlogical = rawdatatableCATallFiles.TimePoint == TP     & rawdatatableCATallFiles.active == 1 ...
               | rawdatatableCATallFiles.TimePoint == TP - 1 & rawdatatableCATallFiles.active == 1 ...
               | rawdatatableCATallFiles.TimePoint == TP - 2 & rawdatatableCATallFiles.active == 1;

last3TParray   = rawdatatableCATallFiles(last3TPlogical,:);

currentTPcolonyNumberList = unique(currentTP.Colony);
currentTPcolonyNumberList = currentTPcolonyNumberList(currentTPcolonyNumberList ~= 0);
currentTParrayColony      = cell(numel(currentTPcolonyNumberList),1); %preallocate


%%
% lopps through TimePoints and determines minimal distance
for colonyNumberCounter = 1:numel(currentTPcolonyNumberList)

    colonyNumber = currentTPcolonyNumberList(colonyNumberCounter);

    currentColonylastTPAssignedTracksLogical = lastTP.Colony    == colonyNumber & lastTP.TrackNumber    ~= 0; 
    lastTPColony                             = lastTP(currentColonylastTPAssignedTracksLogical,:);

    currentColonyAssignedTracksLogical       = currentTP.Colony == colonyNumber & currentTP.TrackNumber ~= 0;
    currentColony                            = currentTP(currentColonyAssignedTracksLogical,:);

    currentTPnoColonyNoTrackLogical          = currentTP.Colony == 0            | currentTP.TrackNumber == 0;
    currentTPnoColonyNoTrack                 = currentTP(currentTPnoColonyNoTrackLogical,:); %saves data point which could not be assigned in order to append them later

    % Create matrix of current and next TP
    currentColonyAndNextTP      = [lastTPColony; currentColony; nextTParray; secondNextTParray];
    currentColonyAndNextTParray = double(table2array(currentColonyAndNextTP));

    fprintf('Position %03d TimePoint %03d Colony %03d Detected Cell Number %03d\n', currentPosition, TP, colonyNumber, sum(currentColonyAssignedTracksLogical));

    if ~isempty(currentColony) && size(currentColonyAndNextTP,1) > 1

        % Determine unwighted euclidean distance of XY coordinates
        DistanceEuclideanXY         = pdist(currentColonyAndNextTParray(:,[primaryTrackingParameter1 primaryTrackingParameter2]),'euclidean');
        EuclideanTrackDistanceXY    = squareform(DistanceEuclideanXY);

        % Determine unwighted normalied euclidean distance
        % of all background corrected fluorescence channel
        DistanceEuclideanFluorescence      = pdist(currentColonyAndNextTParray(:,SumBgCorrectedChannelColumn),'seuclidean');
        EuclideanTrackDistanceFluorescence = squareform(DistanceEuclideanFluorescence);

        % set all already assigned rowns of nextTP to
        % 99999 to prevent double assignment
        alreadyAssignedRowsLogical = currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TrackNumber ~= 0 & currentColonyAndNextTP.TimePoint == TP + 1;
        EuclideanTrackDistanceXY(alreadyAssignedRowsLogical,:)           = 99999;
        EuclideanTrackDistanceFluorescence(alreadyAssignedRowsLogical,:) = 99999;

        % define cells that belong to current colony in next TP
        EuclideanTrackDistanceColonyXY   = EuclideanTrackDistanceXY;
        EuclideanTrackDistanceColonyFL   = EuclideanTrackDistanceFluorescence;
        EuclidianDistanceThresholdColony = maxTrackDistance;

        % assigns 99999 to diagonal to remove 0
        % which interfere with euclidean
        % minimum
        EuclideanTrackDistanceXY(logical(eye(size(EuclideanTrackDistanceXY))))                     = 99999;
        EuclideanTrackDistanceColonyXY(logical(eye(size(EuclideanTrackDistanceColonyXY))))         = 99999;
        EuclideanTrackDistanceFluorescence(logical(eye(size(EuclideanTrackDistanceFluorescence)))) = 99999;

        %>>>>>>>>>>>>> Assign Colony numbers in next TP and
        %second next TP
        EuclideanDistanceThresholdcurrentTPColonyFilterLogical = currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TrackNumber ~= 0;
        EuclideanDistanceThresholdcurrentTPColonyFilterLogical = EuclideanDistanceThresholdcurrentTPColonyFilterLogical';
        EuclideanDistanceThresholdnextTPColonyFilterLogical    = currentColonyAndNextTP.TimePoint == TP + 1 | currentColonyAndNextTP.TimePoint == TP + 2 & currentColonyAndNextTP.Colony == 0;

        % filters for column in euclidean matrix that have
        % already been assigned to current colony in
        % current TP
        EuclideanDistanceThreshold4TrackAssignment = EuclideanTrackDistanceColonyXY(:,EuclideanDistanceThresholdcurrentTPColonyFilterLogical);

        % creates 0 and matrix to filter on TP+1 ony in already assigned columns
        EuclideanDistanceThresholdnextTPColonyFilterLogicalMatrix = repmat(EuclideanDistanceThresholdnextTPColonyFilterLogical,1,size(EuclideanDistanceThreshold4TrackAssignment,2));

        %Logical Vector required for Trackassignment - identifies values that belong to next TP and current colony Number
        EuclideanDistanceThreshold4TrackAssignmentLogical = EuclideanDistanceThreshold4TrackAssignment < EuclidianDistanceThresholdColony & EuclideanDistanceThresholdnextTPColonyFilterLogicalMatrix == 1;

        % assign Colony Number to all objects below
        % Euclidean Threshold
        currentColonyAndNextTP.Colony(sum(EuclideanDistanceThreshold4TrackAssignmentLogical,2) > 0,:) = colonyNumber;








        % determine cell number of current colony in last TP
        currentColonylastTPAssignedTracksLogical   = currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TrackNumber ~= 0 & currentColonyAndNextTP.TimePoint == TP - 1;
        LastTPColonyCellNumber                     = sum(currentColonylastTPAssignedTracksLogical);

        % determine cell number of current colony in current TP
        currentColonycurrenTPAssignedTracksLogical = currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TrackNumber ~= 0 & currentColonyAndNextTP.TimePoint == TP;
        CurrentTPColonyCellNumber                  = sum(currentColonycurrenTPAssignedTracksLogical);

        % determine cell number of current in nextTP
        NextTPColonyCellNumberLogical              = currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TimePoint == TP + 1;
        NextTPColonyCellNumber                     = sum(NextTPColonyCellNumberLogical);

        % determine cell number of current in second nextTP
        SecondNextTPColonyCellNumberLogical        = currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TimePoint == TP + 2;
        SecondNextTPColonyCellNumber               = sum(SecondNextTPColonyCellNumberLogical);












        % Calculation of flexible criteria for cell
        % fusion event based on comparison of
        % previous trackpoints with cell in next TP
        currentTPdataLogical  = currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TrackNumber ~= 0 & currentColonyAndNextTP.TimePoint == TP;
        currentTPTrackNumbers = currentColonyAndNextTP.TrackNumber(currentTPdataLogical,:);
        last3TParrayCellMean  = cell(length(currentTPTrackNumbers),1);

        % extracts (morphological) features
        % Area, SumCh00, Eccentricity and
        % TrackLength from all cells of
        % current colony and TP to
        % determine most likey cell that
        % underwent division
        for last3TPcellCounter = 1:length(currentTPTrackNumbers)

            currenTrackNumber       = currentTPTrackNumbers(last3TPcellCounter);
            last3TParrayCellLogical = last3TParray.Colony == colonyNumber & last3TParray.TrackNumber == currenTrackNumber;
            last3TParrayCell        = last3TParray(last3TParrayCellLogical,:);

            %calculates mean of last 3TP
            last3TParrayCellMean{last3TPcellCounter} = mean(last3TParrayCell{:,:},1);
            last3TParrayMeanCAT                      = cat(1,last3TParrayCellMean{:});

        end

        %extract columns belong to
        %background corrected
        %fluorescence channel
        last3TParrayMean                          = array2table(last3TParrayMeanCAT);
        last3TParrayMean.Properties.VariableNames = CurrentlyLoadedVariables;













        % Calculation of current Track lengths
        currentTrackNumberLength = cell(length(currentTPTrackNumbers),1);

        for last3TPcellCounter = 1:length(currentTPTrackNumbers)
            % determines length of current
            % colony and Track in order to identify
            % if cells devided recently
            currenTrackNumber                            = currentTPTrackNumbers(last3TPcellCounter);
            currentTrackNumberLengthLogical              = rawdatatableCATallFiles.Colony == colonyNumber & rawdatatableCATallFiles.TrackNumber == currenTrackNumber & rawdatatableCATallFiles.Apoptosis == 0;
            currentTrackNumberLength{last3TPcellCounter} = sum(currentTrackNumberLengthLogical);
        end





        % Defines maximal Track Length per cell to exclude
        if TP < minTP + maxTPperCellCycle + 1
            maxTrackLengthNoCellDivision = TP - 1 - minTP;
        else
            maxTrackLengthNoCellDivision = maxTPperCellCycle;
        end

        % determines which tracks of current TP are shorter
        % than user defined min Tracks Length (used
        % subsqeuently to exclude very short tracks from
        % division detection)
        TracksShorterThanUserThresholdLogical = [currentTrackNumberLength{:}] <= maxTrackLengthNoCellDivision;



        %% identify mother / daughter cells in
        % case of division

        RowIndexDividingCells = cell(NextTPColonyCellNumber - CurrentTPColonyCellNumber,1);
        RowIndexMotherCells   = cell(NextTPColonyCellNumber - CurrentTPColonyCellNumber,1);

        if NextTPColonyCellNumber > 1
            nextTPandColonyLogical                    = currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TimePoint == TP + 1;
            nextTPandColonyFluorescenceValues         = currentColonyAndNextTP(nextTPandColonyLogical,SumBgCorrectedChannelColumn);
            nextTPandColonyFluorescenceValuesArray    = table2array(nextTPandColonyFluorescenceValues);
            currentTPandColonyFluorescenceValues      = last3TParrayMean(:,SumBgCorrectedChannelColumn);
            currentTPandColonyFluorescenceValuesArray = table2array(currentTPandColonyFluorescenceValues);

            currentTPandColonyLogical       = currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TimePoint == TP;
            currentTPandColonyXYValues      = currentColonyAndNextTP(currentTPandColonyLogical,[primaryTrackingParameter1 primaryTrackingParameter2]);
            currentTPandColonyXYValuesArray = table2array(currentTPandColonyXYValues);
            nextTPandColonyLogical          = currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TimePoint == TP + 1;
            nextTPandColonyXYValues         = currentColonyAndNextTP(nextTPandColonyLogical,[primaryTrackingParameter1 primaryTrackingParameter2]);
            nextTPandColonyXYValuesArray    = table2array(nextTPandColonyXYValues);                      


            if ~isempty(currentTPandColonyFluorescenceValuesArray)
                %FL
                AddedSumBgCorrected                = [];
                SumBgCorrectedIntensitiesCurrentTP = zeros(size(currentTPandColonyFluorescenceValuesArray,1),length(SumBgCorrectedChannelColumn)); %preallocate

                for ChannelCounter = 1:length(SumBgCorrectedChannelColumn)
                    SumBgCorrectedIntensitiesNextTP                      = nextTPandColonyFluorescenceValuesArray(:,ChannelCounter);
                    SumBgCorrectedMatrixNextTP                           = repmat(SumBgCorrectedIntensitiesNextTP, 1,length(SumBgCorrectedIntensitiesNextTP));
                    SumBgCorrectedMatrixNextTPInverted                   = SumBgCorrectedMatrixNextTP';
                    AddedSumBgCorrectedMatrixNextTP                      = SumBgCorrectedMatrixNextTP + SumBgCorrectedMatrixNextTPInverted;
                    AddedSumBgCorrected(:,ChannelCounter)                = AddedSumBgCorrectedMatrixNextTP(tril(ones(length(SumBgCorrectedMatrixNextTP),length(SumBgCorrectedMatrixNextTP)),-1) == 1);
                    SumBgCorrectedIntensitiesCurrentTP(:,ChannelCounter) = currentTPandColonyFluorescenceValuesArray(:,ChannelCounter);
                end

                % uses user defined minimum TrackNumber Length
                % setting and excluded tracks shorter than that
                % from division detection process for FL
                SumBgCorrectedIntensitiesCurrentTP(TracksShorterThanUserThresholdLogical',:)         = 99999;


                AddedNextTPfluorescence = [SumBgCorrectedIntensitiesCurrentTP; AddedSumBgCorrected];

                % Determine unwighted euclidean distance of FL
                DistanceEuclideanFLaddedNextTP      = pdist(AddedNextTPfluorescence,'euclidean');
                EuclideanTrackDistanceFLaddedNextTP = squareform(DistanceEuclideanFLaddedNextTP);

                % assigns 99999 to diagonal to remove 0
                % which interfere with euclidean
                % minimum
                EuclideanTrackDistanceFLaddedNextTP(logical(eye(size(EuclideanTrackDistanceFLaddedNextTP)))) = 99999;



                % XY
                MeanOfAddedPrimaryParameter    = [];
                PrimaryParameterValueCurrentTP = zeros(size(currentTPandColonyXYValuesArray,1),size(nextTPandColonyXYValuesArray,2)); %preallocate

              for primaryParameterCounter = 1:size(nextTPandColonyXYValuesArray,2)
                  PrimaryParamterValuesNextTPandColony                      = nextTPandColonyXYValuesArray(:,primaryParameterCounter);
                  nextTPandColonyXYValuesMatrix                             = repmat(PrimaryParamterValuesNextTPandColony, 1,length(PrimaryParamterValuesNextTPandColony));
                  nextTPandColonyXYValuesMatrixInverted                     = nextTPandColonyXYValuesMatrix';
                  AddedNextTPandColonyXYValuesMatrix                        = (nextTPandColonyXYValuesMatrix + nextTPandColonyXYValuesMatrixInverted) ./2;
                  MeanOfAddedPrimaryParameter(:,primaryParameterCounter)    = AddedNextTPandColonyXYValuesMatrix(tril(ones(length(nextTPandColonyXYValuesMatrix),length(nextTPandColonyXYValuesMatrix)),-1) == 1);
                  PrimaryParameterValueCurrentTP(:,primaryParameterCounter) = currentTPandColonyXYValuesArray(:,primaryParameterCounter);
              end

              % uses user defined minimum TrackNumber Length
              % setting and excluded tracks shorter than that
              % from division detection process for XY
              PrimaryParameterValueCurrentTP(TracksShorterThanUserThresholdLogical',:)         = 99999;


              AddedNextTPColonyXYValues                = [PrimaryParameterValueCurrentTP; MeanOfAddedPrimaryParameter]; 

              % Determine unwighted euclidean distance of XY
              DistanceEuclideanAddedNextTPColonyXYValues      = pdist(AddedNextTPColonyXYValues,'euclidean');
              EuclideanTrackDistanceAddedNextTPColonyXYValues = squareform(DistanceEuclideanAddedNextTPColonyXYValues);

              % assigns 99999 to diagonal to remove 0
              % which interfere with euclidean
              % minimum
              EuclideanTrackDistanceAddedNextTPColonyXYValues(logical(eye(size(EuclideanTrackDistanceAddedNextTPColonyXYValues)))) = 99999;


                for divisionCounter = 1:(NextTPColonyCellNumber - CurrentTPColonyCellNumber)

                    % XY filters euclidean matrix for data deduced from TP+1 rows (to be assigned) and TP columsn (tracks to be assigned to)
                    EuclideanTrackDistanceXYaddedNextTPComp             = EuclideanTrackDistanceAddedNextTPColonyXYValues(1 + size(PrimaryParameterValueCurrentTP,1):size(AddedNextTPColonyXYValues,1),1:size(PrimaryParameterValueCurrentTP,1));

                    % assuming a cell can have a maximum number
                    % of 9 adjacent cells (degrees of freedom)
                    % this indentifies the 9 closest added XY
                    % event of TP + 1
                    [SortedElements, SmallestColumnIdx, SmallestRowIdx] = getNElements(EuclideanTrackDistanceXYaddedNextTPComp, 9); %get sub index of n th smallest elements


                    %creates Linear index based of subindixes
                    %(required for subsquent extraction of
                    %scatter elements in array)
                    linearIdxXLaddedNextTPcomp = sub2ind(size(EuclideanTrackDistanceXYaddedNextTPComp), SmallestRowIdx, SmallestColumnIdx);


                    % FL filters euclidean matrix for data deduced from TP+1 rows (to be assigned) and TP columsn (tracks to be assigned to)
                    EuclideanTrackDistanceFLaddedNextTPComp       = EuclideanTrackDistanceFLaddedNextTP(1 + size(SumBgCorrectedIntensitiesCurrentTP,1):size(AddedNextTPfluorescence,1),1:size(SumBgCorrectedIntensitiesCurrentTP,1));
                    MeanEuclideanTrackDistanceFLaddedNextTPComp   = mean(mean(EuclideanTrackDistanceFLaddedNextTPComp(:,~TracksShorterThanUserThresholdLogical')));


                    % extracts nine smallest eucl XY and FL
                    % dist values in order to apply filter
                    % criteria 
                    NineSmallestEuclideanTrackDistanceXYaddedNextTPCompFLdistValues = EuclideanTrackDistanceFLaddedNextTPComp(linearIdxXLaddedNextTPcomp);
                    NineSmallestEuclideanTrackDistanceXYaddedNextTPCompValues       = EuclideanTrackDistanceXYaddedNextTPComp(linearIdxXLaddedNextTPcomp);


                    % filter criteria supposed to improve
                    % mother detection. Exclude putative 9 closest data point if distance of XY bigger than maxTrackDistance set by user OR eucl. FL distance bigger than mean FL eucl dist of added TP+1 value 
                    NineSmallestBiggerMeanEuclTrackDistFLaddedNextTPCompLogical = NineSmallestEuclideanTrackDistanceXYaddedNextTPCompFLdistValues  <= MeanEuclideanTrackDistanceFLaddedNextTPComp;
                    NineSmallestBiggerMaxEuclTrackDistXYaddedNextTPCompLogical  = NineSmallestEuclideanTrackDistanceXYaddedNextTPCompValues        <= maxTrackDistance;


                    LinearIdxToBeConsideredAsPutativeMotherCell = linearIdxXLaddedNextTPcomp(NineSmallestBiggerMeanEuclTrackDistFLaddedNextTPCompLogical & NineSmallestBiggerMaxEuclTrackDistXYaddedNextTPCompLogical);  

                    % Determine minimum eucl XY dist of TP+1
                    % added tracks after removing extremely
                    % unlikely matches from the 9th closest
                    % candidate tracks
                    [CurrentEuclideanTrackDistanceXYadded, minIdx] = min(EuclideanTrackDistanceXYaddedNextTPComp(LinearIdxToBeConsideredAsPutativeMotherCell));

                    % checks whether proximity of remaining
                    % most likely adjacent events is sufficient
                    % to determine accurate assignment even in
                    % dense cultures. If XY eucl dist between
                    % min and other is smaller than 5 apply
                    % additional parameter to determine mother
                    % cell
                    PutativeAlternativeMotherCellLogical = EuclideanTrackDistanceXYaddedNextTPComp(LinearIdxToBeConsideredAsPutativeMotherCell) - CurrentEuclideanTrackDistanceXYadded < 5;

                    if sum(PutativeAlternativeMotherCellLogical) > 1

                    % determines best FL fit of events closer
                    % than <5 in XY distance matrix
                    PutativeAlternativeMotherCellLinearIndex          = LinearIdxToBeConsideredAsPutativeMotherCell(PutativeAlternativeMotherCellLogical);
                    [PutativeAlternativeMotherCellFLvalues, minFLidx] = min(EuclideanTrackDistanceFLaddedNextTPComp(PutativeAlternativeMotherCellLinearIndex));
                    FLscores                                          = PutativeAlternativeMotherCellFLvalues ./ EuclideanTrackDistanceFLaddedNextTPComp(PutativeAlternativeMotherCellLinearIndex);

                    % determines max Area of events closer
                    % than <5 in XY distance matrix
                    [~, PutatveMotherColumn]                              = ind2sub(size(EuclideanTrackDistanceXYaddedNextTPComp), PutativeAlternativeMotherCellLinearIndex);
                    [PutativeAlternativeMotherCellAreavalues, maxAreaidx] = max(last3TParrayMean.Area(PutatveMotherColumn,:));
                    AreaScores                                            = last3TParrayMean.Area(PutatveMotherColumn,:) ./ PutativeAlternativeMotherCellAreavalues;

                    % determines max TrackLength of events closer
                    % than <5 in XY distance matrix
                    CurrentTrackNumberLength                                            = [currentTrackNumberLength{:}]';
                    [PutativeAlternativeMotherCellTrackLengthvalues, TrackLengthMaxidx] = max(CurrentTrackNumberLength(PutatveMotherColumn,:));
                    TrankLengthScores                                                   = CurrentTrackNumberLength(PutatveMotherColumn,:) ./ PutativeAlternativeMotherCellTrackLengthvalues;

                    PutativeAlternativeMotherScoreSummary = FLscores + AreaScores + TrankLengthScores;
                    [BestScoreValue, BestScoreIdx]        = max(PutativeAlternativeMotherScoreSummary);

                    BestScoreLinearIndex = PutativeAlternativeMotherCellLinearIndex(BestScoreIdx);

                    % overwrites best fit that is solely based
                    % on XY eucl dist. with best fit based on
                    % multiple parameter score (see above)
                    CurrentEuclideanTrackDistanceXYadded = EuclideanTrackDistanceXYaddedNextTPComp(BestScoreLinearIndex);
                    CurrentEuclideanDistanceFLadded      = EuclideanTrackDistanceFLaddedNextTPComp(BestScoreLinearIndex);

                    else    

                    % detminines the eucl FL dist from current
                    % minimum XY eucl dist. in order to exclude
                    % poor matches from division detection
                    CurrentEuclideanDistanceFLadded = EuclideanTrackDistanceFLaddedNextTPComp(LinearIdxToBeConsideredAsPutativeMotherCell);
                    CurrentEuclideanDistanceFLadded = CurrentEuclideanDistanceFLadded(minIdx);

                    end


                    if ~isempty(CurrentEuclideanTrackDistanceXYadded)

                        if CurrentEuclideanTrackDistanceXYadded == 99999 || isnan(CurrentEuclideanTrackDistanceXYadded)
                            fprintf('Daughter addition ERROR\n')
                            continue

                        elseif   CurrentEuclideanDistanceFLadded > 30 ... %detection of oversegmentation
                                & CurrentTPColonyCellNumber       < NextTPColonyCellNumber ...
                                & CurrentTPColonyCellNumber       == SecondNextTPColonyCellNumber ...
                                | CurrentEuclideanDistanceFLadded > 30 ... %detection of oversegmentation
                                & CurrentTPColonyCellNumber       > LastTPColonyCellNumber ...
                                & CurrentTPColonyCellNumber       > NextTPColonyCellNumber ...
                                & CurrentTPColonyCellNumber       > SecondNextTPColonyCellNumber

                            fprintf('Putative OVERSEGMENTATION detected ERROR\n')
                            continue

                        else

                            % identifies row/column of minimal
                            % euchlidean value in filtered eucl
                            % matrix
                            [rowNextTrackCorrectedXYaddedDaughters, rowCurrentTrackCorrectedXYaddedMother] = find(EuclideanTrackDistanceXYaddedNextTPComp == CurrentEuclideanTrackDistanceXYadded);

                            % in case multiple rows with same XY
                            % eucl distance are present, exclude
                            % all that belong to other columns
                            if length(rowCurrentTrackCorrectedXYaddedMother) > 1
                               rowCurrentTrackCorrectedXYaddedMother     = rowCurrentTrackCorrectedXYaddedMother(1);
                               [rowNextTrackCorrectedXYaddedDaughters,~] = find(EuclideanTrackDistanceXYaddedNextTPComp(:,rowCurrentTrackCorrectedXYaddedMother) == CurrentEuclideanTrackDistanceXYadded);
                            end


                            % shifts row and column index
                            % to match euclidean distance
                            % entries
                            rowNextTrackCorrectedFLaddedDaughters             = rowNextTrackCorrectedXYaddedDaughters + size(AddedSumBgCorrected,1)                 - size(EuclideanTrackDistanceFLaddedNextTPComp,1);
                            rowNextTrackCorrectedFLaddedDaughtersToBeSet99999 = rowNextTrackCorrectedXYaddedDaughters + size(EuclideanTrackDistanceFLaddedNextTP,1) - size(EuclideanTrackDistanceFLaddedNextTPComp,1);

                            % retrieves fluorescence
                            % intensitity sum of row/column
                            % coordinates corresponding to sum
                            % of daughter cells
                            AddedSumValue = zeros(size(AddedSumBgCorrected,2),1);

                            for ChannelCounter = 1:size(AddedSumBgCorrected,2)

                                AddedSumValue(ChannelCounter,1) = AddedSumBgCorrected(rowNextTrackCorrectedFLaddedDaughters(1), ChannelCounter);

                                % find coordinates of sum of
                                % daughter cell fluorescence
                                % intensities in added fluorescence
                                % matrix to identify daughter cells
                                [rowNextTPandColonyLogical,columnNextTPandColonyLogical] = find(tril(AddedSumBgCorrectedMatrixNextTP,-1) == AddedSumValue(ChannelCounter,1));

                            end

                            [rowsCurrentColonyAndNextTP,~] = find(nextTPandColonyLogical == 1);

                            % Saves rows indices of mother
                            % and dividing cells
                            RowIndexDividingCells{divisionCounter} = rowsCurrentColonyAndNextTP([rowNextTPandColonyLogical,columnNextTPandColonyLogical],1);

                            % exclusion criteria for division
                            PutativeDebrisQClogical = currentColonyAndNextTP.Area <= AreaPercentile(1) & currentColonyAndNextTP.StdDevSignalBF1 <= StdSumCh00Percentile(1);
                            PutativeDebrisQCidx     = find(PutativeDebrisQClogical == 1);

                            if sum(ismember(RowIndexDividingCells{divisionCounter},PutativeDebrisQCidx)) > 0 
                               RowIndexDividingCells{divisionCounter} = [];
                            else
                               RowIndexMotherCells{divisionCounter}   = rowCurrentTrackCorrectedXYaddedMother + LastTPColonyCellNumber;
                            end

                            % sets already assigned /
                            % extracted data point in
                            % euclidean matrix to 99999 so
                            % they wont be used again in
                            % additional loops
                            EuclideanTrackDistanceFLaddedNextTP(:,rowCurrentTrackCorrectedXYaddedMother)                         = 99999;
                            EuclideanTrackDistanceFLaddedNextTP(rowNextTrackCorrectedFLaddedDaughtersToBeSet99999,:)             = 99999;
                            EuclideanTrackDistanceAddedNextTPColonyXYValues(:,rowCurrentTrackCorrectedXYaddedMother)             = 99999;
                            EuclideanTrackDistanceAddedNextTPColonyXYValues(rowNextTrackCorrectedFLaddedDaughtersToBeSet99999,:) = 99999;


                        end

                    end

                end

            end

        end















        %% determine how many putative cell could be assigned to any given track in radius X between TP and TP+1
        % reduces XY radius until number matches with
        % global colony count.

        currentColonyAndNextTPAssignableTracksLogical = currentColonyAndNextTP.Colony    == colonyNumber & currentColonyAndNextTP.TrackNumber ~= 0 & currentColonyAndNextTP.TimePoint == TP;
        currentColonyAndNextTPnextTPlogical           = currentColonyAndNextTP.TimePoint == TP + 1;

        % identifies rows in currentTP that belong to
        % current colony. Row index used below to be
        % assigned number of potential tracks
        [rowIndexCurrentTP,~]                   = find(currentColonyAndNextTPAssignableTracksLogical == 1);
        AssignedTrackColumnCurrentTPLogicalTEST = EuclideanTrackDistanceColonyXY(currentColonyAndNextTPnextTPlogical,rowIndexCurrentTP); % Determines number of smallest smallest elements (closest XY) that match next TP colony cell Number
        AssignedTrackColumnCurrentTPLogicalTEST(:,TracksShorterThanUserThresholdLogical) = 99999; % sets all column that can have only a single track to be assigned to due to recent division to 99999

        if numel(AssignedTrackColumnCurrentTPLogicalTEST) > 0
            [SortedElements, smallestColumnIdx, smallestRowIdx] = getNElements(AssignedTrackColumnCurrentTPLogicalTEST, NextTPColonyCellNumber - sum(TracksShorterThanUserThresholdLogical)); %get linear index of n th smallest elements
        end


        if ~isempty(AssignedTrackColumnCurrentTPLogicalTEST)

            uniqueColumnOfnthSmallestNumberElementsIDx  = 1:numel(rowIndexCurrentTP); % counts number of occurrences of column value. This represents the number of n th smallest elements in this matrix and therefore the putative number of assignable elements.

            if length(uniqueColumnOfnthSmallestNumberElementsIDx) == 1
                counts               = length(smallestColumnIdx);
                correctedRowEntries  = smallestColumnIdx + LastTPColonyCellNumber;
            else
                [counts,columnOfnthSmallestNumberElementsIDxCorrespondingly] = hist(smallestColumnIdx,uniqueColumnOfnthSmallestNumberElementsIDx);
                correctedRowEntries                                          = columnOfnthSmallestNumberElementsIDxCorrespondingly + LastTPColonyCellNumber;
            end

            % Sets the tracks that can only have one subsequent
            % track back to 1
            if sum(TracksShorterThanUserThresholdLogical) > 0
               counts(TracksShorterThanUserThresholdLogical) = 1;
            end

            currentColonyAndNextTP.NoOfAssignableCellsNextTP(correctedRowEntries,:) = counts;

        end








        %% determine how many putative cell could be assigned to any given track in radius X between TP and TP + 2
        % reduces XY radius until number matches with
        % global colony count.

        currentColonyAndNextTPAssignableTracksLogical = currentColonyAndNextTP.Colony    == colonyNumber & currentColonyAndNextTP.TrackNumber ~= 0 & currentColonyAndNextTP.TimePoint == TP;
        currentColonyAndNextTPsecondnextTPlogical     = currentColonyAndNextTP.TimePoint == TP + 2;

        % identifies rows in currentTP that belong to
        % current colony. Row index used below to be
        % assigned number of potential tracks
        [rowIndexCurrentTP,~]                   = find(currentColonyAndNextTPAssignableTracksLogical == 1);
        AssignedTrackColumnCurrentTPLogicalTEST = EuclideanTrackDistanceColonyXY(currentColonyAndNextTPsecondnextTPlogical,rowIndexCurrentTP); % Determines number of smallest smallest elements (closest XY) that match next TP colony cell Number
        AssignedTrackColumnCurrentTPLogicalTEST(:,TracksShorterThanUserThresholdLogical) = 99999; % sets all column that can have only a single track to be assigned to due to recent division to 99999

        if numel(AssignedTrackColumnCurrentTPLogicalTEST) > 0
            [SortedElements, smallestColumnIdx, smallestRowIdx] = getNElements(AssignedTrackColumnCurrentTPLogicalTEST, SecondNextTPColonyCellNumber - sum(TracksShorterThanUserThresholdLogical)); %get linear index of n th smallest elements
        end

        if ~isempty(AssignedTrackColumnCurrentTPLogicalTEST)

            uniqueColumnOfnthSmallestNumberElementsIDx  = 1:numel(rowIndexCurrentTP); % counts number of occurrences of column value. This represents the number of n th smallest elements in this matrix and therefore the putative number of assignable elements.

            if length(uniqueColumnOfnthSmallestNumberElementsIDx) == 1
                counts               = length(smallestColumnIdx);
                correctedRowEntries  = smallestColumnIdx + LastTPColonyCellNumber;
            else
                [counts,columnOfnthSmallestNumberElementsIDxCorrespondingly] = hist(smallestColumnIdx,uniqueColumnOfnthSmallestNumberElementsIDx);
                correctedRowEntries                                          = columnOfnthSmallestNumberElementsIDxCorrespondingly + LastTPColonyCellNumber;
            end

            % Sets the tracks that can only have one subsequent
            % track back to 1
            if sum(TracksShorterThanUserThresholdLogical) > 0
               counts(TracksShorterThanUserThresholdLogical) = 1;
            end

            currentColonyAndNextTP.NoOfAssignableCellsSecondNextTP(correctedRowEntries,:) = counts;

        end









        %% PART ??: Assign Track Number
        %
        %

        if CurrentTPColonyCellNumber == 0
            CurrentTPCellNumber = LastTPColonyCellNumber;
        else
            CurrentTPCellNumber = CurrentTPColonyCellNumber;
        end



           for TrackNo = 1:CurrentTPCellNumber


            EuclideanTrackDistanceLastTPCompLogical    = currentColonyAndNextTP.TimePoint == TP - 1;
            EuclideanTrackDistanceCurrentTPCompLogical = currentColonyAndNextTP.TimePoint == TP;

            % set all already assigned rowns of nextTP to
            % 99999 to prevent double assignment
            alreadyAssignedRowsLogical                                       = currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TrackNumber ~= 0 & currentColonyAndNextTP.TimePoint == TP + 1;
            EuclideanTrackDistanceXY(alreadyAssignedRowsLogical,:)           = 99999;
            EuclideanTrackDistanceFluorescence(alreadyAssignedRowsLogical,:) = 99999;

            EuclideanTrackDistanceCurrentTPCompLogicalHor = EuclideanTrackDistanceCurrentTPCompLogical';
            EuclideanTrackDistanceNextTPCompLogicalVert   = currentColonyAndNextTP.TimePoint == TP + 1;
            EuclideanTrackDistanceCurrentNextTPXYcomp     = EuclideanTrackDistanceXY(EuclideanTrackDistanceNextTPCompLogicalVert, EuclideanTrackDistanceCurrentTPCompLogicalHor);
            EuclideanTrackDistanceVectorXY                = reshape(EuclideanTrackDistanceCurrentNextTPXYcomp,numel(EuclideanTrackDistanceCurrentNextTPXYcomp),1);
            EuclideanTrackDistanceVectorXY                = sort(EuclideanTrackDistanceVectorXY);







            % Determines minimal euclicean distance of
            % current non redundant matrix
            CurrentEuclideanDistanceXY = min(EuclideanTrackDistanceVectorXY);

            if ~isempty(CurrentEuclideanDistanceXY)

                % Assign ERROR and proceed
                if CurrentEuclideanDistanceXY == 99999

                    ErrorLogical                                 = currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TrackNumber == 0;
                    currentColonyAndNextTP.Error(ErrorLogical,:) = 1;
                    fprintf('Position %03d TimePoint %03d Colony %03d Cycle %03d Row ?? with euclidean distance %d assigned to cell ?? - ERROR - XY minimum = 99999\n', currentPosition, TP, colonyNumber, TrackNo, CurrentEuclideanDistanceXY);
                    continue
                else


                    % Identifies row and column that match
                    % current minimal euclidean distance
                    [rowNextTrack, rowCurrentTrack] = find(EuclideanTrackDistanceCurrentNextTPXYcomp == CurrentEuclideanDistanceXY);

                    % in case multiple rows with same XY
                    % eucl distance are present, exclude
                    % all that belong to other columns
                    if length(rowCurrentTrack) > 1
                        rowCurrentTrack  = rowCurrentTrack(1);
                        [rowNextTrack,~] = find(EuclideanTrackDistanceCurrentNextTPXYcomp(:,rowCurrentTrack) == CurrentEuclideanDistanceXY);
                    end


                    % Checks whether list of potentially assigned
                    % rows is bigger than 1 in order to determine
                    % the first and the second entry. If distance
                    % is very small comparison of fluorescence
                    % intensities is initiated to determine
                    % assignment
                    CurrentAndNextEuclideanDistanceXYlogical = 0;

                    if size(EuclideanTrackDistanceCurrentNextTPXYcomp,1) >= 2

                        % checks whether another entry in the same column eucl XY dist is
                        % equally close
                        EuclideanTrackDistanceCurrentNextTPXYcompSorted       = sort(EuclideanTrackDistanceCurrentNextTPXYcomp);
                        EuclideanTrackDistanceCurrentNextTPXYcompSortedSecMin = EuclideanTrackDistanceCurrentNextTPXYcompSorted(2,rowCurrentTrack(1));
                        CurrentAndNextEuclideanDistanceXYlogical              = EuclideanTrackDistanceCurrentNextTPXYcompSorted(2,rowCurrentTrack(1)) - CurrentEuclideanDistanceXY < 1;

                        if EuclideanTrackDistanceCurrentNextTPXYcompSortedSecMin ~= 99999

                            % extracts row and column index of putative
                            % alternative cell in same column
                            [alternativeRowNextTrack, ~] = find(EuclideanTrackDistanceCurrentNextTPXYcomp(:,rowCurrentTrack(1)) == EuclideanTrackDistanceCurrentNextTPXYcompSortedSecMin);


                            if size(EuclideanTrackDistanceCurrentNextTPXYcomp,1) >= 3

                                EuclideanTrackDistanceCurrentNextTPXYcompSortedThirdMin = EuclideanTrackDistanceCurrentNextTPXYcompSorted(3,rowCurrentTrack(1));
                                [secondAlternativeRowNextTrack, ~]                      = find(EuclideanTrackDistanceCurrentNextTPXYcomp(:,rowCurrentTrack(1)) == EuclideanTrackDistanceCurrentNextTPXYcompSortedThirdMin);



                                if length(alternativeRowNextTrack) > 1 && length(secondAlternativeRowNextTrack) > 1
                                    if alternativeRowNextTrack(1) == secondAlternativeRowNextTrack(1) || alternativeRowNextTrack(1) == secondAlternativeRowNextTrack(2)
                                        alternativeRowNextTrack       = alternativeRowNextTrack(1,1);
                                        secondAlternativeRowNextTrack = secondAlternativeRowNextTrack(2,1);
                                    end
                                end

                            else
                                secondAlternativeRowNextTrack = [];
                            end

                            % in case minimum euclidean XY
                            % distance it not unique OR informative enough to distinguish between cells use
                            % background corrected fluorescence
                            % euclidean distance to distinguish
                            if length(alternativeRowNextTrack) > 1

                                EuclideanTrackDistanceCurrentNextTPFLcomp = EuclideanTrackDistanceFluorescence(EuclideanTrackDistanceNextTPCompLogicalVert, EuclideanTrackDistanceCurrentTPCompLogicalHor);


                                if length(alternativeRowNextTrack) > 1
                                    EuclideanTrackDistanceXYidenticalsEuclideanFluorescenceValues = EuclideanTrackDistanceCurrentNextTPFLcomp(alternativeRowNextTrack,rowCurrentTrack(1));
                                else
                                    EuclideanTrackDistanceXYidenticalsEuclideanFluorescenceValues = EuclideanTrackDistanceCurrentNextTPFLcomp([alternativeRowNextTrack, secondAlternativeRowNextTrack], rowCurrentTrack(1));
                                end

                                % Determines minimal euclicean distance of
                                % current non redundant matrix
                                CurrentEuclideanDistanceXYIdenticalMinimumFluoresceneValue = min(EuclideanTrackDistanceXYidenticalsEuclideanFluorescenceValues);


                                % Identifies row and column that match
                                % current minimal euclidean distance
                                [alternativeRowNextTrackFL, ~] = find(EuclideanTrackDistanceCurrentNextTPFLcomp == CurrentEuclideanDistanceXYIdenticalMinimumFluoresceneValue);


                                if length(secondAlternativeRowNextTrack) > 1
                                    secondAlternativeRowNextTrack = secondAlternativeRowNextTrack(2,1);
                                end


                                % in case best FL fit does match
                                % alternativ entry (second XY
                                % minimum) of same column exchange
                                % values, otherwise leave as is
                                if secondAlternativeRowNextTrack == alternativeRowNextTrackFL %if both entries are in same row swap/update rowNextTracK index

                                    % Identify row and column that
                                    % match current seconnd minimum
                                    %EuclideanTrackDistanceXYidenticalsEuclideanFLValuesSorted = sort(EuclideanTrackDistanceXYidenticalsEuclideanFluorescenceValues);
                                    %CurrentEuclideanDistanceXYIdenticalSecMinimumFluoresceneValue = EuclideanTrackDistanceXYidenticalsEuclideanFLValuesSorted(2,:);

                                    %[alternativeRowNextTrack,alternativeRowCurrentTrack] = find(EuclideanTrackDistanceCurrentNextTPFLcomp == CurrentEuclideanDistanceXYIdenticalSecMinimumFluoresceneValue);

                                    %swap values and alternative
                                    %entrry instead since FL value
                                    %fit better
                                    secondAlternativeRowNextTrack = alternativeRowNextTrack;
                                    alternativeRowNextTrack       = alternativeRowNextTrackFL;
                                else %keep value
                                    alternativeRowNextTrack = alternativeRowNextTrackFL;
                                end

                            end

                        end
                    else
                        alternativeRowNextTrack = [];
                    end







                    %% USE OF FLUORESCENCE INFORMATION
                    % in case minimum euclidean XY
                    % distance it not unique OR informative enough to distinguish between cells use
                    % background corrected fluorescence
                    % euclidean distance to distinguish
                    if length(rowNextTrack) > 1 || CurrentAndNextEuclideanDistanceXYlogical == 1

                        EuclideanTrackDistanceCurrentNextTPFLcomp = EuclideanTrackDistanceFluorescence(EuclideanTrackDistanceNextTPCompLogicalVert, EuclideanTrackDistanceCurrentTPCompLogicalHor);

                        if sum(~isnan(EuclideanTrackDistanceCurrentNextTPFLcomp)) > 0 % exeption handling: in case FL data is missing and only NAN are present do not execute. Otherwise to be assigned row will be empty and crash later

                        if length(rowNextTrack) > 1
                            EuclideanTrackDistanceXYidenticalsEuclideanFluorescenceValues = EuclideanTrackDistanceCurrentNextTPFLcomp(rowNextTrack,rowCurrentTrack(1));
                        elseif CurrentAndNextEuclideanDistanceXYlogical == 1
                            EuclideanTrackDistanceXYidenticalsEuclideanFluorescenceValues = EuclideanTrackDistanceCurrentNextTPFLcomp([rowNextTrack, alternativeRowNextTrack],rowCurrentTrack(1));
                        end

                        % Determines minimal euclicean distance of
                        % current non redundant matrix
                        CurrentEuclideanDistanceXYIdenticalMinimumFluoresceneValue = min(EuclideanTrackDistanceXYidenticalsEuclideanFluorescenceValues);

                        % Identifies row and column that match
                        % current minimal euclidean distance
                        [rowNextTrackFL, ~] = find(EuclideanTrackDistanceCurrentNextTPFLcomp == CurrentEuclideanDistanceXYIdenticalMinimumFluoresceneValue);


                        % in case best FL fit does match
                        % alternativ entry (second XY
                        % minimum) of same column exchange
                        % values, otherwise leave as is
                        if alternativeRowNextTrack == rowNextTrackFL %if both entries are in same column and row update rowNextTracK index

                            %swap values and alternative
                            %entrry instead since FL value
                            %fit better
                            alternativeRowNextTrack = rowNextTrack;
                            rowNextTrack            = rowNextTrackFL;
                        else %keep value
                            rowNextTrack = rowNextTrackFL;
                        end

                        % error prone setting -->
                        % choose first in list improve
                        % later bug in 160726DL13 P14
                        % TP146
                        if length(rowNextTrack) > 1
                            rowNextTrack = rowNextTrack(1,1);
                        end

                        if length(alternativeRowNextTrack) > 1
                            alternativeRowNextTrack = setdiff(alternativeRowNextTrack, rowNextTrack);
                        end

                        else
                         if length(rowNextTrack) > 1
                            rowNextTrack = rowNextTrack(1,1);
                         end  
                        end

                    end







                    %%
                    % checks whether another columns eucl XY dist is
                    % equally close to the same row
                    CurrentAndNextEuclideanDistanceXYAcrossColumnLogical                    = EuclideanTrackDistanceCurrentNextTPXYcomp(rowNextTrack,:) < maxTrackDistance; 
                    CurrentAndNextEuclideanDistanceXYAcrossColumnLogical(:,rowCurrentTrack) = 0; %excludes already determines minimum from comparision, otherwise would be executed every time

                    % in case minimum euclidean XY
                    % distance it not unique OR informative enough to distinguish between cells use
                    % background corrected fluorescence
                    % euclidean distance to distinguish
                    if CurrentAndNextEuclideanDistanceXYAcrossColumnLogical == 1

                        EuclideanTrackDistanceCurrentNextTPFLcomp                     = EuclideanTrackDistanceFluorescence(EuclideanTrackDistanceNextTPCompLogicalVert, EuclideanTrackDistanceCurrentTPCompLogicalHor);
                        EuclideanTrackDistanceXYidenticalsEuclideanFluorescenceValues = EuclideanTrackDistanceCurrentNextTPFLcomp(rowNextTrack,:);

                        % Determines minimal euclicean distance of
                        % current non redundant matrix
                        CurrentEuclideanDistanceXYIdenticalMinimumFluoresceneValue = min(EuclideanTrackDistanceXYidenticalsEuclideanFluorescenceValues);

                        % Identifies row and column that match
                        % current minimal euclidean distance
                        [~, rowCurrentTrackFL] = find(EuclideanTrackDistanceCurrentNextTPFLcomp == CurrentEuclideanDistanceXYIdenticalMinimumFluoresceneValue);

                        % in case cross column comparison
                        % of FL values shows better fit
                        % change to be assign column
                        if rowCurrentTrackFL ~= rowCurrentTrack
                            rowCurrentTrack = rowCurrentTrackFL;
                        end

                    end











                    %%
                    % shifts row and column index
                    % to match euclidean distance
                    % entries
                    lastAndCurrentTPlogical            = currentColonyAndNextTP.TimePoint == TP | currentColonyAndNextTP.TimePoint == TP - 1;
                    rowNextTrackCorrected              = rowNextTrack            + sum(lastAndCurrentTPlogical);
                    rowNextTrackSecondMinimumCorrected = alternativeRowNextTrack + sum(lastAndCurrentTPlogical);


                    %%
                    % correction of rowCurrentTrack due to
                    % TP-1 columns plus exeption for TP1
                    % where TP-1 is not present
                    if TP > 1
                        rowCurrentTrackCorrected      = rowCurrentTrack(1)       + sum(EuclideanTrackDistanceLastTPCompLogical);
                        currentTrackNumberLengthIndex = rowCurrentTrackCorrected - sum(EuclideanTrackDistanceLastTPCompLogical);
                    else
                        rowCurrentTrackCorrected      = rowCurrentTrack(1);
                        currentTrackNumberLengthIndex = rowCurrentTrack;
                    end

                    %%
                    % Apply user set maximum tracknumber and skip loop
                    if maxColonyCellNumber == 0 % do nothing
                    elseif currentColonyAndNextTP.TrackNumber(rowCurrentTrackCorrected,:) > maxColonyCellNumber
                        continue
                    end





                    %%
                    % compares relative deviation
                    % of to be assigned track to mean of
                    % previous 3 TPs to assess
                    % whether or not an assignment error has
                    % have occurred.

                    % extracts TrackNumber of just
                    % assigned Track
                    AssignedTrackNumber       = currentColonyAndNextTP.TrackNumber(rowCurrentTrackCorrected,:);

                    if length(AssignedTrackNumber) == 1

                        %extracts row of just assigned
                        %track for comparison with mean
                        %fluorescence value of last 3
                        %TP
                        last3TParrayMeanAssignedTrackLogical = last3TParrayMean.TrackNumber == AssignedTrackNumber;
                        last3TParrayMeanAssignedTrack        = last3TParrayMean(last3TParrayMeanAssignedTrackLogical,:);
                        last3TParrayMeanAssignedTrackArray   = table2array(last3TParrayMeanAssignedTrack);


                        if ~isempty(last3TParrayMeanAssignedTrackArray)

                            % calculates relative deviation from mean of previous 3 TP
                            %currentColonyAndNextTParrayMatrix = repmat(currentColonyAndNextTParray(rowNextTrackCorrected,:),size(last3TParrayMeanCAT,1),1);
                            %Last3TPrelativeDeviationVerifyTrack = abs(100 - (currentAssignedTrackArray./last3TParrayMeanAssignedTrackArray*100));

                            EuclideanAssignmentDeviation = EuclideanTrackDistanceFluorescence(rowNextTrackCorrected,rowCurrentTrackCorrected) > (last3TParrayMeanAssignedTrackArray(:,AssignedEuclideanDistanceFLcolumnNumber) * 1.4) ...
                                | EuclideanTrackDistanceFluorescence(rowNextTrackCorrected,rowCurrentTrackCorrected) < (last3TParrayMeanAssignedTrackArray(:,AssignedEuclideanDistanceFLcolumnNumber) *1/1.4);

                            % Annotates ERROR when
                            % fluorescence intensities of
                            % currently assigned track
                            % deviate more than 50% from
                            % mean of last 3TP
                            if sum(EuclideanAssignmentDeviation == 0)
                                currentColonyAndNextTP.FluorescenceIntensityTrackOutlier(rowNextTrackCorrected,:) = 0;
                            else
                                currentColonyAndNextTP.FluorescenceIntensityTrackOutlier(rowNextTrackCorrected,:) = 1;
                                fprintf('Position %03d TimePoint %03d Colony %03d Cycle %03d Row %03d with euclidean distance %d assigned to cell %03d - ERROR - FL missmatch previous Track\n', currentPosition, TP, colonyNumber, TrackNo, rowNextTrackCorrected, CurrentEuclideanDistanceXY, AssignedTrackNumber);

                            end


                            % in case of cell division
                            % determines whether or not the
                            % other daughter deviates from
                            % last 3TP FL mean eucl
                            % distance
                            if currentColonyAndNextTP.NoOfAssignableCellsNextTP(rowCurrentTrackCorrected,:) > 1

                                EuclideanAssignmentDeviation2 = EuclideanTrackDistanceFluorescence(rowNextTrackSecondMinimumCorrected,rowCurrentTrackCorrected) > (last3TParrayMeanAssignedTrackArray(:,AssignedEuclideanDistanceFLcolumnNumber) * 1.4) ...
                                    | EuclideanTrackDistanceFluorescence(rowNextTrackSecondMinimumCorrected,rowCurrentTrackCorrected) < (last3TParrayMeanAssignedTrackArray(:,AssignedEuclideanDistanceFLcolumnNumber) *1/1.4);

                                % Annotates ERROR when
                                % fluorescence intensities of
                                % currently assigned track
                                % deviate more than 50% from
                                % mean of last 3TP
                                if sum(EuclideanAssignmentDeviation2 == 0) ...

                                currentColonyAndNextTP.FluorescenceIntensityTrackOutlier(rowNextTrackSecondMinimumCorrected,:) = 0;

                                else
                                    currentColonyAndNextTP.FluorescenceIntensityTrackOutlier(rowNextTrackSecondMinimumCorrected,:) = 1;
                                    fprintf('Position %03d TimePoint %03d Colony %03d Cycle %03d Row %03d with euclidean distance %d assigned to cell %03d - ERROR - FL missmatch previous Track\n', currentPosition, TP, colonyNumber, TrackNo, rowNextTrackSecondMinimumCorrected, EuclideanTrackDistanceXY(rowNextTrackSecondMinimumCorrected,rowCurrentTrackCorrected), AssignedTrackNumber);

                                end

                            end


                        else
                            continue
                        end

                    else
                        continue
                    end










                    %%
                    % determines whether to be assigned
                    % track is present in list of dividing
                    % cells (created by comparing FL
                    % intensities of matrix)
                    RowIndexDividingCellsToBeAssingedTrackCompLogical = false(1, numel(RowIndexDividingCells));
                    %if ~isempty(RowIndexDividingCells{:})

                    for DividingCellCounter = 1:numel(RowIndexDividingCells)
                        RowIndexDividingCellsToBeAssingedTrackCompLogical(:,DividingCellCounter) = ~isempty(find(RowIndexDividingCells{DividingCellCounter} == rowNextTrackCorrected));
                    end
                    %end

                    %%
                    % determines whether to be assigned
                    % column is present in list of mother
                    % cells (created by comparing FL
                    % intensities of matrix)
                    RowIndexMotherCellsToBeAssingedTrackCompLogical = false(1, numel(RowIndexMotherCells));
                    %if ~isempty(RowIndexMotherCells{:})

                    for MotherCellCounter = 1:numel(RowIndexMotherCells)
                        RowIndexMotherCellsToBeAssingedTrackCompLogical(:,MotherCellCounter) = ~isempty(find(RowIndexMotherCells{MotherCellCounter} == rowCurrentTrackCorrected));
                    end
                    %end





                    %%
                    % Compares to be assigned Track with
                    % NoOfAssignableCellsSecondNextTP of
                    % last TP
                    [rowLastTrackCorrected,~] = find(currentColonyAndNextTP.TimePoint == TP - 1 & currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TrackNumber == AssignedTrackNumber);

                    if length(rowLastTrackCorrected) > 1
                        rowLastTrackCorrected = rowLastTrackCorrected(1);
                    end

                    LastTPnoOfAssignableCellsSecondNextTPtest = currentColonyAndNextTP.NoOfAssignableCellsSecondNextTP(rowLastTrackCorrected,:);

                    if isempty(LastTPnoOfAssignableCellsSecondNextTPtest)
                        LastTPnoOfAssignableCellsSecondNextTPtest = 0;
                    end



                    %% ASSIGN TrackNumber to cell with best XY and FL fit and decided whether or not cell division occurs

                    if size(rowCurrentTrackCorrected,1) == 1

                        % makes sure that only cell within
                        % colony are assigned, if nothing
                        % found assing LOST
                        if currentColonyAndNextTP.Colony(rowNextTrackCorrected,:)              ~= colonyNumber ...
                                | currentColonyAndNextTP.Colony(rowCurrentTrackCorrected,:)    ~= colonyNumber

                            currentColonyAndNextTP.Lost(rowCurrentTrackCorrected,:) = 1;

                            fprintf('Position %03d TimePoint %03d Colony %03d Cycle %03d Row %03d with euclidean distance %d assigned to cell %03d - Out of Colony Assignment Error\n', currentPosition, TP, colonyNumber, TrackNo, rowNextTrackCorrected, CurrentEuclideanDistanceXY, currentColonyAndNextTP.TrackNumber(rowCurrentTrackCorrected,:));


                        else

                            % APOPTOSIS REassignment Assign Apoptosis if was apoptotic before
                            % ==========================>

                            currentColonylastTPAssignedTracksLogical = currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TrackNumber == AssignedTrackNumber & currentColonyAndNextTP.TimePoint == TP - 1 ...
                                | currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TrackNumber == AssignedTrackNumber & currentColonyAndNextTP.TimePoint == TP;

                            if sum(currentColonyAndNextTP.Apoptosis(currentColonylastTPAssignedTracksLogical)) > 0

                              % assign Colony and Track Annotation of
                              % currentTP to matching row in nextTP
                              currentColonyAndNextTP.TrackNumber(rowNextTrackCorrected,:)                 = currentColonyAndNextTP.TrackNumber(rowCurrentTrackCorrected,:);
                              currentColonyAndNextTP.Apoptosis(rowNextTrackCorrected,:)                   = 1;
                              currentColonyAndNextTP.AssignedEuclideanDistanceXY(rowNextTrackCorrected,:) = EuclideanTrackDistanceXY(rowNextTrackCorrected,rowCurrentTrackCorrected);
                              currentColonyAndNextTP.AssignedEuclideanDistanceFL(rowNextTrackCorrected,:) = EuclideanTrackDistanceFluorescence(rowNextTrackCorrected,rowCurrentTrackCorrected);  

                              % sets distances of already assigned cells
                              % to 99999 so they can not be used by other
                              % cells
                              EuclideanTrackDistanceXY(:,rowCurrentTrackCorrected)           = 99999;
                              EuclideanTrackDistanceXY(rowNextTrackCorrected,:)              = 99999;
                              EuclideanTrackDistanceFluorescence(:,rowCurrentTrackCorrected) = 99999;
                              EuclideanTrackDistanceFluorescence(rowNextTrackCorrected,:)    = 99999; 

                                fprintf('Position %03d TimePoint %03d Colony %03d Cycle %03d Row %03d with euclidean distance %d assigned to cell %03d - Track was Assigned Apoptosis before\n', currentPosition, TP, colonyNumber, TrackNo, rowNextTrackCorrected, CurrentEuclideanDistanceXY, currentColonyAndNextTP.TrackNumber(rowCurrentTrackCorrected,:));


                                % APOPTOSIS Assignment
                                % ==========================>

                            elseif unique(last3TParrayMeanAssignedTrack.AssignedEuclideanDistanceXY)                             == 0 ...
                                    & unique(last3TParrayMeanAssignedTrack.TimePoint)                                             > minTP ...
                                    & currentTrackNumberLength{currentTrackNumberLengthIndex}                                    >= 3 ...
                                    & sum(last3TParray.Colony == colonyNumber & last3TParray.TrackNumber == AssignedTrackNumber) == 3;



                                % assign Colony and Track Annotation of
                                % currentTP to matching row in nextTP
                                currentColonyAndNextTP.TrackNumber(rowNextTrackCorrected,:)                 = currentColonyAndNextTP.TrackNumber(rowCurrentTrackCorrected,:);
                                currentColonyAndNextTP.Apoptosis(rowNextTrackCorrected,:)                   = 1;
                                currentColonyAndNextTP.AssignedEuclideanDistanceXY(rowNextTrackCorrected,:) = EuclideanTrackDistanceXY(rowNextTrackCorrected,rowCurrentTrackCorrected);
                                currentColonyAndNextTP.AssignedEuclideanDistanceFL(rowNextTrackCorrected,:) = EuclideanTrackDistanceFluorescence(rowNextTrackCorrected,rowCurrentTrackCorrected);

                                % sets distances of already assigned cells
                                % to 99999 so they can not be used by other
                                % cells
                                EuclideanTrackDistanceXY(:,rowCurrentTrackCorrected)           = 99999;
                                EuclideanTrackDistanceXY(rowNextTrackCorrected,:)              = 99999;
                                EuclideanTrackDistanceFluorescence(:,rowCurrentTrackCorrected) = 99999;
                                EuclideanTrackDistanceFluorescence(rowNextTrackCorrected,:)    = 99999;

                                fprintf('Position %03d TimePoint %03d Colony %03d Cycle %03d Row %03d with euclidean distance %d assigned to cell %03d - APOPTOSIS\n', currentPosition, TP, colonyNumber, TrackNo, rowNextTrackCorrected, CurrentEuclideanDistanceXY, currentColonyAndNextTP.TrackNumber(rowCurrentTrackCorrected,:));





                                % NO CELL DIVISION - CRITERIA
                                % ===============================>
                            elseif currentTrackNumberLength{currentTrackNumberLengthIndex}                         <= maxTrackLengthNoCellDivision ...
                                    | currentColonyAndNextTP.NoOfAssignableCellsNextTP(rowCurrentTrackCorrected,:) == 1 & currentColonyAndNextTP.NoOfAssignableCellsSecondNextTP(rowCurrentTrackCorrected,:) == 1 ...
                                    | sum(RowIndexMotherCellsToBeAssingedTrackCompLogical)                         == 0 & NextTPColonyCellNumber                                                              > 2 ...
                                    | currentColonyAndNextTP.NoOfAssignableCellsNextTP(rowCurrentTrackCorrected,:) == 2 & currentColonyAndNextTP.NoOfAssignableCellsSecondNextTP(rowCurrentTrackCorrected,:) == 1 & sum(RowIndexMotherCellsToBeAssingedTrackCompLogical) == 0 ...
                                    | currentColonyAndNextTP.NoOfAssignableCellsNextTP(rowCurrentTrackCorrected,:) == 0 & currentColonyAndNextTP.NoOfAssignableCellsSecondNextTP(rowCurrentTrackCorrected,:) == 1 ...

                                % assign Colony and Track Annotation of
                                % currentTP to matching row in nextTP
                                currentColonyAndNextTP.TrackNumber(rowNextTrackCorrected,:)                 = currentColonyAndNextTP.TrackNumber(rowCurrentTrackCorrected,:);
                                currentColonyAndNextTP.AssignedEuclideanDistanceXY(rowNextTrackCorrected,:) = EuclideanTrackDistanceXY(rowNextTrackCorrected,rowCurrentTrackCorrected);
                                currentColonyAndNextTP.AssignedEuclideanDistanceFL(rowNextTrackCorrected,:) = EuclideanTrackDistanceFluorescence(rowNextTrackCorrected,rowCurrentTrackCorrected);

                                % sets distances of already assigned cells
                                % to 99999 so they can not be used by other
                                % cells
                                EuclideanTrackDistanceXY(:,rowCurrentTrackCorrected)           = 99999;
                                EuclideanTrackDistanceXY(rowNextTrackCorrected,:)              = 99999;
                                EuclideanTrackDistanceFluorescence(:,rowCurrentTrackCorrected) = 99999;
                                EuclideanTrackDistanceFluorescence(rowNextTrackCorrected,:)    = 99999;

                                fprintf('Position %03d TimePoint %03d Colony %03d Cycle %03d Row %03d with euclidean distance %d assigned to cell %03d \n', currentPosition, TP, colonyNumber, TrackNo, rowNextTrackCorrected, CurrentEuclideanDistanceXY, currentColonyAndNextTP.TrackNumber(rowCurrentTrackCorrected,:));






                                % CELL DIVISION
                                % ==========================>

                            elseif currentColonyAndNextTP.NoOfAssignableCellsNextTP(rowCurrentTrackCorrected,:)          > 1 ...
                                    & sum(RowIndexMotherCellsToBeAssingedTrackCompLogical)                               > 0 ...
                                    %& currentColonyAndNextTP.NoOfAssignableCellsSecondNextTP(rowCurrentTrackCorrected,:) > 1

                                currentColonyAndNextTP.TrackNumber(rowNextTrackCorrected,:)              = currentColonyAndNextTP.TrackNumber(rowCurrentTrackCorrected,:) * 2 + 0;
                                currentColonyAndNextTP.TrackNumber(rowNextTrackSecondMinimumCorrected,:) = currentColonyAndNextTP.TrackNumber(rowCurrentTrackCorrected,:) * 2 + 1;


                                currentColonyAndNextTP.AssignedEuclideanDistanceXY(rowNextTrackCorrected,:)              = EuclideanTrackDistanceXY(rowNextTrackCorrected,rowCurrentTrackCorrected);
                                currentColonyAndNextTP.AssignedEuclideanDistanceFL(rowNextTrackCorrected,:)              = EuclideanTrackDistanceFluorescence(rowNextTrackCorrected,rowCurrentTrackCorrected);
                                currentColonyAndNextTP.AssignedEuclideanDistanceXY(rowNextTrackSecondMinimumCorrected,:) = EuclideanTrackDistanceXY(rowNextTrackSecondMinimumCorrected,rowCurrentTrackCorrected);
                                currentColonyAndNextTP.AssignedEuclideanDistanceFL(rowNextTrackSecondMinimumCorrected,:) = EuclideanTrackDistanceFluorescence(rowNextTrackSecondMinimumCorrected,rowCurrentTrackCorrected);
                                currentColonyAndNextTP.Division(rowCurrentTrackCorrected,:) = 1;

                                % sets distances of already assigned cells
                                % to zero so they can not be used by other
                                % cells
                                EuclideanTrackDistanceXY(:,rowCurrentTrackCorrected)           = 99999;
                                EuclideanTrackDistanceXY(rowNextTrackCorrected,:)              = 99999;
                                EuclideanTrackDistanceXY(rowNextTrackSecondMinimumCorrected,:) = 99999;

                                EuclideanTrackDistanceFluorescence(:,rowCurrentTrackCorrected)           = 99999;
                                EuclideanTrackDistanceFluorescence(rowNextTrackCorrected,:)              = 99999;
                                EuclideanTrackDistanceFluorescence(rowNextTrackSecondMinimumCorrected,:) = 99999;

                                fprintf('Position %03d TimePoint %03d Colony %03d Cycle %03d Row %03d with euclidean distance %d assigned to cell %03d - CELL DIVISION\n', currentPosition, TP, colonyNumber, TrackNo, rowNextTrackCorrected, CurrentEuclideanDistanceXY, currentColonyAndNextTP.TrackNumber(rowCurrentTrackCorrected,:));
                                fprintf('Position %03d TimePoint %03d Colony %03d Cycle %03d Row %03d with euclidean distance %d assigned to cell %03d - CELL DIVISION\n', currentPosition, TP, colonyNumber, TrackNo, rowNextTrackSecondMinimumCorrected, CurrentEuclideanDistanceXY, currentColonyAndNextTP.TrackNumber(rowCurrentTrackCorrected,:));












                                % TREAT REMAINING INSTANCES as
                                % NO CELL DIVISION
                                % ============================>
                            else %no criterium met ---> assign track

                                %fprintf('No criterium met -> No cell division \n');

                                % assign Colony and Track Annotation of
                                % currentTP to matching row in nextTP
                                currentColonyAndNextTP.TrackNumber(rowNextTrackCorrected,:)                 = currentColonyAndNextTP.TrackNumber(rowCurrentTrackCorrected,:);
                                currentColonyAndNextTP.AssignedEuclideanDistanceXY(rowNextTrackCorrected,:) = EuclideanTrackDistanceXY(rowNextTrackCorrected,rowCurrentTrackCorrected);
                                currentColonyAndNextTP.AssignedEuclideanDistanceFL(rowNextTrackCorrected,:) = EuclideanTrackDistanceFluorescence(rowNextTrackCorrected,rowCurrentTrackCorrected);

                                % sets distances of already assigned cells
                                % to 99999 so they can not be used by other
                                % cells
                                EuclideanTrackDistanceXY(:,rowCurrentTrackCorrected)           = 99999;
                                EuclideanTrackDistanceXY(rowNextTrackCorrected,:)              = 99999;
                                EuclideanTrackDistanceFluorescence(:,rowCurrentTrackCorrected) = 99999;
                                EuclideanTrackDistanceFluorescence(rowNextTrackCorrected,:)    = 99999;

                                fprintf('Position %03d TimePoint %03d Colony %03d Cycle %03d Row %03d with euclidean distance %d assigned to cell %03d\n', currentPosition, TP, colonyNumber, TrackNo, rowNextTrackCorrected, CurrentEuclideanDistanceXY, currentColonyAndNextTP.TrackNumber(rowCurrentTrackCorrected,:));

                            end

                        end





                        %%ERROR HANDLING:
                        %===================>
                        %In case last
                        %available TrackNo of current
                        %TP has been assigned check
                        %whether there are TrackNumber
                        %in TP-1 compared to TP+1 that
                        %have not been assigned
                        %(indicative of not segmented
                        %cell). If so determine which
                        %and determine eucl dist of not
                        %assigned TrackNumber between
                        %TP-1 abd TP+1. If below
                        %threshold assign.

                        if TrackNo == CurrentTPCellNumber & LastTPColonyCellNumber > CurrentTPColonyCellNumber & CurrentTPColonyCellNumber < NextTPColonyCellNumber

                            LastTPlogical             = currentColonyAndNextTP.TimePoint == TP - 1;
                            NextTPlogical             = currentColonyAndNextTP.TimePoint == TP + 1 & currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TrackNumber ~= 0;
                            LastTPpresentTrackNumbers = currentColonyAndNextTP.TrackNumber(LastTPlogical);
                            NextTPpresentTrackNumbers = currentColonyAndNextTP.TrackNumber(NextTPlogical);

                            TrackNumberDifferenceTPminusOneTPplusOne = setdiff(LastTPpresentTrackNumbers,NextTPpresentTrackNumbers);
                            TrackNumberCommonTPminsOneTPplusOne = intersect(LastTPpresentTrackNumbers,NextTPpresentTrackNumbers);

                            % identify row that are present in
                            % last current and next TP in order
                            % to exclude them from correction
                            % assigmnmebt by setting xy eucl
                            % matrix rows below to 99999
                            TrackNumberIdxToBeExcludedFromTPplusOneCorrection = ismember(currentColonyAndNextTP.TrackNumber,TrackNumberCommonTPminsOneTPplusOne) & ismember(currentColonyAndNextTP.Colony, colonyNumber) & ismember(currentColonyAndNextTP.TimePoint, TP + 1);

                            AllMissingRows = zeros(numel(TrackNumberDifferenceTPminusOneTPplusOne),1); %preallocate

                            %find row INDEX of TrackNumbers
                            %present in TP - 1 but lacking
                            %in TP + 1
                            for jj = 1:numel(TrackNumberDifferenceTPminusOneTPplusOne)
                                [CurrentMissingRows,~] = find(currentColonyAndNextTP.TimePoint == TP - 1 & currentColonyAndNextTP.TrackNumber == TrackNumberDifferenceTPminusOneTPplusOne(jj));
                                AllMissingRows(jj,1)   = CurrentMissingRows(1); % if more than one Rows with same TrackNumber are detected select first.
                            end
                            AllMissingRows = sort(AllMissingRows');


                            for ii = 1:numel(TrackNumberDifferenceTPminusOneTPplusOne)

                                EuclideanTrackDistanceCurrentNextTPXYcomp     = EuclideanTrackDistanceColonyXY(EuclideanTrackDistanceNextTPCompLogicalVert, AllMissingRows);

                                % Sets rows to be excluded from
                                % correction to 99999 
                                ToBeExcludedFromCorrectionLogical             = TrackNumberIdxToBeExcludedFromTPplusOneCorrection(EuclideanTrackDistanceNextTPCompLogicalVert, :);
                                EuclideanTrackDistanceCurrentNextTPXYcomp(ToBeExcludedFromCorrectionLogical,:) = 99999;

                                EuclideanTrackDistanceVectorXY                = reshape(EuclideanTrackDistanceCurrentNextTPXYcomp,numel(EuclideanTrackDistanceCurrentNextTPXYcomp),1);
                                EuclideanTrackDistanceVectorXY                = sort(EuclideanTrackDistanceVectorXY);
                                CurrentEuclideanDistanceXY                    = min(EuclideanTrackDistanceVectorXY);
                                RelaxStringenceFactor                         = 1.5; % factor to relax maxTrackDistance eucl XY threshold in oder to compensation for jumping over one frame in between during comparison




                                % check for not yet assigend
                                % tracks in TP + 1
                                NotAssignedTracksLogical              = currentColonyAndNextTP.TimePoint == TP + 1 & currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TrackNumber == 0 & currentColonyAndNextTP.Apoptosis == 0;
                                AlternativeCurrentEuclideanDistanceXY = min(EuclideanTrackDistanceColonyXY(NotAssignedTracksLogical, AllMissingRows'));


                                % Checks for tracks present in
                                % TP-1, TP and TP+1 and
                                % excludes them from correction
                                %TracksPresentInAll3TPsLogical = currentColonyAndNextTP.TrackNumber(EuclideanTrackDistanceNextTPCompLogicalVert,:) = 

                                if sum(NotAssignedTracksLogical) > 0 & AlternativeCurrentEuclideanDistanceXY < maxTrackDistance * RelaxStringenceFactor
                                    CurrentEuclideanDistanceXY = AlternativeCurrentEuclideanDistanceXY;
                                end


                                if CurrentEuclideanDistanceXY <= maxTrackDistance * RelaxStringenceFactor

                                    % Identifies row and column that match
                                    % current minimal euclidean distance
                                    [rowNextTrack, rowCurrentTrack] = find(EuclideanTrackDistanceCurrentNextTPXYcomp == CurrentEuclideanDistanceXY);

                                    % in case multiple rows with same XY
                                    % eucl distance are present, exclude
                                    % all that belong to other columns
                                    if length(rowCurrentTrack) > 1
                                        rowCurrentTrack  = rowCurrentTrack(1);
                                        [rowNextTrack,~] = find(EuclideanTrackDistanceCurrentNextTPXYcomp(:,rowCurrentTrack) == CurrentEuclideanDistanceXY);
                                    end


                                    % Exeption: in case multiple
                                    % entries have same XY
                                    % distance use FL value dist
                                    % to determine best fit

                                    if numel(rowNextTrack) > 1

                                        BestFLfit   = min(EuclideanTrackDistanceColonyFL(rowNextTrack,rowCurrentTrack));

                                        % overwrites multiple
                                        % entries found in
                                        % rowNextTrack with entry that fits best with FL values
                                        [rowNextTrack,~] = find(EuclideanTrackDistanceColonyFL == BestFLfit);

                                        %Exeption: In case neither
                                        %XY dist nor FL dist is
                                        %sufficient to determine
                                        %best fit choose first
                                        %entry
                                        if numel(rowNextTrack) > 1
                                            rowNextTrack = rowNextTrack(1);
                                        end
                                    end

                                    rowNextTrackCorrected    = rowNextTrack + sum(lastAndCurrentTPlogical);
                                    rowCurrentTrackCorrected = AllMissingRows(rowCurrentTrack);

                                    currentColonyAndNextTP.TrackNumber(rowNextTrackCorrected,:) = currentColonyAndNextTP.TrackNumber(rowCurrentTrackCorrected,:);
                                    currentColonyAndNextTP.Lost(rowCurrentTrackCorrected,:)     = 0;

                                    EuclideanTrackDistanceColonyXY(:,rowCurrentTrackCorrected)  = 99999;
                                    EuclideanTrackDistanceColonyXY(rowNextTrackCorrected,:)     = 99999;
                                    EuclideanTrackDistanceColonyFL(:,rowCurrentTrackCorrected)  = 99999;
                                    EuclideanTrackDistanceColonyFL(rowNextTrackCorrected,:)     = 99999;

                                end

                            end

                        end









                        %% ERROR HANDLING:
                        % ====================>
                        % remove TrackNumber that have been
                        % assigned more than once
                        % check whether assigned
                        % TrackNumber has already been
                        % assigned before in this
                        % colony
                        if ~isempty(rowNextTrackCorrected)

                            AssignedTrackNumber           = currentColonyAndNextTP.TrackNumber(rowNextTrackCorrected,:);
                            DoubleAssigmentControlLogical = currentColonyAndNextTP.TimePoint == TP - 1 & currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TrackNumber == AssignedTrackNumber;

                            if sum(DoubleAssigmentControlLogical) > 1
                                currentColonyAndNextTP.TrackNumber(rowNextTrackCorrected,:) = 0;
                                fprintf('Position %03d TimePoint %03d Colony %03d Cycle %03d Row %03d with euclidean distance %d assigned to cell %03d - ERROR CORRECTION - Row assigned to cell %03d\n', currentPosition, TP, colonyNumber, TrackNo, rowNextTrackCorrected, CurrentEuclideanDistanceXY, currentColonyAndNextTP.TrackNumber(rowNextTrackCorrected,:));
                            end

                            % check whether assigned
                            % TrackNumber has already been
                            % assigned before in this
                            % colony
                            DoubleAssigmentControlLogical = currentColonyAndNextTP.TimePoint == TP & currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TrackNumber == AssignedTrackNumber;

                            if sum(DoubleAssigmentControlLogical) > 1
                                currentColonyAndNextTP.TrackNumber(rowNextTrackCorrected,:) = 0;
                                fprintf('Position %03d TimePoint %03d Colony %03d Cycle %03d Row %03d with euclidean distance %d assigned to cell %03d - ERROR CORRECTION - Row assigned to cell %03d\n', currentPosition, TP, colonyNumber, TrackNo, rowNextTrackCorrected, CurrentEuclideanDistanceXY, currentColonyAndNextTP.TrackNumber(rowNextTrackCorrected,:));
                            end

                            % check whether assigned
                            % TrackNumber has already been
                            % assigned before in this
                            % colony
                            DoubleAssigmentControlLogical = currentColonyAndNextTP.TimePoint == TP + 1 & currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TrackNumber == AssignedTrackNumber;

                            if sum(DoubleAssigmentControlLogical) > 1
                                currentColonyAndNextTP.TrackNumber(rowNextTrackCorrected,:) = 0;
                                fprintf('Position %03d TimePoint %03d Colony %03d Cycle %03d Row %03d with euclidean distance %d assigned to cell %03d - ERROR CORRECTION - Row assigned to cell %03d\n', currentPosition, TP, colonyNumber, TrackNo, rowNextTrackCorrected, CurrentEuclideanDistanceXY, currentColonyAndNextTP.TrackNumber(rowNextTrackCorrected,:));
                            end



                        end





                        %%ERROR HANDLING:
                        %===================>
                        % If all tracks of current TP have been assigned
                        % check in TP - 1 and determine
                        % which Tracks were not assigned
                        % Apoptosis or Division. If
                        % NoOfAssignableTrack in TP+1 and TP+2
                        % of lost track is 0 and a division
                        % occured remove division event 

                        if TrackNo == CurrentTPCellNumber & LastTPColonyCellNumber < CurrentTPColonyCellNumber & CurrentTPColonyCellNumber > NextTPColonyCellNumber & NextTPColonyCellNumber == SecondNextTPColonyCellNumber

                            LastTPDivisionLogical             = currentColonyAndNextTP.TimePoint == TP - 1 & currentColonyAndNextTP.Division == 1;
                            TracksLengthEqualsOneLogical      = [currentTrackNumberLength{:}] == 1;
                            TrackLengthEqualsOneTrackNumber   = currentTPTrackNumbers(TracksLengthEqualsOneLogical,:);

                            CurrentTPlogical                  = currentColonyAndNextTP.TimePoint == TP & currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.Apoptosis == 0 & currentColonyAndNextTP.Division == 0;
                            CurrentTPpresentTrackNumbers      = currentColonyAndNextTP.TrackNumber(CurrentTPlogical);
                            NextTPlogical                     = currentColonyAndNextTP.TimePoint == TP + 1 & currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TrackNumber ~= 0;
                            NextTPpresentTrackNumbers         = currentColonyAndNextTP.TrackNumber(NextTPlogical);

                            TrackNumberDifferenceTPminusOneTPplusOne = setdiff(CurrentTPpresentTrackNumbers,NextTPpresentTrackNumbers);

                            if sum(LastTPDivisionLogical) > 0 & ~isempty(TrackLengthEqualsOneTrackNumber) & ~isempty(intersect(TrackLengthEqualsOneTrackNumber, TrackNumberDifferenceTPminusOneTPplusOne))

                            %AllMissingRows                           = zeros(numel(TrackNumberDifferenceTPminusOneTPplusOne),1); %preallocate

                            %find row INDEX of TrackNumbers
                            %present in TP - 1 but lacking
                            %in TP + 1
                            for jj = 1:numel(TrackNumberDifferenceTPminusOneTPplusOne)

                                [CurrentMissingRows,~] = find(currentColonyAndNextTP.TimePoint == TP & currentColonyAndNextTP.TrackNumber == TrackNumberDifferenceTPminusOneTPplusOne(jj));

                                if ~isempty(CurrentMissingRows)

                                AllMissingRows(jj,1)   = CurrentMissingRows(1); % if more than one Rows with same TrackNumber are detected select first.

                                % sets missing tracknumber to 0
                                % (due to oversegmentation)
                                currentColonyAndNextTP.TrackNumber(AllMissingRows(jj,1),:) = 0;
                                currentColonyAndNextTP.Lost(AllMissingRows(jj,1),:)        = 1;
                                % Identifies rows of wrong sister cell in TP
                                % and TP + 1 and corrects
                                % TrackNumber by setting it to
                                % mother value

                                if mod(TrackNumberDifferenceTPminusOneTPplusOne(jj),2) % if TrackNumber is ODD substract -1 to get to sister track
                                    CurrentNotAssignedTracksSisterLogical                         = currentColonyAndNextTP.TrackNumber == TrackNumberDifferenceTPminusOneTPplusOne(jj) - 1 & currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TimePoint == TP + 1 ...
                                                                                                  | currentColonyAndNextTP.TrackNumber == TrackNumberDifferenceTPminusOneTPplusOne(jj) - 1 & currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TimePoint == TP;
                                    MotherTrackNumber = (TrackNumberDifferenceTPminusOneTPplusOne(jj) - 1) / 2;                                                          
                                else % if TrackNumber is EVEN add +1 to get to sister track   
                                    CurrentNotAssignedTracksSisterLogical                         = currentColonyAndNextTP.TrackNumber == TrackNumberDifferenceTPminusOneTPplusOne(jj) + 1 & currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TimePoint == TP + 1 ...
                                                                                                  | currentColonyAndNextTP.TrackNumber == TrackNumberDifferenceTPminusOneTPplusOne(jj) + 1 & currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TimePoint == TP;
                                    MotherTrackNumber = TrackNumberDifferenceTPminusOneTPplusOne(jj) / 2;
                                end    

                                currentColonyAndNextTP.TrackNumber(CurrentNotAssignedTracksSisterLogical,:) = MotherTrackNumber;

                                LastTPMotherDivisionLogical                                    = currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TimePoint == TP - 1 & currentColonyAndNextTP.TrackNumber == MotherTrackNumber & currentColonyAndNextTP.Division == 1;
                                currentColonyAndNextTP.Division(LastTPMotherDivisionLogical,:) = 0;

                                end

                            end    

                            end

                        end

                        %%ERROR HANDLING
                        % ========================>
                        % In case division was detected
                        % check whether sister cell of
                        % mother was lost.
                        CurrentTPDivisionLogical = currentColonyAndNextTP.TimePoint == TP & currentColonyAndNextTP.Division == 1;

                        if TrackNo == CurrentTPCellNumber & sum(CurrentTPDivisionLogical) > 0

                            AllDivisingTracksCurrentTP = currentColonyAndNextTP.TrackNumber(CurrentTPDivisionLogical,:);

                            for jjj = 1:numel(AllDivisingTracksCurrentTP)

                                currentTrackNumberDivision = AllDivisingTracksCurrentTP(jjj);

                                if mod(currentTrackNumberDivision,2)
                                    SisterOfcurrentTrackNumberDivision = currentTrackNumberDivision - 1; % in case CurrentTrackNumber is ODD sister TrackNumber is CurrentTraackNumber minus 1
                                else
                                    SisterOfcurrentTrackNumberDivision = currentTrackNumberDivision + 1; % in case CurrentTrackNumber is ODD sister TrackNumber is CurrentTraackNumber plus 1
                                end

                                % determine whether sister of
                                % putative mother cell was assigned
                                % lost
                                SisterOfcurrentTrackNumberLostLogical = rawdatatableCATallFiles.Colony == colonyNumber & rawdatatableCATallFiles.TrackNumber == SisterOfcurrentTrackNumberDivision & rawdatatableCATallFiles.Lost == 1;

                                if sum(SisterOfcurrentTrackNumberLostLogical) > 0 % in case sister of putative mother cell was lost

                                    LostSisterCellData             = rawdatatableCATallFiles(SisterOfcurrentTrackNumberLostLogical,:);
                                    TimePointWhenSisterCellWasLost = LostSisterCellData.TimePoint;

                                    if TP - TimePointWhenSisterCellWasLost < 4 % compare FL values to determine best match

                                        SisterCellDataLogical               = currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TimePoint == TP     & currentColonyAndNextTP.TrackNumber == currentTrackNumberDivision;
                                        WronglyAssignedDaughterCellLogical1 = currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TimePoint == TP +1  & currentColonyAndNextTP.TrackNumber == currentTrackNumberDivision * 2;
                                        WronglyAssignedDaughterCellLogical2 = currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TimePoint == TP +1  & currentColonyAndNextTP.TrackNumber == currentTrackNumberDivision * 2 + 1;

                                        if sum(SisterCellDataLogical) > 0 & sum(WronglyAssignedDaughterCellLogical1) > 0 & sum(WronglyAssignedDaughterCellLogical2) > 0

                                        SisterCellData                   = currentColonyAndNextTP(SisterCellDataLogical,:);
                                        WronglyAssignedDaughterCellData1 = currentColonyAndNextTP(WronglyAssignedDaughterCellLogical1,:);
                                        WronglyAssignedDaughterCellData2 = currentColonyAndNextTP(WronglyAssignedDaughterCellLogical2,:);

                                        CorrectLostSisterAssignmentMatrix      = [LostSisterCellData; SisterCellData; WronglyAssignedDaughterCellData1; WronglyAssignedDaughterCellData2];
                                        CorrectLostSisterAssignmentMatrixArray = table2array(CorrectLostSisterAssignmentMatrix);

                                        % Determine unwighted normalied euclidean distance
                                        % of all background corrected fluorescence channel
                                        DistanceEuclideanFLwronglyAssignedLostSister      = pdist(CorrectLostSisterAssignmentMatrixArray(:,SumBgCorrectedChannelColumn),'seuclidean');
                                        EuclideanTrackDistanceFLwronglyAssignedLostSister = squareform(DistanceEuclideanFLwronglyAssignedLostSister);

                                        % assigns 99999 to diagonal to remove 0
                                        % which interfere with euclidean
                                        % minimum
                                        EuclideanTrackDistanceFLwronglyAssignedLostSister(logical(eye(size(EuclideanTrackDistanceFLwronglyAssignedLostSister)))) = 99999;

                                        EuclideanTrackDistanceFLwronglyAssignedLostSisterComp = EuclideanTrackDistanceFLwronglyAssignedLostSister(3:4, 1:2);
                                        CurrentEuclideanDistanceFLwrongSister                 = min(min(EuclideanTrackDistanceFLwronglyAssignedLostSisterComp));

                                        % Identifies row and column that match
                                        % current minimal euclidean distance
                                        [rowNextTrack, rowCurrentTrack] = find(EuclideanTrackDistanceFLwronglyAssignedLostSisterComp == CurrentEuclideanDistanceFLwrongSister);

                                        rowNextTrackCorrected    = rowNextTrack + 2;

                                        if     rowNextTrackCorrected == 3 & rowCurrentTrack == 2
                                            currentColonyAndNextTP.TrackNumber(WronglyAssignedDaughterCellLogical1,:) = currentTrackNumberDivision;
                                            currentColonyAndNextTP.TrackNumber(WronglyAssignedDaughterCellLogical2,:) = SisterOfcurrentTrackNumberDivision;
                                        elseif rowNextTrackCorrected == 3 & rowCurrentTrack == 1
                                            currentColonyAndNextTP.TrackNumber(WronglyAssignedDaughterCellLogical1,:) = SisterOfcurrentTrackNumberDivision;
                                            currentColonyAndNextTP.TrackNumber(WronglyAssignedDaughterCellLogical2,:) = currentTrackNumberDivision;
                                        elseif rowNextTrackCorrected == 4 & rowCurrentTrack == 2
                                            currentColonyAndNextTP.TrackNumber(WronglyAssignedDaughterCellLogical2,:) = currentTrackNumberDivision;
                                            currentColonyAndNextTP.TrackNumber(WronglyAssignedDaughterCellLogical1,:) = SisterOfcurrentTrackNumberDivision;
                                        elseif rowNextTrackCorrected == 4 & rowCurrentTrack == 1
                                            currentColonyAndNextTP.TrackNumber(WronglyAssignedDaughterCellLogical2,:) = SisterOfcurrentTrackNumberDivision;
                                            currentColonyAndNextTP.TrackNumber(WronglyAssignedDaughterCellLogical1,:) = currentTrackNumberDivision;
                                        end

                                        % removes Lost and Division entry from
                                        % correct sister and wrongly
                                        % assigned mother cell
                                        currentTrackNumberDivisionLogical                                     = currentColonyAndNextTP.TimePoint == TP & currentColonyAndNextTP.Division == 1 & currentColonyAndNextTP.TrackNumber == currentTrackNumberDivision;
                                        currentColonyAndNextTP.Division(currentTrackNumberDivisionLogical)    = 0;
                                        rawdatatableCATallFiles.Lost(SisterOfcurrentTrackNumberLostLogical,:) = 0;

                                        end

                                    end

                                end

                            end

                        end




                        %% ERROR handling
                        %=======================> 
                        % find not assigned tracks in current
                        % Colony and look for recently lost
                        % tracks and assign if eucl. distance
                        % close enough

                        NotAssignedTracksLogical     = currentColonyAndNextTP.TimePoint == TP + 1 & currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TrackNumber == 0 & currentColonyAndNextTP.Apoptosis == 0;
                        AlreadyAssignedTracksLogical = currentColonyAndNextTP.TimePoint == TP + 1 & currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TrackNumber ~= 0;
                        RecentlyLostTracksLogical = rawdatatableCATallFiles.Colony == colonyNumber & rawdatatableCATallFiles.TimePoint <= TP - 1 & rawdatatableCATallFiles.TimePoint >= TP - 4 & rawdatatableCATallFiles.Lost == 1;

                        if TrackNo == CurrentTPCellNumber & sum(NotAssignedTracksLogical) > 0 & sum(RecentlyLostTracksLogical) > 0

                        % checks whether putative lost track has already been assigned in next TP and only proceeds if this is not the case
                        RecentlyLostTrackNumberData    = rawdatatableCATallFiles(RecentlyLostTracksLogical,:); 
                        RecentlyLostTrackNumberList    = RecentlyLostTrackNumberData.TrackNumber;
                        AlreadyAssignedTrackNumberList = currentColonyAndNextTP.TrackNumber(AlreadyAssignedTracksLogical,:);

                        if sum(~ismember(RecentlyLostTrackNumberList, AlreadyAssignedTrackNumberList)) > 0

                        NotAssignedTracksData       = currentColonyAndNextTP(NotAssignedTracksLogical,:);
                        NotAssignedTracksDataIndex  = find(NotAssignedTracksLogical == 1);

                        RecentlyLostAndNotAssignedTrackDataMatrix      = [RecentlyLostTrackNumberData; NotAssignedTracksData];
                        RecentlyLostAndNotAssignedTrackDataMatrixArray = table2array(RecentlyLostAndNotAssignedTrackDataMatrix);

                        % Determine unwighted normalied euclidean distance
                        % of all background corrected fluorescence channel
                        DistanceEuclideanFLlostAndNotAssigned      = pdist(RecentlyLostAndNotAssignedTrackDataMatrixArray(:,SumBgCorrectedChannelColumn),'seuclidean');
                        EuclideanTrackDistanceFLlostAndNotAssigned = squareform(DistanceEuclideanFLlostAndNotAssigned);

                        % assigns 99999 to diagonal to remove 0
                        % which interfere with euclidean
                        % minimum
                        EuclideanTrackDistanceFLlostAndNotAssigned(logical(eye(size(EuclideanTrackDistanceFLlostAndNotAssigned)))) = 99999;

                        for jjj = 1:sum(RecentlyLostTracksLogical)

                        EuclideanTrackDistanceFLlostAndNotAssignedComp        = EuclideanTrackDistanceFLlostAndNotAssigned(numel(size(RecentlyLostAndNotAssignedTrackDataMatrix,1) + 1, 1:size(RecentlyLostAndNotAssignedTrackDataMatrix,1)));
                        CurrentEuclideanTrackDistanceFLlostAndNotAssignedComp = min(min(EuclideanTrackDistanceFLlostAndNotAssignedComp));

                        if ~isempty(CurrentEuclideanTrackDistanceFLlostAndNotAssignedComp) ...
                              & ~isnan((CurrentEuclideanTrackDistanceFLlostAndNotAssignedComp))  

                        % Identifies row and column that match
                        % current minimal euclidean distance
                        [rowNextTrack, rowCurrentTrack] = find(EuclideanTrackDistanceFLlostAndNotAssignedComp == CurrentEuclideanTrackDistanceFLlostAndNotAssignedComp);
                        rowNextTrackCorrected           = rowNextTrack + size(RecentlyLostAndNotAssignedTrackDataMatrix,1);

                        currentColonyAndNextTP.TrackNumber(NotAssignedTracksDataIndex(rowNextTrack),:) = RecentlyLostAndNotAssignedTrackDataMatrix.TrackNumber(rowCurrentTrack,:);


                        EuclideanTrackDistanceFLlostAndNotAssigned(rowNextTrackCorrected,:) = 99999;
                        EuclideanTrackDistanceFLlostAndNotAssigned(:,rowCurrentTrack)       = 99999;

                        RecentlyLostTracksNowCorrectedLogical = rawdatatableCATallFiles.Colony == colonyNumber & rawdatatableCATallFiles.TimePoint <= TP -1 & rawdatatableCATallFiles.TimePoint >= TP - 4 & rawdatatableCATallFiles.Lost == 1 & rawdatatableCATallFiles.TrackNumber == RecentlyLostAndNotAssignedTrackDataMatrix.TrackNumber(rowCurrentTrack,:);
                        rawdatatableCATallFiles.Lost(RecentlyLostTracksNowCorrectedLogical,:) = 0;

                        end

                        end

                        end

                        end







                        %% ERROR handling
                        %=======================>
                        % In case last available TrackNo of current
                        % TP has been assigned check
                        % whether there are assigned tracks
                        % that change Area between TP-1 and TP
                        % AND TP and TP+1 over 1.5x. If at the same time another
                        % track reduces its Area between TP-1 and TP over 1.5x and ends with
                        % division the scenario is indicative
                        % of fusion event that happened while
                        % other cell divided which lead to
                        % undected division and mix up of
                        % subsequent tracks
                        CurrentTPDivisionLogical = currentColonyAndNextTP.TimePoint == TP & currentColonyAndNextTP.Division == 1;

                        if TrackNo == CurrentTPCellNumber & sum(CurrentTPDivisionLogical) > 0

                        % extracts Last Current and Next data from all assigned tracks in TP+1 of current colony. Subquently the change of Area between TP-1 and TP as well as TP and TP+1 if 
                        % avaiable is determined. In case any
                        % track shows increase and subsequent
                        % reduction of Area above 1.5x and
                        % another track that ended as division
                        % showed drop of 1.5x proceed with
                        % error handling.
                        LastCurrentAndNextTPassignedTracksLogical =  currentColonyAndNextTP.TimePoint == TP - 1 & currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TrackNumber ~= 0 ...
                                                                   | currentColonyAndNextTP.TimePoint == TP     & currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TrackNumber ~= 0 ...
                                                                   | currentColonyAndNextTP.TimePoint == TP + 1 & currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TrackNumber ~= 0;

                        CurrentlyAssignedTrackNumbers                    = unique(currentColonyAndNextTP.TrackNumber(LastCurrentAndNextTPassignedTracksLogical,:));                                        
                        LastCurrentNextTPAssignedTrackNumberArea         = cell(1,numel(CurrentlyAssignedTrackNumbers)); %preallocate  
                        LastCurrentNextTPAssignedTrackNumberAreaDiff     = cell(1,numel(CurrentlyAssignedTrackNumbers)); %preallocate    
                        LastCurrentNextTPAssignedTrackNumberAreaDiffRate = cell(1,numel(CurrentlyAssignedTrackNumbers)); %preallocate

                        % Extracts Area data of all tracks and
                        % calculates chnage between TP-1 TP and
                        % TP+1
                       for iii = 1:numel(CurrentlyAssignedTrackNumbers)
                          CurrentlyAssignedTrackNumberLogical                   = currentColonyAndNextTP.TrackNumber == CurrentlyAssignedTrackNumbers(iii);
                          LastCurrentNextTPAssignedTrackNumberArea{iii}         = currentColonyAndNextTP.Area(CurrentlyAssignedTrackNumberLogical);
                          LastCurrentNextTPAssignedTrackNumberAreaDiff{iii}     = diff(LastCurrentNextTPAssignedTrackNumberArea{iii});
                          LastCurrentNextTPAssignedTrackNumberAreaDiffRate{iii} = LastCurrentNextTPAssignedTrackNumberAreaDiff{iii} ./ LastCurrentNextTPAssignedTrackNumberArea{iii}(1:end-1);
                       end

                       % checks whether any track Area changes 1.5x up and 1.5x down between TP-1 TP and TP+1                                   
                       LastCurrentNextTPAssignedTrackNumberAreaLogical    = cellfun(@(x) x > 0.5 | x < -0.5, LastCurrentNextTPAssignedTrackNumberAreaDiffRate, 'UniformOutput', false);
                       LastCurrentNextTPAssignedTrackNumberAreaLogicalSum = cellfun(@(x) sum(x), LastCurrentNextTPAssignedTrackNumberAreaLogical, 'UniformOutput', false);
                       TrackWithStrongAreaReductionAndIncreaseIndex       = find([LastCurrentNextTPAssignedTrackNumberAreaLogicalSum{:}] == 2);

                       % checks whether any tracks that ended
                       % with division has drop of Area above
                       % 1.5x between TP-1 and TP
                       [TrackNumbersWithStrongAreaReductionRowIndex,~] = find([LastCurrentNextTPAssignedTrackNumberAreaLogicalSum{:}],1);
                       TracksNumbersWithStrongAreaReduction            = CurrentlyAssignedTrackNumbers(TrackNumbersWithStrongAreaReductionRowIndex);
                       TracksNumbersThatEndWithDivision                = currentColonyAndNextTP.TrackNumber(CurrentTPDivisionLogical,:);

                       % if criteria are meet proceed with
                       % error handling and correction
                       if ~isempty(TrackWithStrongAreaReductionAndIncreaseIndex) & ismember(TracksNumbersWithStrongAreaReduction,TracksNumbersThatEndWithDivision)




                         % look for tracks where XY eucl dist assignment is unusually far away when compared to all so far assigned XY tracks  
                         AllAssignedTrackDataLogical          = rawdatatableCATallFiles.TrackNumber ~= 0;
                         AllAssignedEuclideanDistanceXY       = rawdatatableCATallFiles.AssignedEuclideanDistanceXY(AllAssignedTrackDataLogical,:);
                         MeanOfAllAssignedEuclideanDistanceXY = mean(AllAssignedEuclideanDistanceXY);
                         StdOfAllAssignedEuclideanDistanceXY  = std(AllAssignedEuclideanDistanceXY);

                         PutativeAssignmentErrorCurrentTPlogical = currentColonyAndNextTP.AssignedEuclideanDistanceXY >= MeanOfAllAssignedEuclideanDistanceXY * StdOfAllAssignedEuclideanDistanceXY & currentColonyAndNextTP.TimePoint == TP;
                         PutativeAssignmentErrorNextTPlogical    = currentColonyAndNextTP.AssignedEuclideanDistanceXY >= MeanOfAllAssignedEuclideanDistanceXY * StdOfAllAssignedEuclideanDistanceXY & currentColonyAndNextTP.TimePoint == TP + 1;


                         if sum(PutativeAssignmentErrorCurrentTPlogical) == 1 & sum(PutativeAssignmentErrorNextTPlogical) == 1

                         % determine TrackNumer of putative assignment error in TP
                         PutativeAssigmentErrorCurrentTPtrackNumberlogical = currentColonyAndNextTP.TrackNumber(PutativeAssignmentErrorCurrentTPlogical,:);

                         % determine TrackNumber of putative
                         % assignment error is located in TP+1                                    
                         PutativeAssigmentErrorCurrentTPtrackNumberNextTPlogical = currentColonyAndNextTP.TrackNumber == PutativeAssigmentErrorCurrentTPtrackNumberlogical & currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TimePoint == TP + 1;



                         if sum(PutativeAssigmentErrorCurrentTPtrackNumberNextTPlogical) > 0

                             % Replaces TP+1 track of putative assignment error
                         % in TP with putative assignment error
                         % trackn in TP+1
                         currentColonyAndNextTP.TrackNumber(PutativeAssigmentErrorCurrentTPtrackNumberNextTPlogical,:) = currentColonyAndNextTP.TrackNumber(PutativeAssignmentErrorNextTPlogical,:);

                         % Replaces putative assignment error
                         % of TP+1 with track number of just
                         % repalced assigment error of current
                         % TP (basically swap assignment error
                         % tracknumbers in TP+1)
                         currentColonyAndNextTP.TrackNumber(PutativeAssignmentErrorNextTPlogical,:) = currentColonyAndNextTP.TrackNumber(PutativeAssignmentErrorCurrentTPlogical,:);


                         NotDetectedDivisionTrackNumber                 = intersect(TracksNumbersWithStrongAreaReduction,TracksNumbersThatEndWithDivision);
                         NotDetectedDivisionTrackNumberCurrentTPLogical = currentColonyAndNextTP.TrackNumber == NotDetectedDivisionTrackNumber & currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TimePoint == TP;
                         NotDetectedDivisionTrackNumberLastTPLogical    = currentColonyAndNextTP.TrackNumber == NotDetectedDivisionTrackNumber & currentColonyAndNextTP.Colony == colonyNumber & currentColonyAndNextTP.TimePoint == TP - 1;

                         currentColonyAndNextTP.TrackNumber(NotDetectedDivisionTrackNumberCurrentTPLogical,:) = NotDetectedDivisionTrackNumber * 2;
                         currentColonyAndNextTP.TrackNumber(PutativeAssignmentErrorCurrentTPlogical,:)        = NotDetectedDivisionTrackNumber * 2 + 1;

                         % correct division entries of TP and
                         % TP - 1 
                         currentColonyAndNextTP.Division(NotDetectedDivisionTrackNumberCurrentTPLogical,:) = 0;
                         currentColonyAndNextTP.Division(NotDetectedDivisionTrackNumberLastTPLogical,:)    = 1;

                         end

                         end

                       end

                       end













                        %% Compare assigned track to all
                        % previously assigned tracks of this colony
                        % to detect assignment errors
                        VerifyTrackAssignmentTable = [currentColonyAndNextTP(rowNextTrackCorrected,:); last3TParrayMean];
                        VerifyTrackAssignmentArray = double(table2array(VerifyTrackAssignmentTable));

                        % Determine unwighted euclidean distance of XY coordinates
                        DistanceEuclideanFluorescenceVerifyTrack      = pdist(VerifyTrackAssignmentArray(:,SumBgCorrectedChannelColumn),'euclidean');
                        EuclideanTrackDistanceFluorescenceVerifyTrack = squareform(DistanceEuclideanFluorescenceVerifyTrack);

                        % assigns 99999 to diagonal to remove 0
                        % which interfere with euclidean
                        % minimum
                        EuclideanTrackDistanceFluorescenceVerifyTrack(logical(eye(size(EuclideanTrackDistanceFluorescenceVerifyTrack)))) = 99999;

                        % filters euclidean distance
                        % matrix for entries related to
                        % just assigned Tracknumber
                        EuclideanTrackDistanceVerifyNextTPCompLogical          = VerifyTrackAssignmentTable.TimePoint == TP + 1;
                        EuclideanTrackDistanceVerifyNextTPCompLogicalHor       = EuclideanTrackDistanceVerifyNextTPCompLogical';
                        EuclideanTrackDistanceVerifyprevious3TPCompLogicalVert = VerifyTrackAssignmentTable.TimePoint == TP - 1;
                        EuclideanTrackDistanceFluorescenceVerifyTrackComp      = EuclideanTrackDistanceFluorescenceVerifyTrack(EuclideanTrackDistanceVerifyprevious3TPCompLogicalVert, EuclideanTrackDistanceVerifyNextTPCompLogicalHor);
                        EuclideanTrackDistanceVectorVerifyFluorescence         = unique(EuclideanTrackDistanceFluorescenceVerifyTrackComp);

                        % Determines minimal euclicean distance of
                        % current non redundant matrix
                        CurrentEuclideanDistanceFluorescenceVerifyTrack = min(EuclideanTrackDistanceVectorVerifyFluorescence);

                        if ~isempty(CurrentEuclideanDistanceFluorescenceVerifyTrack)

                            % Identifies row and column that match
                            % current minimal euclidean distance
                            [rowVerifyNextTrack, ~] = find(EuclideanTrackDistanceFluorescenceVerifyTrackComp == CurrentEuclideanDistanceFluorescenceVerifyTrack);

                            % shifts row and column index
                            % to match euclidean distance
                            % entries
                            rowVerifyNextTrack = rowVerifyNextTrack + size(EuclideanTrackDistanceFluorescenceVerifyTrack,1) - size(EuclideanTrackDistanceFluorescenceVerifyTrackComp,1);

                            if VerifyTrackAssignmentTable.TrackNumber(rowVerifyNextTrack,:) == VerifyTrackAssignmentTable.TrackNumber(1,:)
                                currentColonyAndNextTP.BetterFluorescenceIntensityFitAvailable(rowNextTrackCorrected,:) = 0;
                            else
                                currentColonyAndNextTP.BetterFluorescenceIntensityFitAvailable(rowNextTrackCorrected,:) = 1;
                                fprintf('Position %03d TimePoint %03d Colony %03d Cycle %03d Row %03d with euclidean distance %d assigned to cell %03d - ERROR FL missmatch\n', currentPosition, TP, colonyNumber, TrackNo, rowNextTrackCorrected, CurrentEuclideanDistanceXY, currentColonyAndNextTP.TrackNumber(rowNextTrackCorrected,:));
                            end


                        end

                    else
                        continue
                    end


                end

            else
                continue
            end

        end



        currentTParrayColony{colonyNumberCounter} = currentColonyAndNextTP(currentColonyAndNextTP.TimePoint == TP,:);

        nextTParray       = currentColonyAndNextTP(currentColonyAndNextTP.TimePoint == TP + 1,:);
        secondNextTParray = currentColonyAndNextTP(currentColonyAndNextTP.TimePoint == TP + 2,:);

    else
        currentTParrayColony{colonyNumberCounter} = [];
    end

end

% EXEPTION in case no colony is present use all data point of currentTP
if numel(currentTPcolonyNumberList) == 0
    currentTPnoColonyNoTrack = currentTP;
end

currentTParray                     = cat(1,currentTParrayColony{:});

rawdatatableCATallFiles(rawdatatableCATallFiles.TimePoint == TP,:)     = [];
rawdatatableCATallFiles(rawdatatableCATallFiles.TimePoint == TP + 1,:) = [];
rawdatatableCATallFiles(rawdatatableCATallFiles.TimePoint == TP + 2,:) = [];

rawdatatableCATallFiles     = [rawdatatableCATallFiles; currentTParray; currentTPnoColonyNoTrack; nextTParray; secondNextTParray];

end


%%
% function that searches for the n-th number of smallest elements in a
% matrix and retries 2d indices
function [smallestNElements smallestColumnIdx smallestRowIdx] = getNElements(A, n)

smallestColumnIdx = zeros(n,1); %preallocate
smallestRowIdx    = zeros(n,1); %preallocate
smallestNElements = zeros(n,1); %preallocate

    for iiii = 1:n

        [Amin, AIdx] = min(A(:));    

        [AminRow,AminColumn] = ind2sub(size(A),AIdx); % transforms linear index back to 2D index
        A(AminRow,:)         = 99999;

        smallestNElements(iiii) = Amin;
        smallestColumnIdx(iiii) = AminColumn;
        smallestRowIdx(iiii)    = AminRow;

    end  
end