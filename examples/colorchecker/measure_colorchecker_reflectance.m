% measure_colorchecker_reflectance
%
% Measure a rectangular reflective colour chart one patch at a time.
% Every patch becomes an immutable standard SpectraLab archive. The
% ColorChecker session JSON records grid geometry, calibration events and
% references to those archives. No PNG or PDF is generated during capture.

action = questdlg( ...
    "Create a new ColorChecker session or resume an existing one?", ...
    "SpectraLab - ColorChecker reflectance", ...
    "New session", "Resume session", "Cancel", "New session");
if isempty(action) || action == "Cancel"
    disp("ColorChecker measurement cancelled. Nothing was measured.");
    return
end

if action == "New session"
    isResume = false;
    session = createNewSession();
    if isempty(session), return, end
else
    isResume = true;
    [file, folder] = uigetfile("colorchecker_session.json", ...
        "SpectraLab - Select ColorChecker session");
    if isequal(file, 0)
        disp("ColorChecker measurement cancelled. Nothing was measured.");
        return
    end
    session = spectralab.colorchecker.load(fullfile(folder, file));
end

if isResume
    [settings, session] = acquisitionSettingsForResume(session);
    resolutionChoice = string(settings.Resolution);
    instrumentId = string(settings.InstrumentId);
    expectedSerial = string(settings.SerialNumber);
    message = "This ColorChecker session is locked to:" + newline + newline + ...
        "Instrument: " + instrumentId + newline + ...
        "Serial number: " + displayValue(expectedSerial) + newline + ...
        "Resolution: " + resolutionChoice + newline + newline + ...
        "Continue only with this instrument and resolution.";
    choice = questdlg(message, ...
        "SpectraLab - Resume ColorChecker session", ...
        "Continue with these settings", "Cancel", ...
        "Continue with these settings");
    if isempty(choice) || choice == "Cancel"
        disp("ColorChecker resume cancelled. Nothing was measured.");
        return
    end
else
    instrumentId = select_spotread_instrument();
    if instrumentId == ""
        disp("ColorChecker measurement cancelled. Nothing was measured.");
        return
    end
    resolutionChoice = string(questdlg( ...
        "Select spectral resolution for this ColorChecker session.", ...
        "SpectraLab - ColorChecker reflectance resolution", ...
        "Standard", "High resolution", "Cancel", "Standard"));
    if resolutionChoice == "" || resolutionChoice == "Cancel"
        disp("ColorChecker measurement cancelled. Nothing was measured.");
        return
    end
    expectedSerial = "";
    session.AcquisitionSettings = makeAcquisitionSettings( ...
        instrumentId, resolutionChoice, expectedSerial);
    session = spectralab.colorchecker.save(session);
end

inst = spectralab.drivers.createInstrument( ...
    instrumentId, ...
    MeasurementKind="reflectance", ...
    HighResolution=strcmp(resolutionChoice, "High resolution"), ...
    PlacementConfirmation=@(~) []);
instrumentCleanup = onCleanup(@() inst.close());

workflow = spectralab.core.Session(inst, ...
    Operator=string(session.Context.Operator), ...
    Project=string(session.Context.Project), ...
    AudibleFeedback=true);
workflow = workflow.open();

% A new driver process always starts with a fresh physical calibration.
% Record it in the persistent ColorChecker session before accepting patches.
confirmWhiteReferenceCalibration("initial calibration");
workflow = workflow.calibrate("Mode", "automatic");
calibrationSerial = verify_spotread_instrument( ...
    inst, expectedSerial, "ColorChecker reflectance calibration");
if strlength(expectedSerial) == 0
    session.AcquisitionSettings.SerialNumber = calibrationSerial;
end
session = spectralab.colorchecker.recordCalibration(session, inst.getInfo(), ...
    Method="spotread reflective white-reference calibration");
session = spectralab.colorchecker.save(session);

while true
    patch = spectralab.colorchecker.nextPatch(session);
    if isempty(fieldnames(patch))
        uiwait(msgbox( ...
            "All patches in this ColorChecker session are measured.", ...
            "SpectraLab - ColorChecker complete", "modal"));
        break
    end

    [calibrationDue, dueAt] = spectralab.colorchecker.isCalibrationDue(session);
    if calibrationDue
        message = "Calibration is due before patch " + patch.Coordinate + ".";
        if ~isnat(dueAt)
            message = message + newline + "Due at: " + string(dueAt);
        end
        uiwait(msgbox(message, "SpectraLab - Calibration required", "warn", "modal"));
        confirmWhiteReferenceCalibration("recalibration");
        workflow = workflow.calibrate("Mode", "automatic");
        calibrationSerial = verify_spotread_instrument( ...
            inst, calibrationSerial, "ColorChecker recalibration");
        session = spectralab.colorchecker.recordCalibration(session, inst.getInfo(), ...
            Method="spotread reflective white-reference recalibration");
        session = spectralab.colorchecker.save(session);
    end

    instruction = "Expected patch: " + patch.Coordinate + newline + newline + ...
        "Place the i1Pro on this patch and confirm to measure." + newline + ...
        "No PDF or PNG will be created during this session.";
    choice = questdlg(instruction, ...
        "SpectraLab - Measure ColorChecker " + patch.Coordinate, ...
        "Measure " + patch.Coordinate, "Stop and keep session", "Cancel", ...
        "Measure " + patch.Coordinate);
    if isempty(choice) || choice == "Cancel"
        disp("ColorChecker measurement cancelled. Completed patches are preserved.");
        break
    end
    if choice == "Stop and keep session"
        disp("ColorChecker session paused. Completed patches are preserved.");
        break
    end

    label = "ColorChecker_" + patch.Coordinate;
    measurement = workflow.measure(label, "Mode", "automatic");
    verify_spotread_instrument( ...
        inst, calibrationSerial, "ColorChecker patch " + patch.Coordinate);
    measurement = spectralab.colorchecker.reflectanceOnlySpectrum( ...
        measurement, Coordinate=patch.Coordinate, ...
        SessionUUID=string(session.Identity.UUID), ...
        ChartName=targetName(session), ...
        ChartManufacturedDate=string( ...
            session.Definition.ChartManufacturedDate));

    archiveName = safeName(session.Definition.Name) + "_" + patch.Coordinate + "_" + ...
        string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
    archiveFile = fullfile(session.Context.SessionFolder, ...
        session.Context.ArchiveFolder, archiveName + ".mat");
    archive = spectralab.archive.create(measurement);
    spectralab.archive.save(archive, archiveFile);

    session = spectralab.colorchecker.recordMeasurement( ...
        session, patch.Coordinate, archiveFile);
    session = spectralab.colorchecker.save(session);
    fprintf("ColorChecker patch %s saved:\n  %s\n", ...
        patch.Coordinate, archiveFile);
end

workflow = workflow.close();
clear instrumentCleanup

function session = createNewSession()
session = [];
scriptFolder = string(fileparts(mfilename("fullpath")));
workRoot = string(fileparts(scriptFolder));
root = uigetdir(workRoot, ...
    "SpectraLab - Select Work folder for new ColorChecker session");
if isequal(root, 0)
    disp("ColorChecker measurement cancelled. Nothing was measured.");
    return
end

answers = inputdlg( ...
    {"Session name", "Calibration interval (minutes)", ...
     "Operator", "Project", "Chart ID", ...
     "Chart serial number", "Chart manufactured date (YYYY-MM or YYYY-MM-DD)"}, ...
    "SpectraLab - X-Rite ColorChecker Digital SG session", ...
    [1 60; 1 20; 1 60; 1 60; 1 60; 1 60; 1 30], ...
    {"ColorChecker", "30", "", ...
     "ColorChecker reflectance", "", "", ""});
if isempty(answers), return, end

interval = str2double(answers{2});
if ~isfinite(interval) || interval <= 0
    error("SpectraLab:Work:InvalidColorCheckerCalibrationInterval", ...
        "Calibration interval must be positive.");
end

name = strtrim(string(answers{1}));
if strlength(name) == 0 || ~isempty(regexp(char(name), '[\\/:]', 'once'))
    error("SpectraLab:Work:InvalidColorCheckerName", ...
        "Session name must be non-empty and contain no path separators.");
end
folderName = safeName(name) + "_" + ...
    string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
sessionFolder = fullfile(root, folderName);
session = spectralab.colorchecker.create(sessionFolder, ...
    Name=name, ...
    TargetDefinitionID="xrite-colorchecker-digital-sg-140", ...
    CalibrationIntervalMinutes=interval, ...
    Operator=string(answers{3}), Project=string(answers{4}), ...
    ChartID=string(answers{5}), ...
    ChartSerialNumber=string(answers{6}), ...
    ChartManufacturedDate=string(answers{7}));
fprintf("ColorChecker session created:\n  %s\n", sessionFolder);
fprintf("Target definition:\n  %s\n", ...
    session.Definition.TargetDefinition.Name);
end

function value = targetName(session)
if isfield(session.Definition, "TargetDefinition")
    value = string(session.Definition.TargetDefinition.Name);
else
    value = string(session.Definition.Name);
end
end

function output = safeName(value)
output = regexprep(strtrim(string(value)), "[^A-Za-z0-9_-]+", "_");
output = regexprep(output, "_+", "_");
output = strip(output, "_");
if strlength(output) == 0, output = "ColorChecker"; end
end

function confirmWhiteReferenceCalibration(kind)
message = "This is " + string(kind) + "." + newline + newline + ...
    "Place the i1Pro/i1Pro2 on its supplied WHITE calibration reference " + ...
    "tile — not on the ColorChecker." + newline + newline + ...
    "A ColorChecker patch such as A1 is measured only after this calibration is complete.";
uiwait(msgbox(message, ...
    "SpectraLab - White reference calibration", "warn", "modal"));
end

function [settings, session] = acquisitionSettingsForResume(session)
if isfield(session, "AcquisitionSettings")
    settings = session.AcquisitionSettings;
    return
end
if isempty(session.Calibrations)
    error("SpectraLab:Work:MissingColorCheckerAcquisitionSettings", ...
        "The session has no locked instrument and resolution settings.");
end
instrument = session.Calibrations(end).Instrument;
instrumentId = readInstrumentText(instrument, ["instrument_id", "name"]);
serialNumber = readInstrumentText(instrument, ...
    ["serial_number", "SerialNumber"]);
if isfield(instrument, "high_resolution")
    highResolution = logical(instrument.high_resolution);
else
    error("SpectraLab:Work:MissingColorCheckerResolution", ...
        "The session does not record its spectral resolution.");
end
if highResolution, resolution = "High resolution"; else, resolution = "Standard"; end
settings = makeAcquisitionSettings(instrumentId, resolution, serialNumber);
session.AcquisitionSettings = settings;
session = spectralab.colorchecker.save(session);
end

function settings = makeAcquisitionSettings(instrumentId, resolution, serialNumber)
settings = struct( ...
    "InstrumentId", string(instrumentId), ...
    "SerialNumber", string(serialNumber), ...
    "Resolution", string(resolution), ...
    "HighResolution", string(resolution) == "High resolution", ...
    "MeasurementKind", "reflectance", ...
    "LockedAt", char(datetime("now", "TimeZone", "local"), ...
        "yyyy-MM-dd'T'HH:mm:ssXXX"));
end

function value = readInstrumentText(instrument, candidates)
value = "";
names = string(fieldnames(instrument));
for candidate = candidates
    index = find(strcmpi(names, candidate), 1);
    if ~isempty(index)
        value = strtrim(string(instrument.(char(names(index)))));
        if value ~= "", return, end
    end
end
end

function value = displayValue(value)
if strlength(value) == 0, value = "not recorded"; end
end
