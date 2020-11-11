%% Filter for isolated Eents in Time
%identify isolated that occured only once in time window
BinnedXYmatrixSumTP                                       = movsum(BinnedXYmatrix,BinSizeTPs,3); %sum the 2d histogram with window size given iin BINszieTP alon the time axis (3)
[CurrentPositionYcountsID,CurrentPositionXcountsID,TPidx] = ind2sub(size(BinnedXYmatrixSumTP),find(BinnedXYmatrixSumTP == 1)); %find those that only occured once and are therefore isolated

%if this was the first round of filtering, start from first TP

CenterofWindow=median(1:BinSizeTPs); %This is why BinsizeTP needs to be an odd number
ValidTPSlicesForFiltering=1:BinSizeTPs; %use all of the window to filter out isolated events


%map the identified objects back to centroids and thereby cell
CurrentWindowTPs=vertcat(CurrentWindow{:,3});
CentroidX=vertcat(CurrentWindow{:,1});
CentroidY=vertcat(CurrentWindow{:,2});
TPidx2actuallTP=(currentTP-BinSizeTPs+1):currentTP;
CurrentFileactiveIsolated=logical(ones(numel(CentroidY),1)); %keeps track of filterings for every csv file and is then saved in folder
for ii = 1:numel(CurrentPositionYcountsID) %iterate trhough squares where isolated events were found!
    %map them to their original centroids and inactivate them
    IsolatedID = find( CentroidX >= Xedges(CurrentPositionYcountsID(ii))& ...
    CentroidX < Xedges(CurrentPositionYcountsID(ii) + 1) & ...
    CentroidY >= Yedges(CurrentPositionXcountsID(ii)) & ...
    CentroidY < Yedges(CurrentPositionXcountsID(ii) + 1) & ...
    CurrentWindowTPs == TPidx2actuallTP(TPidx(ii)));
    CurrentFileactiveIsolated(IsolatedID,:) = false;
end  