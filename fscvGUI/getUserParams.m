function fscvparam= getUserParams(hGui)


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

items = get(hGui.stimType,'String');
index_selected = get(hGui.stimType,'Value');
item_selected = items{index_selected};
fscvparam.stimType=index_selected;

end