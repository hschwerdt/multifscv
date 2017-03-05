function outputData = createOutput(s,fscvparam)
%Based on fscvparam and session s parameters, create analog output signals:
%fscv ramp, stim output, and custom clock
freq=fscvparam.freq;         %Hz
timeToScan=fscvparam.timeToScan;
vaMax=fscvparam.vaMax;
scanRate=fscvparam.scanRate;
vaMin=fscvparam.vaMin;
timeToRecord=fscvparam.timeToRecord;
timeToPlot=fscvparam.timeToPlot;

stimFreq=fscvparam.stimFreq;
stimPulses=fscvparam.stimPulses;
stimWidth=fscvparam.stimWidth;
stimVolts=fscvparam.stimVolts;
stimDelay=fscvparam.stimDelay;
stimStart=fscvparam.stimStart;

output_length = max(round(s.Rate*timeToRecord), 15*s.Rate); 

%fscv triangle ramp waveform
V_amp=1;
ramp_factor=1;
sampleframe=linspace(1,(1/freq)*s.Rate,(1/freq)*s.Rate);
anodal_scan=scanRate./(s.Rate).*sampleframe(1:round(timeToScan*s.Rate/2))+vaMin;
cathodal_scan=-scanRate./(s.Rate).*sampleframe(round(timeToScan*s.Rate/2):round(timeToScan*s.Rate))+(vaMax-vaMin)+anodal_scan(end);
ac_scan=[anodal_scan cathodal_scan];
hold_scan=[];
hold_scan(1:(length(sampleframe)-length(ac_scan)))=vaMin;
fscv_scan=[ac_scan hold_scan]';
output_fscv=fscv_scan.*ramp_factor;
output_fscv=repmat(output_fscv,round(output_length/length(output_fscv))+5,1);
output_fscv=output_fscv(1:output_length);

%custom clock synched with FSCV scan
uppulsecycle=length(ac_scan);      %in samples
downpulsecycle=length(hold_scan);       %in samples
pulsePeak=1.5;
pulse=repmat(pulsePeak,uppulsecycle,1);
pulse2=repmat(0,downpulsecycle,1);
pulseout=[pulse; pulse2];
pulseout=pulseout(1:length(fscv_scan));
output_pulse=repmat(pulseout,round(output_length/length(pulseout))+5,1);
output_pulse=output_pulse(1:output_length);

%stimulation TTL parameters
%stimOnset=round(fscvcapture.ScanSpan*s.Rate);
stimStartID=round(stimStart*s.Rate);
endfirstFSCVindex=length(ac_scan);
stimOnID=endfirstFSCVindex+round(stimDelay*1e-3*s.Rate)+stimStartID;            %num samples to hold before starting stim relative to end of nearby FSCV scan based on user input
stimDelayInterval=zeros(stimOnID,1);
stimPulse=repmat(stimVolts,round(stimWidth*1e-3*s.Rate),1);
stimInterval=round(1/stimFreq*s.Rate)-length(stimPulse);
stimInterval=zeros(stimInterval,1);
%stimInterval=zeros(stimInterval-stimOnset-length(stimPulse),1);
stimOut=[stimPulse; stimInterval];
stimOut=repmat(stimOut,stimPulses,1);
stimOut=[stimDelayInterval; stimOut];
stimRest=zeros(length(output_pulse)-length(stimOut),1);
output_stim=[stimOut; stimRest];
output_stim=zeros(length(output_pulse),1);      %no stim output during "run" only during "capture"

outputData=repmat([output_fscv, output_pulse, output_stim], 1,1);
end

