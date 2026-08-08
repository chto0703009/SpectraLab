function [isDue, dueAt] = isCalibrationDue(session, options)
%ISCALIBRATIONDUE Apply the session-owned calibration timer policy.

arguments
    session (1,1) struct
    options.At (1,1) datetime = datetime("now", "TimeZone", "local")
end

spectralab.colorchecker.validate(session);
if isempty(session.Calibrations)
    isDue = true;
    dueAt = NaT;
    return
end

dueAt = datetime(string(session.Calibrations(end).DueAt), ...
    "InputFormat", "yyyy-MM-dd'T'HH:mm:ssXXX", "TimeZone", "local");
isDue = options.At >= dueAt;
end
