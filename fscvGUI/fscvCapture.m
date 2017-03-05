function fscvCapture(src, event, c, fscvparam, hGui)
%Start recording data to variable
%Store data only in FSCV scans not during hold period
persistent fscvData firstData fscvBuffer trigFSCVActive trigFSCVMoment prevtrigFSCVMoment trappedInsideTrigMoment flagLastScanRetrieve firsttrigFSCVMoment recordCount
% If dataCapture is running for the first time, initialize persistent vars
if event.TimeStamps(1)==0 || length(fscvBuffer)==0
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
timeToRecord = fscvparam.timeToRecord;
timeToPlot = sscanf(get(hGui.dispTime, 'string'), '%f');      %add
samplesToPlot = min([round(timeToPlot * src.Rate), size(fscvBuffer,1)]);
firstPoint = size(fscvBuffer, 1) - samplesToPlot + 1;
if firstPoint<0
    firstPoint=1;
end
if fscvBuffer(firstPoint)<fscvBuffer(end,1)
    % Update x-axis limits
    xlim(hGui.Axes1, [fscvBuffer(firstPoint,1), fscvBuffer(end,1)]);

    % Live plot has one line for each acquisition channel
    for ii = 1:(numel(hGui.LivePlot)-1)
        set(hGui.LivePlot(ii), 'XData', fscvBuffer(firstPoint:end, 1), ...      %time
                               'YData', fscvBuffer(firstPoint:end, 1+ii))
    end
end

% Get capture toggle button value (1 or 0) from UI
captureRequested = get(hGui.CaptureButton, 'value');

    % Get/store trigger configuration parameters from UI text inputs 
    %validation of user input not addressed 
    trigConfig.Channel = sscanf(get(hGui.FSCVTrigChannel, 'string'), '%u');
    trigConfig.Level = sscanf(get(hGui.FSCVTrigLevel, 'string'), '%f');
    trigConfig.Slope = sscanf(get(hGui.FSCVTrigSlope, 'string'), '%f');
        
if captureRequested && ~trigFSCVActive
    set(hGui.StatusText, 'String', ['Recording ' num2str(((fscvBuffer(end,1)-firsttrigFSCVMoment)))]);
    [trigFSCVActive, trigFSCVMoment] = trigDetect(prevData, latestData, trigConfig);

elseif captureRequested && trigFSCVActive 
    padding_rangeout=0;        %samples to add before and after actual scan time
    scanData=0;
    trigSampleIndex=0;
    lastScanSampleIndex=0;
    
    scanRate = fscvparam.scanRate;
    vaMin = fscvparam.vaMin;      %add
    vaMax = fscvparam.vaMax;    %add
    freq = fscvparam.freq;      %add
    timeToScan = abs(vaMax-vaMin)./scanRate.*2;
    % Find index of sample in recent data buffer from notify
    % Find index of sample in dataBuffer with timestamp value trigMoment
    if flagLastScanRetrieve==0
            %if we did not forget any overlying data scan between buffer
            %notifies
            
        trigSampleIndex = find(fscvBuffer(:,1) == trigFSCVMoment, 1, 'first')-padding_rangeout;
        % Find index of sample in dataBuffer to complete the capture
        lastScanSampleIndex = round(trigSampleIndex + timeToScan * src.Rate()+padding_rangeout*2);       %add more indeces so not to cutt off 06/14
        scanData=fscvBuffer(trigSampleIndex:lastScanSampleIndex, :); 
    else
        flagLastScanRetrieve=0;     %reset flag
        trigSampleIndex=round(trappedInsideTrigMoment*src.Rate());
        lastScanSampleIndex = round(trigSampleIndex + timeToScan * src.Rate()+padding_rangeout*2);
        scanData=fscvBuffer(trigSampleIndex:lastScanSampleIndex, :); 
    end
    
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

                              
    %Depends on s.NotifyWhenDataAvailableExceeds (ie. update rate from buffer)
    %if greater this times s.Rate > 0.1 s then we need to log non-"trigged" events 
    insideTrigIndex=0;
    insideTrigMoments=0;
    numInsideTrigMoments=0;
    while length(insideTrigMoments)<=50
        if insideTrigIndex==0
            insideTrigIndex=trigSampleIndex;        %first reference point to use to look for subseq trigs
        end
        insideTrigMoment=0;     %re-initialize each loop
        [insideTrigActive, insideTrigMoment] = trigDetect([], fscvBuffer(insideTrigIndex+5:end,:), trigConfig);
        %insideTrigMoment=insideTrigMoment+(insideTrigIndex+50)./src.Rate();
        if isempty(insideTrigMoment)
               %no trig events found for remaining buffer, exit loop
               break
        end
        if insideTrigMoments==0
            insideTrigMoments=insideTrigMoment;      %initial value is first trig inside
        else
            insideTrigMoments=[insideTrigMoments; insideTrigMoment];
        end
        %redefine insideTrigIndex so next while loop looks for next trig
        %moment in this buffer
        insideTrigIndex=find(fscvBuffer(:,1) == insideTrigMoment, 1, 'first')-padding_rangeout;
        insideLastScanIndex = round(insideTrigIndex + timeToScan * src.Rate()+padding_rangeout*2);   
        % if insideLastScanIndex falls out of current buffer length, need
        % to retrieve this data in next notify
        if insideLastScanIndex>length(fscvBuffer)
            flagLastScanRetrieve=1;
            trappedInsideTrigMoment=insideTrigIndex/src.Rate     %store for next call
            break
        end
        numInsideTrigMoments=numInsideTrigMoments+1;
        scanInsideData=fscvBuffer(insideTrigIndex:insideLastScanIndex, :); 
        scanData=[scanData; scanInsideData];
        
    end

    if firstData==0 
        fscvData=scanData;
        firstData=1;
        firsttrigFSCVMoment=trigFSCVMoment;
    elseif firstData==1   
        %%only if interval greater than some time otherwise consantly storing when above trigger level
            %%% && abs((scanData((end-timeToScan * src.Rate()),1)-trigFSCVMoment) > (.5) )
        fscvData=[fscvData; scanData];
        
    end
        trigFSCVActive = false;
        prevtrigFSCVMoment=trigFSCVMoment;
        assignin('base','fscvData',fscvData);
        
    %display recorded data
    if ((fscvBuffer(end,1)-firsttrigFSCVMoment) > timeToRecord)
        % Reset trigger flag, to allow for a new triggered data capture
        trigFSCVActive = false;
        firsttrigFSCVMoment=[];
        firstData=0;
        %set(hGui.CaptureButton, 0);
        set(hGui.CaptureButton,'Enable','off') 
        captureRequested=0;
        set(hGui.CaptureButton,'Enable','on') 
        % Update captured data plot (one line for each acquisition channel)
        for ii = 1:numel(hGui.CapturePlot)
            set(hGui.CapturePlot(ii), 'XData', fscvData(:, 1), ...
                                      'YData', fscvData(:, 1+ii-1))
        end

        % Update UI to show that capture has been completed
        set(hGui.CaptureButton, 'Value', 0);
        set(hGui.StatusText, 'String', '');
        recordedData=fscvData;
        %assignin('base','recordedfscvData',recordedfscvData);   
        set(hGui.StatusText, 'String', 'Recorded');
        varName = get(hGui.VarName, 'String');
        % Use assignin function to save the captured data in a base workspace variable
        assignin('base', varName, recordedData);
        save(varName,'recordedData')

    FileName=get(hGui.VarName,'string');
    FileNum=strsplit(FileName,'_');
    if length(FileNum)>=2
        FileID=strjoin(FileNum(1:(end-1)),'_');  FileNum=FileNum(end); FileID=char(FileID); FileNum=char(FileNum); FileNum=str2num(FileNum);
        else
            FileNum=0;
        end
        set(hGui.VarName, 'string', [FileID '_' num2str(FileNum+1)]);
    end
    
elseif ~captureRequested
    trigFSCVActive = false;
    set(hGui.StatusText, 'String', 'Not Recording');
    
    %delete buffer
    numSamplesToDiscard = size(fscvBuffer,1) - c.bufferSize;
    if (numSamplesToDiscard > 0)
            fscvBuffer(1:numSamplesToDiscard, :) = [];
    end

end

drawnow;

end