function session = recordCalibration(session, instrumentInfo, options)
%RECORDCALIBRATION Add a completed calibration event to a session.

arguments
    session (1,1) struct
    instrumentInfo (1,1) struct
    options.Method (1,1) string = "instrument calibration"
    options.Message (1,1) string = ""
    options.Timestamp (1,1) datetime = datetime("now", "TimeZone", "local")
end

spectralab.colorchecker.validate(session);
timestamp = options.Timestamp;
if isempty(timestamp.TimeZone), timestamp.TimeZone = "local"; end
dueAt = timestamp + minutes(session.CalibrationPolicy.IntervalMinutes);
sequence = numel(session.Calibrations) + 1;
entry = struct( ...
    "Sequence", sequence, ...
    "Timestamp", char(timestamp, "yyyy-MM-dd'T'HH:mm:ssXXX"), ...
    "DueAt", char(dueAt, "yyyy-MM-dd'T'HH:mm:ssXXX"), ...
    "Method", strtrim(options.Method), ...
    "Instrument", instrumentInfo, ...
    "Message", strtrim(options.Message));
session.Calibrations(end+1,1) = entry;
session.History(end+1,1) = string(datetime("now", ...
    "TimeZone", "local", "Format", "yyyy-MM-dd HH:mm:ss")) + ...
    "  Calibration " + string(sequence) + " recorded.";
end
