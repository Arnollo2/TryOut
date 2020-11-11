cc = bwconncomp(bw);%detects objects 
%extract the center of mass per object AND their area
S = regionprops(cc,'Centroid','Area');
NumObjects=cc.NumObjects;

Centroids=inf(NumObjects,2);%number of centroids in 2D --> convert struct to array
Areas=inf(NumObjects,1);%number of centroids in 2D --> convert struct to array
for center=1:NumObjects
    Centroids(center,:)=S(center).Centroid;
    Areas(center,:)=S(center).Area;
end


%% Dilate the Mask + Regional Background correction %%
%takes roughly 1 sec

%dilate for signal
dilation=9;%ADJUST
SE = strel('octagon',dilation);
blackimdil = imdilate(bw,SE);
AllAreasInd=find(blackimdil==1); %list all the pixels belonging to found objects
[AllAreasSubY,AllAreasSubX] =ind2sub(size(blackimdil),AllAreasInd);
AllAreas=horzcat(AllAreasSubX,AllAreasSubY);

%dilate for background
dilation=48;%ADJUST
SE = strel('octagon',dilation);
blackimdilBG = imdilate(bw,SE);
AllAreasIndBG=find(blackimdilBG==1); %list all the pixels belonging to found objects
[AllAreasSubYBG,AllAreasSubXBG] =ind2sub(size(blackimdilBG),AllAreasIndBG);
AllAreasBG=horzcat(AllAreasSubXBG,AllAreasSubYBG);


distancetoCentroids=pdist2(AllAreas,Centroids);%actually still a minor flaw

assigned=zeros(length(AllAreas),1);
for point=1:length(AllAreas)
    distances=distancetoCentroids(point,:);
    NearestObject=find(distances==min(distances));
    
    %although unliekly but might happen that a pixel is similarly close to
    %more than just one object. in that case assign randomly
    if length(NearestObject)> 1 
        NearestObject=randsample(NearestObject,1);
    end
    
    assigned(point,1)=NearestObject;
end

%do the same for bigger dilated background image
distancetoCentroidsBG=pdist2(AllAreasBG,Centroids);
assignedBG=zeros(length(AllAreasBG),1);
for point=1:length(AllAreasBG)
    distances=distancetoCentroidsBG(point,:);
    NearestObject=find(distances==min(distances));
    
    %although unliekly but might happen that a pixel is similarly close to
    %more than just one object. in that case assign randomly
    if length(NearestObject)> 1 
       NearestObject=randsample(NearestObject,1);
    end
    
    assignedBG(point,1)=NearestObject;
end

%% update mask and retrieve data from other channels
mask=zeros(size(blackimdil));
maskBG=zeros(size(blackimdilBG));
SignalArea=inf(NumObjects,1);
SumSignalPE=inf(NumObjects,1);
StdDevSignalPE=inf(NumObjects,1);
SumSignalAPC=inf(NumObjects,1);
StdDevSignalAPC=inf(NumObjects,1);
BgSignalPE=inf(NumObjects,1);
BgSignalAPC=inf(NumObjects,1);
SumSignalBF1=inf(NumObjects,1);
StdDevSignalBF1=inf(NumObjects,1);

for object=1:NumObjects
    assignedPixels=AllAreasInd(assigned(:,1)==object,1); %get pixels
    assignedPixelsBG=AllAreasIndBG(assignedBG(:,1)==object,1); %get pixels
    assignedPixelsBG=assignedPixelsBG(~ismember(assignedPixelsBG,AllAreasInd)); %only get the area around detected objects!
    %compute background
    backgroundArea=length(assignedPixelsBG);
    SignalBGPE=PEimage(assignedPixelsBG);
    SignalBGAPC=APCimage(assignedPixelsBG);
    SignalBF1=BF1image(assignedPixels);
    BgSignalPE(object,1)=sum(SignalBGPE)/backgroundArea; %the signal of background per pixel
    BgSignalAPC(object,1)=sum(SignalBGAPC)/backgroundArea; %the signal of background per pixel
    %compute Signal
    SignalPE=PEimage(assignedPixels); %get Signals
    SignalAPC=APCimage(assignedPixels);
    SignalArea(object,1)=length(assignedPixels);%get area of mask for Bg correction
    SumSignalPE(object,1)=sum(SignalPE);
    SumSignalAPC(object,1)=sum(SignalAPC);           
    StdDevSignalPE(object,1)=std(double(SignalPE));
    StdDevSignalAPC(object,1)=std(double(SignalAPC));
    StdDevSignalBF1(object,1)=std(double(SignalBF1));
    SumSignalBF1(object,1)=sum(double(SignalBF1));

    mask(assignedPixels)=object;  %Update mask
    maskBG(assignedPixelsBG)=object;  %Update mask for Background
end

%The actual Bg correction
SumBgCorrectedPE=SumSignalPE-(BgSignalPE.*SignalArea);
SumBgCorrectedAPC=SumSignalAPC-(BgSignalAPC.*SignalArea);


%imshow(imadjust(PEimage))
%for ii=1:NumObjects
%   hold on
%   assignedPixelsBG=find(maskBG==ii);
%   [PixY,PixX]=ind2sub(size(maskBG),assignedPixelsBG);
%   scatter(PixX,PixY)
%end

%% Write CSVs into directories %%%    
%takes roughly 0.5 sec
dataframe=horzcat(repmat(pos,NumObjects,1),repmat(currentTP,NumObjects,1),Centroids(:,1),Centroids(:,2),Areas,SumSignalPE,SumBgCorrectedPE,SumSignalAPC,SumBgCorrectedAPC,SumSignalBF1,StdDevSignalBF1);
%header
cHeader = {'Position' 'TimePoint' 'CentroidX' 'CentroidY' 'Area' 'SumSignalPE' 'SumBgCorrectedPE' 'SumSignalAPC' 'SumBgCorrectedAPC','SumSignalBF1','StdDevSignalBF1'}; 
commaHeader = [cHeader;repmat({';'},1,numel(cHeader))]; %insert commaas
commaHeader = commaHeader(:)';
textHeader = cell2mat(commaHeader); %cHeader in text with commas

%write header to file but check if folder already exists
OutputFolder=[movieID,'\Analysis\Online_Segmentation\',position,'\'];
if exist(OutputFolder)<1
    mkdir(OutputFolder);
end

%create CSV name, time is writen txxxxx
templateTP='t00000'; 
NumofDigits=length(num2str(currentTP));
templateTP((7-NumofDigits):6)=num2str(currentTP);
templateZ='z001';
templateM='m00';

Outputname=[position,'_',templateTP,'_',templateZ,'_','w00','_',templateM,'_','mask'];
fid = fopen([OutputFolder,Outputname,'.csv'],'w'); 
fprintf(fid,'%s\n',textHeader);
fclose(fid);

%now append the data
dlmwrite([OutputFolder,Outputname,'.csv'],dataframe,'-append','delimiter',';');

%save mask as png
%imwrite(mask,[OutputFolder,Outputname,'.png'])
%to display %
%RGB_label = label2rgb(mask, @copper, 'c', 'shuffle'); %just for display
%imwrite(RGB_label,[OutputFolder,'mask_',num2str(currentTP),'.tif'])
%imwrite(RGB_label,[OutputFolder,Outputname,'.png'])
%imwrite(ahisteq,[OutputFolder,'BF1',Outputname,'.png'])

%imwrite(RGB_label,[OutputFolder,'labelledmasks\',Outputname,'.png'])

