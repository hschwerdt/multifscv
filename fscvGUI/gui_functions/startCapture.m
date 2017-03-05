function startCapture(hObject, ~, hGui)
global outputData dataListener errorListener outputListener fscvparam s scansperupdate stimEnable recordCount
if get(hObject, 'value')
    recordCount=recordCount+1;
    fscvparam= getUserParams(hGui); 
    set(hGui.CaptureButton, 'Value', 1);
    % If button is pressed clear data capture plot
    for ii = 1:numel(hGui.CapturePlot)
        set(hGui.CapturePlot(ii), 'XData', NaN, 'YData', NaN);
    end
    
    %reset everything before recording
    stop(s);
    delete(outputListener);
    delete(dataListener);
    delete(errorListener);
    %release(s);
    delete(s);
    s=initializeSession;
    
    
    outputDataNoStim = createOutput(s,fscvparam); %for after stimulation period and discrete amount of recording thereafter
    
    s.IsContinuous = true;
    if ~stimEnable
        outputData= createCaptureOutput(s,fscvparam); 
    else
        outputData=outputDataNoStim;
    end
    queueOutputData(s,outputData);
    s.NotifyWhenDataAvailableExceeds=round(s.Rate*(1/fscvparam.freq)*scansperupdate);        %update volume
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
    %s.NotifyWhenScansQueuedBelow = min(recordTime-lagbetweenIO, 15*s.Rate-lagbetweenIO);      %After record period use litener to queue empty (ie no stim) data
    s.NotifyWhenScansQueuedBelow = recordTime-lagbetweenIO;
    % Add a listener for DataAvailable events and specify the callback function
    dataListener = addlistener(s, 'DataAvailable', @(src,event) fscvCapture(src, event, fscvcapture, fscvparam, hGui));
    errorListener = addlistener(s, 'ErrorOccurred', @(src,event) disp(getReport(event.Error)));
    outputListener = s.addlistener('DataRequired', @(src,event) src.queueOutputData(outputDataNoStim));


    s.startBackground();
end
end

