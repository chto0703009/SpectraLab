function instrumentId = select_spotread_instrument()
%SELECT_SPOTREAD_INSTRUMENT Detect and confirm the physical Spotread model.

instrumentId = "";
detection = detectInstrument();

if detection.Found
    prompt = sprintf([ ...
        'Spotread identified this USB instrument:\n\n%s\n\n' ...
        'Confirm the physical model for archive provenance. The serial ' ...
        'number will be locked after calibration and verified again ' ...
        'after measurement.'], ...
        detection.Description);
else
    prompt = sprintf([ ...
        'Spotread could not identify a supported USB instrument before ' ...
        'measurement.\n\nSelect the physical model manually.']);
end

choice = questdlg( ...
    prompt, ...
    "SpectraLab - Identified instrument", ...
    "i1Pro2", ...
    "i1Pro", ...
    "Cancel", ...
    char(detection.SuggestedId));

if isempty(choice) || strcmp(choice, "Cancel")
    return
end

instrumentId = string(choice);
end

function detection = detectInstrument()
detection = struct( ...
    "Found", false, ...
    "Description", "not identified", ...
    "SuggestedId", "i1Pro2");

[pathStatus, pathOutput] = system("command -v spotread");
if pathStatus ~= 0
    return
end

executable = strtrim(string(pathOutput));
if strlength(executable) == 0
    return
end

quotedExecutable = strrep(char(executable), '"', '\"');
command = sprintf('"%s" "-?" 2>&1', quotedExecutable);
[~, helpOutput] = system(command);
devices = regexp( ...
    helpOutput, ...
    '(?m)^\s*\d+\s*=\s*''([^'']+)''\s*$', ...
    'tokens');

for deviceIndex = 1:numel(devices)
    description = strtrim(string(devices{deviceIndex}{1}));
    normalized = lower(description);
    if ~contains(normalized, "usb")
        continue
    end

    detection.Found = true;
    detection.Description = description;
    if contains(normalized, "i1 pro 2") || ...
            contains(normalized, "i1pro 2") || ...
            contains(normalized, "i1pro2")
        detection.SuggestedId = "i1Pro2";
    elseif contains(normalized, "i1 pro") || contains(normalized, "i1pro")
        detection.SuggestedId = "i1Pro";
    end
    return
end
end
