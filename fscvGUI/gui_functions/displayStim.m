function displayStim(hObject, ~, hGui)
global s stimEnable
if get(hObject, 'value')
    fscvparam= getUserParams(hGui); 
    outputData2= createCaptureOutput(s,fscvparam); 
    outputRange=round(fscvparam.stimStart*s.Rate):round(1/fscvparam.stimFreq*fscvparam.stimPulses*s.Rate+fscvparam.stimStart*s.Rate);
    outputDataDisplay=outputData2(outputRange,:);
    %figure; plot(round(outputRange./s.Rate),outputDataDisplay);
    for ii = 1:3
        set(hGui.StimPlot(ii), 'XData', NaN, 'YData', NaN);
    end
    for ii = 1:3
      set(hGui.StimPlot(ii), 'XData', outputRange/s.Rate, 'YData', outputDataDisplay(:, ii))
    end
    hold(hGui.Axes6)
    set(hGui.Axes6,'ylim',[-0.5 1.5])
     set(hGui.Axes6,'xlim',[outputRange(1)/s.Rate outputRange(end)/s.Rate])
     set(hGui.StimButton,'Enable','off') 
    set(hGui.StimButton, 'Value', 0);
    hold(hGui.Axes6)
    stimEnable=1;
    
end
    set(hGui.StimButton,'Enable','on') 
end

