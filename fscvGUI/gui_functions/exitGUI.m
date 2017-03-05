function exitGUI(hObject, ~, hGui)
global dataListener errorListener outputListener s
    if isvalid(s)
        if s.IsRunning
        stop(s);
        end
    end
        delete(outputListener);
        delete(dataListener);
        delete(errorListener);

        delete(s);
        set(hGui.endDAQButton, 'Value', 0);
        close(hGui.Fig)
end