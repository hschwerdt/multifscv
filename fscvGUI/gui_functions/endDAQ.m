function endDAQ(hObject, ~, hGui)
%stop button pressed, stop session and delete listeners
global dataListener errorListener outputListener s
    if isvalid(s)
        if s.IsRunning
        stop(s);
        end
    end
        delete(outputListener);
        delete(dataListener);
        delete(errorListener);
%        set(hObject, 'Value', 0);
end

