CurrentWindowActive=CurrentFileactiveStatic&CurrentFileactiveIsolated; %All TPs vertcated here, need to be subsetted to be applied
TPinCenter=TPidx2actuallTP(CenterofWindow);

%only save the TPs in Window from center upwards, thereby last center position is most dominant and will be saved last
TrackingWindowActive=cell(5,1);%save the active logicals here to be used in Tracking
for tp=CenterofWindow:BinSizeTPs %currentTP is last frame in Window

   %Subset
    CSV2save=CurrentWindowCSVs{tp,1};
    CSV2saveName=CurrentWindowCSVs{tp,2};
    WindowTP=TPidx2actuallTP(tp);%these timepoints are lower than WindowCenter and if current just passed window size, they should be saved 
    TPsLogicals=CurrentWindowTPs== WindowTP;
    WindowTPFileactive=CurrentWindowActive(TPsLogicals); %subset for logicals specific to that timepoint
    TrackingWindowActive{tp,1}= WindowTPFileactive; %Store for tracking
    CSV2save=CSV2save(WindowTPFileactive,:);

    %now write out the filtered data
    fid = fopen([CSV2saveName,'_FILTERED','.csv'],'w'); 
    fprintf(fid,'%s\n',textHeader);
    fclose(fid);
    %convert cell to mat for saving
    CSV2saveMat=cellfun(@str2num, CSV2save);
    dlmwrite([CSV2saveName,'_FILTERED','.csv'],CSV2saveMat,'-append','delimiter',';');
    dlmwrite([CSV2saveName,'_Logicals4FILTERING','.csv'],WindowTPFileactive,'delimiter',';');
end
