function hGui = fscvGUI
global outputData dataListener errorListener outputListener fscvparam  s scansperupdate stimEnable recordCount
%fscvGUI Create a graphical user interface for multichannel recording
%hGui = fscvGUI returns a structure of graphics

outputData=[];          %data queued to output
dataListener=[];        %when data acquired in buffer above 'data available' setting, acquire data
errorListener=[];       %listens for session-based errors
outputListener=[];      %listens for 'data required', when more data needs to be transferred to queue for output
fscvparam=[];           %fscv parameters, as provided into GUI     
scansperupdate=3;       %how many fscv scans per update/notify listener, not fast enough for 60 HZ recording
stimEnable=0;
recordCount=0;
buttonsize=[60 30]; buttonsize2=[55 25];
figsize=[1250 650];
plotsize=[200 200];
plotsize2=[400 200];
leftmargin=10;

s=initializeSession;        %initialize session s
    

% Create a figure and configure a callback function (executes on window close)
hGui.Fig = figure('Name','multichannel fscv', ...
    'NumberTitle', 'off', 'Resize', 'off', 'Position', [100 100 figsize]);
set(hGui.Fig, 'DeleteFcn', {@endDAQ, s});
set(hGui.Fig, 'Color',[1 1 1]);
uiBackgroundColor = get(hGui.Fig, 'Color');
numch=numel(s.Channels)-2;

%PLOTS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create the continuous data plot axes with legend
% (one line per acquisition channel)
hGui.Axes1 = axes;
hGui.LivePlot = plot(0, zeros(1, numel(s.Channels(1:numch))));  %only ch1-numch
xlabel('time (s)');
ylabel('voltage (V)');
title('continuous data');
%legend(get(s.Channels(1:numch), 'ID'), 'Location', 'northwestoutside')  %only ch1-2
set(hGui.Axes1, 'Units', 'Pixels', 'Position',  [210 391 plotsize]);

% Create the scope data plot axes (one channel)
hGui.Axes3 = axes('Units', 'Pixels', 'Position', [480 391 plotsize]);
hGui.ScopePlot = plot(NaN, NaN(1, numel(s.Channels(1:numch))),'.','MarkerSize',1,'Color',[0 0 0]);    
set(hGui.Axes3, 'LineStyleOrder', '.');
xlabel('time (s)');
%ylabel('voltage (V)');
title('scope 1');
% Scope Plot 2
hGui.Axes4 = axes('Units', 'Pixels', 'Position', [750 391 plotsize]);
hGui.ScopePlot2 = plot(NaN, NaN(1, numel(s.Channels(1:numch))),'.','MarkerSize',1,'Color',[1 0 0]);    
%xlabel('time (s)');
%ylabel('voltage (V)');
title('scope 2');
% Scope Plot 3
hGui.Axes5 = axes('Units', 'Pixels', 'Position', [1020 391 plotsize]);
hGui.ScopePlot3 = plot(NaN, NaN(1, numel(s.Channels(1:numch))),'.','MarkerSize',1,'Color',[0 0 1]);    
%xlabel('time (s)');
%ylabel('voltage (V)');
title('scope 3');

% Create the stim plot
hGui.Axes6 = axes('Units', 'Pixels', 'Position', [480 99 plotsize2]);
hGui.StimPlot = plot(NaN, NaN(1, 3));      
%xlabel('time (s)');
%ylabel('voltage (V)');
title('stimulation');



% Create the captured data plot axes (one line per acquisition channel)
hGui.Axes2 = axes('Units', 'Pixels', 'Position', [1020 99 plotsize]);
hGui.CapturePlot = plot(NaN, NaN(1, numel(s.Channels(1:numch))));    %only ch1-2
xlabel('time (s)');
%ylabel('voltage (V)');
title('captured data');

%TEXT & TEXT FIELDS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create a status text field
hGui.StatusText = uicontrol('style', 'text', 'string', '',...
    'units', 'pixels', 'position', [leftmargin 15 205 24],...
    'HorizontalAlignment', 'left', 'BackgroundColor', uiBackgroundColor);

% Create an editable text field for applied voltage parameters
hGui.VaFreq = uicontrol('style', 'edit', 'string', '10',...     %applied freq hz
    'units', 'pixels', 'position', [85 figsize(2)-100 57 26]);
hGui.VaScanRate = uicontrol('style', 'edit', 'string', '400',...     %applied scan rate v/s
    'units', 'pixels', 'position', [85 figsize(2)-130 57 26]);
hGui.VaLimitsMin = uicontrol('style', 'edit', 'string', '-0.3',...     %applied scan rate v/s
    'units', 'pixels', 'position', [85 figsize(2)-160 30 26]);
hGui.VaLimitsMax = uicontrol('style', 'edit', 'string', '1.4',...     %applied scan rate v/s
    'units', 'pixels', 'position', [120 figsize(2)-160 30 26]);
    % Create text labels for applied voltage parameters
    hGui.txtFSCVParam = uicontrol('Style', 'text', 'String', 'fscv parameters', ...
        'Position', [leftmargin figsize(2)-70 120 18], 'HorizontalAlignment', 'right', ...
        'BackgroundColor', uiBackgroundColor,'fontweight','bold','fontsize',10);
    hGui.txtVaFreq = uicontrol('Style', 'text', 'String', 'freq. (Hz)', ...
        'Position', [leftmargin figsize(2)-100 57 26], 'HorizontalAlignment', 'right', ...
        'BackgroundColor', uiBackgroundColor);
    hGui.txtVaScanRate = uicontrol('Style', 'text', 'String', 'scan rate (V/s)', ...
        'Position', [leftmargin figsize(2)-130 57 26], 'HorizontalAlignment', 'right', ...
        'BackgroundColor', uiBackgroundColor);
    hGui.txtVaLimitsMin = uicontrol('Style', 'text', 'String', 'limits (V)', ...
        'Position', [leftmargin figsize(2)-160 57 26], 'HorizontalAlignment', 'right', ...
        'BackgroundColor', uiBackgroundColor);

% Create an editable text field for display
hGui.dispTime = uicontrol('style', 'edit', 'string', '1',...     %time to display
    'units', 'pixels', 'position', [105 figsize(2)-235 27 26]);
    % Create text labels for display
    hGui.txtdisp = uicontrol('Style', 'text', 'String', 'display range (s)', ...
        'Position', [leftmargin+25 figsize(2)-240 57 36], 'HorizontalAlignment', 'right', ...
        'BackgroundColor', uiBackgroundColor);

% Collection parameters

hGui.RecordTime = uicontrol('style', 'edit', 'string', '60',...
    'units', 'pixels', 'position', [85 figsize(2)-310 56 26]);
hGui.VarName = uicontrol('style', 'edit', 'string', ['id_idHz_idp_iduA_' num2str(recordCount+1)],...
    'units', 'pixels', 'position', [85 figsize(2)-340 300 26]);
    %  text labels for collection
    hGui.txtRecordSet = uicontrol('Style', 'text', 'String', 'record settings', ...
    'Position', [leftmargin figsize(2)-280 120 17], 'HorizontalAlignment', 'right', ...
    'BackgroundColor', uiBackgroundColor,'fontweight','bold','fontsize',10);
    hGui.txtRecordTime = uicontrol('Style', 'text', 'String', 'record time (s)', ...
        'Position', [leftmargin figsize(2)-310 57 26], 'HorizontalAlignment', 'right', ...
        'BackgroundColor', uiBackgroundColor);
    hGui.txtVarName = uicontrol('Style', 'text', 'String', 'variable name', ...
        'Position', [leftmargin figsize(2)-340 57 26], 'HorizontalAlignment', 'right', ...
        'BackgroundColor', uiBackgroundColor);

%Scope channels to plot
hGui.ScopeChannel = uicontrol('style', 'edit', 'string', '1',...
    'units', 'pixels', 'position', [85 figsize(2)-410 56 24]);
hGui.ScopeChannel2 = uicontrol('style', 'edit', 'string', '2',...
    'units', 'pixels', 'position', [85 figsize(2)-440 56 24]);
hGui.ScopeChannel3 = uicontrol('style', 'edit', 'string', '3',...
    'units', 'pixels', 'position', [85 figsize(2)-470 56 24]);
    %text
    hGui.txtPlotChannels = uicontrol('Style', 'text', 'String', 'scope plot channels', ...
        'Position', [leftmargin figsize(2)-380 114 18], 'BackgroundColor', uiBackgroundColor,'fontweight','bold','fontsize',10);
    hGui.txtScopeChannel1 = uicontrol('Style', 'text', 'String', 'scope 1', ...
        'Position', [leftmargin figsize(2)-410 66 17], 'HorizontalAlignment', 'right', ...
        'BackgroundColor', uiBackgroundColor);
    hGui.txtScopeChannel2 = uicontrol('Style', 'text', 'String', 'scope 2', ...
        'Position', [leftmargin figsize(2)-440 66 17], 'HorizontalAlignment', 'right', ...
        'BackgroundColor', uiBackgroundColor);
    hGui.txtScopeChannel3 = uicontrol('Style', 'text', 'String', 'scope 3', ...
        'Position', [leftmargin figsize(2)-470 66 17], 'HorizontalAlignment', 'right', ...
        'BackgroundColor', uiBackgroundColor);

%FSCV scan trigger %CLOCK Trigger from Ch 18 for timing storage
% Create an editable text field for the trigger channel
hGui.FSCVTrigChannel = uicontrol('style', 'edit', 'string', '18',...
    'units', 'pixels', 'position', [85 figsize(2)-540 56 24]);
% Create an editable text field for the trigger signal level
hGui.FSCVTrigLevel = uicontrol('style', 'edit', 'string', '1',...
    'units', 'pixels', 'position', [85 figsize(2)-570 56 24]);
% Create an editable text field for the trigger signal slope
hGui.FSCVTrigSlope = uicontrol('style', 'edit', 'string', '100.0',...
    'units', 'pixels', 'position', [85 figsize(2)-600 56 24]);
    % text labels
    hGui.txtFSCVTrigParam = uicontrol('Style', 'text', 'String', 'fscv scan trigger', ...
        'Position', [leftmargin figsize(2)-510 114 18], 'BackgroundColor', uiBackgroundColor,'fontweight','bold','fontsize',10);
    hGui.txtFSCVTrigChannel = uicontrol('Style', 'text', 'String', 'channel', ...
        'Position', [leftmargin figsize(2)-540 66 17], 'HorizontalAlignment', 'right', ...
        'BackgroundColor', uiBackgroundColor);
    hGui.txtTrigLevel = uicontrol('Style', 'text', 'String', 'level (V)', ...
       'Position', [leftmargin figsize(2)-570 66 19], 'HorizontalAlignment', 'right', ...
       'BackgroundColor', uiBackgroundColor);
    hGui.txtFSCVTrigSlope = uicontrol('Style', 'text', 'String', 'slope (V/s)', ...
        'Position', [leftmargin figsize(2)-600 66 17], 'HorizontalAlignment', 'right', ...
        'BackgroundColor', uiBackgroundColor);

%Stimulation parameters
% Create an editable text field for the trigger channel
hGui.StimulationFreq = uicontrol('style', 'edit', 'string', '60',...
    'units', 'pixels', 'position', [leftmargin+200+85 figsize(2)-410 56 24]);
hGui.StimulationPulses = uicontrol('style', 'edit', 'string', '24',...
    'units', 'pixels', 'position', [leftmargin+200+85 figsize(2)-440 56 24]);
hGui.StimulationStart = uicontrol('style', 'edit', 'string', '5',...
    'units', 'pixels', 'position', [leftmargin+200+85 figsize(2)-470 56 24]);
hGui.StimulationVolts = uicontrol('style', 'edit', 'string', '5',...
    'units', 'pixels', 'position', [leftmargin+200+85 figsize(2)-500 56 24]);
hGui.StimulationDelay = uicontrol('style', 'edit', 'string', '0.1',...
    'units', 'pixels', 'position', [leftmargin+200+85 figsize(2)-530 56 24]);
hGui.StimulationWidth = uicontrol('style', 'edit', 'string', '1',...
    'units', 'pixels', 'position', [leftmargin+200+85 figsize(2)-560 56 24]);
    % text labels
    hGui.txtStimParam = uicontrol('Style', 'text', 'String', 'stimulation parameters', ...
        'Position', [leftmargin+200 figsize(2)-380 154 20], 'BackgroundColor', uiBackgroundColor,'fontweight','bold','fontsize',10);
    hGui.txtStimulationFreq = uicontrol('Style', 'text', 'String', 'frequency (Hz)', ...
        'Position', [leftmargin+200 figsize(2)-410 80 17], 'HorizontalAlignment', 'right', ...
        'BackgroundColor', uiBackgroundColor);
    hGui.txtStimulationPulses = uicontrol('Style', 'text', 'String', 'number pulses', ...
        'Position', [leftmargin+200 figsize(2)-440 66 17], 'HorizontalAlignment', 'right', ...
        'BackgroundColor', uiBackgroundColor);
    hGui.txtStimulationStart = uicontrol('Style', 'text', 'String', 'onset (s)', ...
        'Position', [leftmargin+200 figsize(2)-470 66 17], 'HorizontalAlignment', 'right', ...
        'BackgroundColor', uiBackgroundColor);
    hGui.txtStimulationVolts = uicontrol('Style', 'text', 'String', 'volts', ...
        'Position', [leftmargin+200 figsize(2)-500 66 17], 'HorizontalAlignment', 'right', ...
        'BackgroundColor', uiBackgroundColor);
    hGui.txtStimulationDelay = uicontrol('Style', 'text', 'String', 'delay (ms)', ...
        'Position', [leftmargin+200 figsize(2)-530 66 17], 'HorizontalAlignment', 'right', ...
        'BackgroundColor', uiBackgroundColor);
    hGui.txtStimulationWidth = uicontrol('Style', 'text', 'String', 'pulse width (ms)', ...
        'Position', [leftmargin+200 figsize(2)-560 85 17], 'HorizontalAlignment', 'right', ...
        'BackgroundColor', uiBackgroundColor);
    hGui.txtStimType = uicontrol('Style', 'text', 'String', 'trigger', ...
        'Position', [leftmargin+200 figsize(2)-590 66 17], 'HorizontalAlignment', 'right', ...
        'BackgroundColor', uiBackgroundColor);

hGui.stimType=uicontrol('Style','popupmenu','String',{'mono';'bi'},'BackgroundColor','white','Position',[leftmargin+200+85 figsize(2)-590 56 24]);


fscvparam.freq = sscanf(get(hGui.VaFreq, 'string'), '%f');      %add
fscvparam.scanRate = sscanf(get(hGui.VaScanRate, 'string'), '%f');      %add
fscvparam.vaMin = sscanf(get(hGui.VaLimitsMin, 'string'), '%f');      %add
fscvparam.vaMax = sscanf(get(hGui.VaLimitsMax, 'string'), '%f');      %add
fscvparam.timeToScan = abs(fscvparam.vaMax-fscvparam.vaMin)./fscvparam.scanRate.*2;
fscvparam.timeToRecord = sscanf(get(hGui.RecordTime, 'string'), '%f');      %add
fscvparam.timeToPlot = sscanf(get(hGui.dispTime, 'string'), '%f');      %add

fscvparam.stimFreq = sscanf(get(hGui.StimulationFreq, 'string'), '%f');      %add
fscvparam.stimPulses = sscanf(get(hGui.StimulationPulses, 'string'), '%f');      %add
fscvparam.stimWidth = sscanf(get(hGui.StimulationWidth, 'string'), '%f');      %add
fscvparam.stimVolts = sscanf(get(hGui.StimulationVolts, 'string'), '%f');      %add
fscvparam.stimDelay= sscanf(get(hGui.StimulationDelay, 'string'), '%f');      %add
fscvparam.stimStart= sscanf(get(hGui.StimulationStart, 'string'), '%f');      %add

%Buttons%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create a capture  button and configure a callback function
hGui.CaptureButton = uicontrol('style', 'togglebutton', 'string', 'capture',...
    'units', 'pixels', 'position', [leftmargin+65 figsize(2)-30 buttonsize]);
set(hGui.CaptureButton, 'callback', {@startCapture, hGui});

% Create a start acquisition button and configure a callback function
hGui.RunButton = uicontrol('style', 'togglebutton', 'string', 'run',...
    'units', 'pixels', 'position', [leftmargin figsize(2)-30 buttonsize]);
set(hGui.RunButton, 'callback', {@startRun, hGui});

% Create a stop acquisition button and configure a callback function
hGui.endDAQButton = uicontrol('style', 'pushbutton', 'string', 'stop daq',...
    'units', 'pixels', 'position', [leftmargin+65*2 figsize(2)-30 buttonsize]);
set(hGui.endDAQButton,'fontsize',8)
set(hGui.endDAQButton, 'callback', {@endDAQ, hGui});% Create a data capture button and configure a callback function

% Create a generate FSCV waveform button and configure a callback function
hGui.exitGUI = uicontrol('style', 'pushbutton', 'string', 'exit',...
    'units', 'pixels', 'position', [leftmargin+65*3 figsize(2)-30 buttonsize]);
set(hGui.exitGUI,'fontsize',8)
set(hGui.exitGUI, 'callback', {@exitGUI, hGui});% Create a data capture button and configure a callback function

% Stim display button
hGui.StimButton=uicontrol('style','togglebutton','string','enable',...
    'units','pixels','position',[leftmargin+230 figsize(2)-625 buttonsize2]);
set(hGui.StimButton,'fontsize',8)
set(hGui.StimButton, 'callback', {@displayStim, hGui});   % Create a stim button and configure a callback function
% Stim disable button
hGui.stimDisableButton=uicontrol('style','togglebutton','string','disable',...
    'units','pixels','position',[leftmargin+290 figsize(2)-625 buttonsize2]);
set(hGui.stimDisableButton,'fontsize',8)
set(hGui.stimDisableButton, 'callback', {@disableStim, hGui});   % Create a stim button and configure a callback function

end

