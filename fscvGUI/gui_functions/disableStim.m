function disableStim(hObject, ~, hGui)
    global stimEnable
    if get(hObject, 'value')
        stimEnable=0;
        set(hGui.stimDisableButton,'Enable','off')
        set(hGui.stimDisableButton,'Value',0);
       cla((hGui.Axes6));
    end
        set(hGui.stimDisableButton,'Enable','on') 

end

