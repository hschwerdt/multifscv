function s = initializeSession
%initializeSession.m
%configure data acquisition session and add analog input channels
%daq.getDevices
s = daq.createSession('ni');
device='dev1';
numch=16;
ch = addAnalogInputChannel(s, device, [0:7 16:23 15 31], 'Voltage'); %add 16 channels
numch=length(ch);
% AI0 = Vr filtered, AI1-7 = ch 1 - 7 , AI16-23 = ch8-15, AI15=ch16, AI31 = clk

out0 = addAnalogOutputChannel(s, device, [0 3 2], 'Voltage');

s.Channels(numch+1).Range = [-2 2];             %output AO0, fscv triangle wave output to filter RC and filtered input to AI0
s.Channels(numch+2).Range = [-2 2];             %output AO3, pulse clock custom made synchronize triangle tied to AI31 out and data collection
s.Channels(numch+3).Range = [-10 10];           %output AO2, stim TTL, AO2

% Set acquisition configuration for each channel
    ch(1).TerminalConfig = 'SingleEnded';       %RSE, referenced to AI GND for filtered ramp in (AI0)
    ch(1).Range = [-2 2];
    ch(18).TerminalConfig = 'SingleEnded';      %RSE, referenced to AI GND for stim pulse 
    ch(18).Range = [-2 2];
    for ii=2:(numch-1)
       ch(ii).TerminalConfig = 'SingleEndedNonReferenced';     %NRSE, ramp (filtered) connected to AIsense
        %ch(ii).Range = [-2 2];                 %10X LOWER GAIN SETTING
       %ch(ii).TerminalConfig = 'Differential';     %NRSE, ramp (filtered) connected to AIsense
        ch(ii).Range = [-10 10];
    end
    
% Set acquisition rate, in scans/second/channel
s.Rate= 25000;
end