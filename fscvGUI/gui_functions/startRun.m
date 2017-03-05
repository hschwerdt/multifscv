function startRun(hObject, ~, hGui)
global outputData dataListener errorListener outputListener s scansperupdate
if get(hObject, 'value')
    fscvparam=getUserParams(hGui); 
    fscvcapture=fscvparam;
    % If button is pressed clear data capture plot
    for ii = 1:numel(hGui.CapturePlot)
        set(hGui.CapturePlot(ii), 'XData', NaN, 'YData', NaN);
    end
    s.IsContinuous = true;
    outputData= createOutput(s,fscvparam); 
    queueOutputData(s,outputData);
    s.NotifyWhenDataAvailableExceeds=round(s.Rate*(1/fscvparam.freq)*scansperupdate);
    %s.NotifyWhenScansQueuedBelow = 100;
    %%FSCV capture parameters
    % Specify triggered capture timespan, in seconds
    fscvcapture.ScanSpan = fscvparam.timeToScan;
    % Specify triggered capture timespan, in seconds
    fscvcapture.TimeSpan = fscvparam.timeToRecord;
    % Specify continuous data plot timespan, in seconds
    fscvcapture.plotTimeSpan = fscvparam.timeToPlot;
    % Determine the timespan corresponding to the block of samples supplied
    % to the DataAvailable event callback function.
    fscvcallbackTimeSpan = double(s.NotifyWhenDataAvailableExceeds)/s.Rate; %100 samples or 0.1 s default
    % Determine required buffer timespan, seconds
    fscvcapture.bufferTimeSpan = max([fscvcapture.plotTimeSpan, fscvcapture.TimeSpan * 3, fscvcallbackTimeSpan * 3]);
    % Determine data buffer size
    fscvcapture.bufferSize =  round(fscvcapture.bufferTimeSpan * s.Rate);
        lagbetweenIO=500;       %in samples, prevent collision between listeners

    recordTime=round(s.Rate*fscvcapture.TimeSpan);
    s.NotifyWhenScansQueuedBelow = recordTime-lagbetweenIO;
    % Add a listener for DataAvailable events and specify the callback function
    dataListener = addlistener(s, 'DataAvailable', @(src,event) fscvScan(src, event, fscvcapture, hGui));
    errorListener = addlistener(s, 'ErrorOccurred', @(src,event) disp(getReport(event.Error)));

    outputListener = s.addlistener('DataRequired', @(src,event) src.queueOutputData(outputData));

    s.startBackground();
    set(hObject, 'Value', 0);
end
end

