%% get the folder
movieID=uigetdir();

%find the latest Metadata xml
allfiles=dir(movieID);
metafile=['x'];%initiallize with x
for i=1:length(allfiles)
    a=allfiles(i).name;
    if contains(a,'.xml')
        metafile = {metafile a};
    end
end
metafile=sort(metafile);
metafile=strcat(movieID,'\',metafile{1});

%% read in the MetaData
METADATA=xml2struct(metafile);

%How Many Positions are imaged and in what conditions? 
for i=1:length(METADATA.Children)
    %find out wich index is Conditions
    current= METADATA.Children.Name;
    if  isequal(METADATA.Children(i).Name,'PositionData')
        break
    end
end
Conditions=METADATA.Children(i);

%XML has relevant information stored in every 2nd field, starts with empty ends with empty, therefore -1
NumberPositions=(length(Conditions.Children)-1)/2;
disp(sprintf('Positions found: %d',NumberPositions));

%% Condition and Position, but also X,Y Position for image
Positions_XY=cell(NumberPositions,1); %initialize Cell
Positions_Conds=cell(NumberPositions,1); %Initialize Cell
Positions_Names=cell(NumberPositions,1); %Initialize Cell
for i=1:NumberPositions
    index=i*2; %information in every 2nd field
    current_Names  =  {Conditions.Children(index).Children(2).Attributes.Name}; %field PosInfoDimension at place 2 #ASSUMPTION
    current_Values = {Conditions.Children(index).Children(2).Attributes.Value}; %field PosInfoDimension at place 2
    actualposnr=  current_Values{find(contains(current_Names,'index'))};%Get position X Coord
    x=current_Values{find(contains(current_Names,'posX'))};%Get position X Coord
    y=current_Values{find(contains(current_Names,'posY'))};%Get position Y Coord
    
    j=str2num(actualposnr);
    Positions_XY{j,1}= [str2num(x) str2num(y)];
    comment= current_Values{find(contains(current_Names,'comment'))};
    Positions_Conds{j,1}= extractAfter(comment,'[1:1] ');%assume we always just have one image per position and therfore the landmark [1:1]! #ASSUMPTION
    Positions_Names{j,1}= extractBefore(comment,' [1:1]');

end
Positions_XY=cell2mat(Positions_XY);


%% Get the edge length per pixel
MicrometerPerPixel=METADATA.Children(36).Attributes.Value;
MicrometerPerPixel=str2double(MicrometerPerPixel);

%% Condition Information
Positions_Conds= cellfun(@char, Positions_Conds,'UniformOutput',false);%this converts it to cell array with char vectors that can be handled
%if nothing was specified by User it returns "" as string, distiguish, between '' cases, where no condition is and the others
CHECK= strcmp(Positions_Conds,'');
if sum(CHECK) == length(Positions_Conds)
    Conditions=nan;
    NumberConditions=0;
    string2disp='NONE';
else
    Conditions=unique(Positions_Conds);
    NumberConditions=length(Conditions);
    string2disp=num2str(NumberConditions);
end
disp(['Conditions found: ', string2disp]);


%% Wavelength information
%How Many Positions are imaged and in what conditions? 
for i=1:length(METADATA.Children)
    %find out wich index is Conditions
    current= METADATA.Children.Name;
    if  isequal(METADATA.Children(i).Name,'WavelengthCount')
        break
    end
end
a=METADATA.Children(i).Attributes.Value;
NumberWavelengths=str2double(a);

%%%which wavelengths?
Wavelengths=cell(NumberWavelengths,1);
for i=1:length(METADATA.Children)
    %find out wich index is Conditions
    current= METADATA.Children.Name;
    if  isequal(METADATA.Children(i).Name,'WavelengthData')
        break
    end
end
a=METADATA.Children(i).Children;


for i=1:NumberWavelengths
    index=i*2; % XML has relevant information stored in every 2nd field
    Wavelengths_Names={a(index).Children(2).Attributes.Name};%field Wavelengthinfo at place 2 #ASSUMPTION
    Wavelengths_Values={a(index).Children(2).Attributes.Value};%field Wavelengthinfo at place 2 #ASSUMPTION
    Wavelengths{i,1}=Wavelengths_Values{1,find(contains(Wavelengths_Names,'Comment'))};
end
display(sprintf('Channels found: %d',NumberWavelengths));



%We use BF1 as overfocus, BF2 as underfocus
BF1_channel=find(contains(Wavelengths,'BF1'));
BF2_channel=find(contains(Wavelengths,'BF2'));
PE_channel=find(contains(Wavelengths,'PE'));
APC_Channel=find(contains(Wavelengths,'APC'));
%find(~ismember(1:NumberWavelengths,[BF1_channel,BF2_channel,PE_channel]));


%Wavelnegthinfo has to be denoted like w0X starting with channel 1 at w00
BF1=['w0',num2str(BF1_channel-1)];
BF2=['w0',num2str(BF2_channel-1)];
APC=['w0',num2str(APC_Channel-1)];
PE=['w0',num2str(PE_channel-1)];

