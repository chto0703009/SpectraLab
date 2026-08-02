classdef EventRecorder < handle
    %EVENTRECORDER Record ordered callback events in workflow tests.

    properties
        Events (:,1) string = strings(0,1)
    end

    methods
        function record(obj, eventName)
            obj.Events(end + 1,1) = string(eventName);
        end
    end
end
