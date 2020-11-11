for jj = BinSizeTPs:-1:1 %read in outputed segmentation csvs into sliding window
    %PixelRange         = 1:BinSizePixel:2049; %our images are usually 2048 pixels wide, split them in windows for counts
    TP2ReadIn         = currentTP-jj+1; %which csv has to be read in now? <-- We look back in time!

    %read in the corresponding csv
    templateTP='t00000'; 
    NumofDigits=length(num2str(TP2ReadIn));
    templateTP((7-NumofDigits):6)=num2str(TP2ReadIn);
    templateZ='z001';
    templateM='m00';
    position=Positionfolders(pos).name;
    Outputname=[position,'_',templateTP,'_',templateZ,'_','w00','_',templateM,'_','mask'];
    OutputFolder=[movieID,'\Analysis\Online_Segmentation\',position,'\'];
    dataframe2=read_mixed_csv([OutputFolder,Outputname,'.csv'],';');
    %trim last column, seems to be an artifact
    dataframe2=dataframe2(2:end,1:end-1);%get rid of last column and header!
    CurrentWindowCSVs{BinSizeTPs-jj+1,1} = dataframe2;%for later filtering FILL WINDOW BACKWARDS IN TIME
    CurrentWindowCSVs{BinSizeTPs-jj+1,2} = [OutputFolder,Outputname];%for later save after filtering

    %read in the positions of centroids
    CurrentPositionXcurrentTP = dataframe2(:,contains(cHeader,'CentroidX'));
    CurrentPositionXcurrentTP = cellfun(@str2double,CurrentPositionXcurrentTP);
    CurrentPositionYcurrentTP = dataframe2(:,contains(cHeader,'CentroidY'));
    CurrentPositionYcurrentTP = cellfun(@str2double,CurrentPositionYcurrentTP);
    %fill the cube from front to back, so with time
    %progression, in Loop we are going the other way to read in
    %csvs correctly
    CurrentWindow{BinSizeTPs-jj+1,1}=CurrentPositionXcurrentTP;
    CurrentWindow{BinSizeTPs-jj+1,2}=CurrentPositionYcurrentTP;
    CurrentWindow{BinSizeTPs-jj+1,3}=repmat(TP2ReadIn,numel(CurrentPositionYcurrentTP),1);

    %fill the moving window by counting the events in the
    %window along the time axis
    %For every centroid, compute distance to centroids in o
    [N,Xedges,Yedges]         = histcounts2(CurrentPositionXcurrentTP,CurrentPositionYcurrentTP,PixelRange,PixelRange);
    BinnedXYmatrix(:,:,BinSizeTPs-jj+1)    = N;          
end