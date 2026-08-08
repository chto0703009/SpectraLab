function session = create(sessionFolder, options)
%CREATE Create a traceable ColorChecker measurement session.
%
%   SESSION = spectralab.colorchecker.create(FOLDER, Rows=10, Columns=14)
%
% A ColorChecker session is a manifest for a rectangular chart.  It does
% not contain spectra itself: every patch is stored as one immutable
% standard SpectraLab archive in FOLDER. The manifest records
% their identities, calibration events and the declared measurement order.

arguments
    sessionFolder (1,1) string
    options.Name (1,1) string = ""
    options.Rows (1,1) double {mustBeInteger, mustBePositive} = 1
    options.Columns (1,1) double {mustBeInteger, mustBePositive} = 1
    options.CalibrationIntervalMinutes (1,1) double {mustBePositive} = 30
    options.Operator (1,1) string = ""
    options.Project (1,1) string = ""
    options.ChartID (1,1) string = ""
    options.ChartSerialNumber (1,1) string = ""
    options.ChartManufacturedDate (1,1) string = ""
end

sessionFolder = string(sessionFolder);
if strlength(strtrim(sessionFolder)) == 0
    error("SpectraLab:ColorChecker:MissingFolder", ...
        "A ColorChecker session folder is required.");
end

if ~isfolder(sessionFolder)
    [ok, message] = mkdir(sessionFolder);
    if ~ok
        error("SpectraLab:ColorChecker:FolderCreationFailed", ...
            "Could not create ColorChecker session folder:\n%s\n\n%s", ...
            sessionFolder, message);
    end
end

sessionFile = fullfile(sessionFolder, "colorchecker_session.json");
if isfile(sessionFile)
    error("SpectraLab:ColorChecker:SessionAlreadyExists", ...
        "A ColorChecker session already exists:\n%s", sessionFile);
end

created = datetime("now", "TimeZone", "local");
if strlength(strtrim(options.Name)) == 0
    name = "ColorChecker " + string(created, "yyyy-MM-dd HH:mm");
else
    name = strtrim(options.Name);
end

patches = repmat(emptyPatch(), options.Rows * options.Columns, 1);
index = 0;
for row = 1:options.Rows
    for column = 1:options.Columns
        index = index + 1;
        patches(index).Coordinate = columnLabel(column) + string(row);
        patches(index).Column = column;
        patches(index).Row = row;
    end
end

session = struct();
session.Schema = "spectralab.colorchecker-session.v1";
session.Identity = struct( ...
    "UUID", string(java.util.UUID.randomUUID), ...
    "Created", char(created), ...
    "CreatedBy", "SpectraLab", ...
    "Software", spectralab.version(), ...
    "Revision", 0);
session.Definition = struct( ...
    "Name", name, ...
    "ChartID", strtrim(options.ChartID), ...
    "ChartSerialNumber", strtrim(options.ChartSerialNumber), ...
    "ChartManufacturedDate", normaliseManufacturedDate(options.ChartManufacturedDate), ...
    "Rows", options.Rows, ...
    "Columns", options.Columns, ...
    "CoordinateConvention", ...
        "Column letters increase left-to-right; row numbers increase top-to-bottom; A1 is upper left.", ...
    "MeasurementOrder", "row-major: A1, B1, ... then A2, B2, ...");
session.Context = struct( ...
    "Operator", strtrim(options.Operator), ...
    "Project", strtrim(options.Project), ...
    "SessionFolder", string(sessionFolder), ...
    "ArchiveFolder", ".");
session.CalibrationPolicy = struct( ...
    "IntervalMinutes", options.CalibrationIntervalMinutes, ...
    "InstrumentSignalPolicy", ...
        "Any reported instrument calibration error requires recalibration.");
session.Calibrations = repmat(emptyCalibration(), 0, 1);
session.Patches = patches;
session.History = string(created, "yyyy-MM-dd HH:mm:ss") + "  Session created.";

session = spectralab.colorchecker.save(session);
end

function value = normaliseManufacturedDate(value)
value = strtrim(string(value));
if strlength(value) == 0
    return
end
% Preserve what is printed on the chart when an exact ISO date is not
% available (for example a manufacture month or lot-marking). Exact dates
% are normalised to the portable ISO representation.
if ~isempty(regexp(char(value), '^\d{4}-\d{2}-\d{2}$', 'once'))
    try
        value = string(datetime(value, "InputFormat", "yyyy-MM-dd"), ...
            "yyyy-MM-dd");
    catch
        % Retain the entered traceability text; it is not measurement data.
    end
end
end

function patch = emptyPatch()
patch = struct( ...
    "Coordinate", "", ...
    "Column", 0, ...
    "Row", 0, ...
    "State", "pending", ...
    "ArchiveFile", "", ...
    "ArchiveUUID", "", ...
    "ArchiveContentHash", "", ...
    "Measured", "", ...
    "CalibrationSequence", 0);
end

function calibration = emptyCalibration()
calibration = struct( ...
    "Sequence", 0, ...
    "Timestamp", "", ...
    "DueAt", "", ...
    "Method", "", ...
    "Instrument", struct(), ...
    "Message", "");
end

function label = columnLabel(column)
label = "";
while column > 0
    remainder = mod(column - 1, 26);
    label = char(65 + remainder) + label;
    column = floor((column - 1) / 26);
end
end
