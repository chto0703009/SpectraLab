% remeasure_colorchecker_patches
%
% Perform a controlled patch-level correction of a completed ColorChecker
% session. Original JSON and MAT archives remain unchanged. Each selected
% patch becomes a new immutable archive, a separate amendment JSON records
% the change, and completion creates a new corrected session JSON.

action = questdlg( ...
    "Start a new controlled correction or resume an unfinished one?", ...
    "SpectraLab - ColorChecker remeasurement", ...
    "New correction", "Resume correction", "Cancel", "New correction");
if isempty(action) || action == "Cancel"
    disp("ColorChecker remeasurement cancelled. Nothing was changed.");
    return
end

if action == "New correction"
    [file, folder] = uigetfile( ...
        {"*.json", "ColorChecker session JSON (*.json)"}, ...
        "SpectraLab - Select original or latest amended session JSON");
    if isequal(file, 0), return, end
    sourceFile = string(fullfile(folder, file));
    source = spectralab.colorchecker.load(sourceFile);
    isOriginal = string(file) == "colorchecker_session.json";
    isAmended = startsWith(string(file), ...
        "colorchecker_session_amended_") && isfield(source, "Derivation");
    if ~isOriginal && ~isAmended
        error("SpectraLab:Examples:ColorCheckerCorrectionSourceRequired", ...
            ["Select colorchecker_session.json for the first correction " ...
             "or the latest colorchecker_session_amended_NNN.json " ...
             "for a subsequent correction."]);
    end
    defaults = {"N1 K6", "Suspected patch placement or acquisition error", ...
        char(string(source.Context.Operator))};
    answers = inputdlg( ...
        {"Patch IDs (space or comma separated)", "Reason", "Operator"}, ...
        "SpectraLab - Controlled ColorChecker correction", ...
        [1 60; 3 60; 1 60], defaults);
    if isempty(answers), return, end
    coordinates = splitPatchList(string(answers{1}));
    reason = strip(strjoin(string(answers{2}), newline));
    operator = strip(strjoin(string(answers{3}), " "));
    [amendment, amendmentFile] = ...
        spectralab.colorchecker.beginRemeasurement( ...
        sourceFile, coordinates, Reason=reason, Operator=operator);
else
    [file, folder] = uigetfile( ...
        {"colorchecker_session_amendment_*.json", ...
         "ColorChecker amendment JSON"}, ...
        "SpectraLab - Select unfinished ColorChecker amendment");
    if isequal(file, 0), return, end
    amendmentFile = string(fullfile(folder, file));
    amendment = spectralab.colorchecker.loadRemeasurement(amendmentFile);
    if string(amendment.Identity.State) ~= "in_progress"
        error("SpectraLab:Examples:ColorCheckerAmendmentComplete", ...
            "The selected amendment is already complete.");
    end
    sourceFile = string(amendment.Source.SessionFile);
    if ~isfile(sourceFile), sourceFile = fullfile(folder, sourceFile); end
    source = spectralab.colorchecker.load(sourceFile);
end

settings = amendment.AcquisitionSettings;
requiredSettings = ["InstrumentId", "SerialNumber", "Resolution", "HighResolution"];
if any(~isfield(settings, requiredSettings))
    error("SpectraLab:Examples:MissingRemeasurementAcquisitionSettings", ...
        "The original session does not contain locked instrument and resolution settings.");
end
instrumentId = string(settings.InstrumentId);
expectedSerial = string(settings.SerialNumber);
resolution = string(settings.Resolution);
message = "This correction is locked to:" + newline + newline + ...
    "Instrument: " + instrumentId + newline + ...
    "Serial number: " + displayValue(expectedSerial) + newline + ...
    "Resolution: " + resolution + newline + newline + ...
    "Original archives will not be changed.";
choice = questdlg(message, "SpectraLab - Confirm correction settings", ...
    "Continue", "Cancel", "Continue");
if isempty(choice) || choice == "Cancel", return, end

pending = amendment.Entries(string({amendment.Entries.State}) == "pending");
if isempty(pending)
    [~, correctedFile] = ...
        spectralab.colorchecker.finalizeRemeasurement(amendmentFile);
    fprintf("Corrected ColorChecker session created:\n  %s\n", correctedFile);
    return
end

inst = spectralab.drivers.createInstrument( ...
    instrumentId, MeasurementKind="reflectance", ...
    HighResolution=logical(settings.HighResolution), ...
    PlacementConfirmation=@(~) []);
instrumentCleanup = onCleanup(@() inst.close());
workflow = spectralab.core.Session(inst, ...
    Operator=string(amendment.Definition.Operator), ...
    Project=string(source.Context.Project), AudibleFeedback=true);
workflow = workflow.open();

uiwait(msgbox( ...
    "Place the instrument on its supplied WHITE calibration reference.", ...
    "SpectraLab - Remeasurement calibration", "warn", "modal"));
workflow = workflow.calibrate("Mode", "automatic");
calibrationSerial = verify_spotread_instrument( ...
    inst, expectedSerial, "ColorChecker controlled remeasurement");

completed = true;
for entry = reshape(pending, 1, [])
    coordinate = string(entry.Coordinate);
    instruction = "Patch to remeasure: " + coordinate + newline + newline + ...
        "Place the instrument on this exact patch." + newline + ...
        "The original measurement remains preserved.";
    choice = questdlg(instruction, ...
        "SpectraLab - Remeasure " + coordinate, ...
        "Measure " + coordinate, "Stop and keep amendment", "Cancel", ...
        "Measure " + coordinate);
    if isempty(choice) || choice == "Cancel" || ...
            choice == "Stop and keep amendment"
        completed = false;
        break
    end

    label = "ColorChecker_" + coordinate + "_remeasurement";
    measurement = workflow.measure(label, "Mode", "automatic");
    verify_spotread_instrument(inst, calibrationSerial, ...
        "ColorChecker remeasurement " + coordinate);
    measurement = spectralab.colorchecker.reflectanceOnlySpectrum( ...
        measurement, Coordinate=coordinate, ...
        SessionUUID=string(source.Identity.UUID), ...
        ChartName=string(source.Definition.Name), ...
        ChartManufacturedDate=string(source.Definition.ChartManufacturedDate));

    archiveName = safeName(source.Definition.Name) + "_" + coordinate + ...
        "_remeasurement_" + sprintf("%03d", amendment.Identity.Sequence) + ...
        "_" + string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
    archiveFile = fullfile(string(source.Context.SessionFolder), ...
        string(source.Context.ArchiveFolder), archiveName + ".mat");
    archive = spectralab.archive.create(measurement);
    spectralab.archive.save(archive, archiveFile);
    amendment = spectralab.colorchecker.recordRemeasurement( ...
        amendmentFile, coordinate, archiveFile, ...
        Reason=string(amendment.Definition.Reason), ...
        InstrumentInfo=inst.getInfo(), Resolution=resolution);
    fprintf("Replacement patch %s saved:\n  %s\n", coordinate, archiveFile);
end

workflow = workflow.close();
clear instrumentCleanup

if completed
    [~, correctedFile] = ...
        spectralab.colorchecker.finalizeRemeasurement(amendmentFile);
    fprintf("Controlled ColorChecker correction complete:\n");
    fprintf("  Original session unchanged: %s\n", sourceFile);
    fprintf("  Amendment:                 %s\n", amendmentFile);
    fprintf("  Corrected session:         %s\n", correctedFile);
    fprintf("Run calculate_colorchecker_colorimetry and select the corrected session.\n");
else
    fprintf("ColorChecker correction paused. Recorded replacements are preserved:\n  %s\n", amendmentFile);
end

function coordinates = splitPatchList(value)
coordinates = upper(string(regexp(char(value), '[A-Za-z]+\d+', 'match'))).';
coordinates = unique(coordinates, "stable");
if isempty(coordinates)
    error("SpectraLab:Examples:ColorCheckerPatchListRequired", ...
        "Enter at least one patch ID, for example N1 K6.");
end
end

function output = safeName(value)
output = regexprep(strtrim(string(value)), "[^A-Za-z0-9_-]+", "_");
output = strip(regexprep(output, "_+", "_"), "_");
if output == "", output = "ColorChecker"; end
end

function value = displayValue(value)
if value == "", value = "not recorded"; end
end
