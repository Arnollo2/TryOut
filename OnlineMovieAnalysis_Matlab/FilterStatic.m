%% Filter non motile Events %%   
%within five timepoints, the cells must change their Centroid in at
%least 3 pixels to the left/right or down/up
CurrentFileactiveStatic=logical(ones(numel(CentroidY),1));
PixelRange = 1:3:2049;
[N,Xedges,Yedges] = histcounts2(CentroidX,CentroidY,PixelRange,PixelRange);

[CurrentPositionYcountsID,CurrentPositionXcountsID] = find(N > NonMotileThreshold);

for ii = 1:numel(CurrentPositionYcountsID)
    NonMotileID = find(CentroidX >= Xedges(CurrentPositionYcountsID(ii)) & ...
    CentroidX < Xedges(CurrentPositionYcountsID(ii) + 1) & ...
    CentroidY >= Yedges(CurrentPositionXcountsID(ii)) & ...
    CentroidY < Yedges(CurrentPositionXcountsID(ii) + 1));
    CurrentFileactiveStatic(NonMotileID,:) = 0;
end