function fscvScan(src, event, c, hGui)
% If fscvScan running first time, initialize persistent vars
% Run cycling waveforms without output stim and plot data
% When capture requested this function is terminated and GUI button
% initializes startCapture function to run fscvCapture
persistent fscvData firstData fscvBuffer trigFSCVActive trigFSCVMoment prevtrigFSCVMoment trappedInsideTrigMoment flagLastScanRetrieve firsttrigFSCVMoment

% Get capture toggle button value (1 or 0) from UI
captureRequested = get(hGui.CaptureButton, 'value');
if ~captureRequested
    if event.TimeStamps(1)==0
        firstData= 0;
        trigFSCVActive = false;       % trigger condition flag
        trigFSCVMoment = [];          % data timestamp when trigger condition met
        firsttrigFSCVMoment = [];
        prevtrigFSCVMoment = [];
        fscvBuffer = [];          % data buffer
        prevData = [];            % last data point from previous callback execution
        fscvData=[];
        flagLastScanRetrieve=0;
        trappedInsideTrigMoment=0;
    else
        prevData = fscvBuffer(end, :);
    end
    % Store continuous acquistion data in persistent FIFO buffer dataBuffer
    latestData = [event.TimeStamps, event.Data];
    fscvBuffer = [fscvBuffer; latestData];
    numSamplesToDiscard = size(fscvBuffer,1) - c.bufferSize;
    if (numSamplesToDiscard > 0)
        fscvBuffer(1:numSamplesToDiscard, :) = [];
    end

    % Update live data plot
    % Plot latest plotTimeSpan seconds of data in dataBuffer
    timeToRecord = sscanf(get(hGui.RecordTime, 'string'), '%f');      %add
    timeToPlot = sscanf(get(hGui.dispTime, 'string'), '%f');      %add
    samplesToPlot = min([round(timeToPlot * src.Rate), size(fscvBuffer,1)]);
    firstPoint = size(fscvBuffer, 1) - samplesToPlot + 1;
    if firstPoint<0
        firstPoint=1;
    end
    % Update x-axis limits
    if fscvBuffer(firstPoint)<fscvBuffer(end,1)

        xlim(hGui.Axes1, [fscvBuffer(firstPoint,1), fscvBuffer(end,1)]);
        % Live plot has one line for each acquisition channel (all channels)
        for ii = 1:(numel(hGui.LivePlot)-1)
            set(hGui.LivePlot(ii), 'XData', fscvBuffer(firstPoint:end, 1), ...      %time
                                   'YData', fscvBuffer(firstPoint:end, 1+ii))
        end
    end
    % Get the trigger configuration parameters from UI text inputs
    % No validation of user input 
    trigConfig.Channel = sscanf(get(hGui.FSCVTrigChannel, 'string'), '%u');
    trigConfig.Level = sscanf(get(hGui.FSCVTrigLevel, 'string'), '%f');
    trigConfig.Slope = sscanf(get(hGui.FSCVTrigSlope, 'string'), '%f');
    [trigFSCVActive, trigFSCVMoment] = trigDetect(prevData, latestData, trigConfig);

    if trigFSCVActive 
        fscvparam=getUserParams(hGui);
        padding_rangeout=0;        %samples to add before and after actual scan time
        scanData=0;
        trigSampleIndex=0;
        lastScanSampleIndex=0;
        scanRate = fscvparam.scanRate;
        vaMin = fscvparam.vaMin;      
        vaMax = fscvparam.vaMax;    
        freq = fscvparam.freq;      
        timeToScan = abs(vaMax-vaMin)./scanRate.*2;
        
        % Find index of sample in dataBuffer with timestamp value trigMoment   
        trigSampleIndex = find(fscvBuffer(:,1) == trigFSCVMoment, 1, 'first')-padding_rangeout;
        lastScanSampleIndex = round(trigSampleIndex + timeToScan * src.Rate()+padding_rangeout*2);       %add more indeces so not to cutt off 06/14

        %PLOTTING ONLINE
        scopeDisplayChannel = sscanf(get(hGui.ScopeChannel, 'string'), '%f');
        set(hGui.ScopePlot, 'XData', fscvBuffer(trigSampleIndex:lastScanSampleIndex, 1), ...
                                  'YData', fscvBuffer(trigSampleIndex:lastScanSampleIndex, scopeDisplayChannel+1))        %scope ch from user
        scopeDisplayChannel2 = sscanf(get(hGui.ScopeChannel2, 'string'), '%f');
        set(hGui.ScopePlot2, 'XData', fscvBuffer(trigSampleIndex:lastScanSampleIndex, 1), ...
                                  'YData', fscvBuffer(trigSampleIndex:lastScanSampleIndex, scopeDisplayChannel2+1))        %ch1
        scopeDisplayChannel3 = sscanf(get(hGui.ScopeChannel3, 'string'), '%f');
        set(hGui.ScopePlot3, 'XData', fscvBuffer(trigSampleIndex:lastScanSampleIndex, 1), ...
                                  'YData', fscvBuffer(trigSampleIndex:lastScanSampleIndex, scopeDisplayChannel3+1))        %ch1
    end
    set(hGui.StatusText, 'String', 'Not Recording');
    
    drawnow;
end
