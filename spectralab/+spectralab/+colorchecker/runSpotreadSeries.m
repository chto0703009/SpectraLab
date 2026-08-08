function series = runSpotreadSeries(labels, outputFolder, options)
%RUNSPOTREADSERIES Measure ColorChecker patches through the Python bridge.
%
% SERIES = spectralab.colorchecker.runSpotreadSeries(LABELS, FOLDER)
% starts one persistent spotread process, calibrates once and measures the
% requested labels in order. LABELS may contain any positive number of
% unique coordinates, for example ["A1","B1",...,"N10"].

arguments
    labels (1,:) string
    outputFolder (1,1) string
    options.SpotreadExecutable (1,1) string = ""
    options.PythonExecutable (1,1) string = ""
    options.HighResolution (1,1) logical = false
    options.TimeoutSeconds (1,1) double {mustBePositive} = 300
    options.OperatorUI (1,1) string {mustBeMember(options.OperatorUI, ...
        ["dialog", "command-window"])} = "dialog"
    options.InstrumentId (1,1) string = ""
    options.ChartName (1,1) string = ""
    options.ChartManufacturedDate (1,1) string = ""
end
labels = upper(strtrim(labels));
if isempty(labels) || any(strlength(labels) == 0) || ...
        numel(unique(labels)) ~= numel(labels)
    error("SpectraLab:ColorChecker:InvalidSeriesLabels", ...
        "Patch labels must be a non-empty list of unique coordinates.");
end
chartName = strtrim(options.ChartName);
chartDate = strtrim(options.ChartManufacturedDate);
if chartName == ""
    error("SpectraLab:ColorChecker:MissingChartName", ...
        "A ColorChecker name is required.");
end
if isempty(regexp(char(chartDate), '^\d{4}-(0[1-9]|1[0-2])$', 'once'))
    error("SpectraLab:ColorChecker:InvalidChartManufacturedDate", ...
        "ColorChecker manufactured date must use YYYY-MM, for example 2023-11.");
end
if ~isfolder(outputFolder), mkdir(outputFolder); end

spotread = options.SpotreadExecutable;
if spotread == ""
    spotread = spectralab.drivers.spotread.findSpotread();
end
python = options.PythonExecutable;
if python == ""
    python = spectralab.drivers.spotread.ManualSafeBridge.findPython();
end
if spotread == "", error("SpectraLab:Spotread:NotFound", "spotread was not found."); end
if python == "", error("SpectraLab:Spotread:PythonNotFound", "Python 3 was not found."); end

% Reflectance is spotread's default geometry. Never pass -e here: that is
% emissive mode and would make ColorChecker reflectance values invalid.
arguments = "-s";
if options.HighResolution, arguments(end+1) = "-H"; end
config = struct( ...
    "spotread", char(spotread), ...
    "arguments", {cellstr(arguments)}, ...
    "output_folder", char(outputFolder), ...
    "labels", {cellstr(labels)}, ...
    "operator_ui", char(options.OperatorUI), ...
    "instrument_id", char(options.InstrumentId), ...
    "high_resolution", options.HighResolution, ...
    "chart_name", char(chartName), ...
    "chart_manufactured_date", char(chartDate), ...
    "timeout", options.TimeoutSeconds);
configFile = fullfile(outputFolder, "series_config.json");
writeText(configFile, jsonencode(config, PrettyPrint=true));
script = spectralab.drivers.spotread.ManualSafeBridge.bridgeScript( ...
    "spotread_colorchecker_series.py");
command = quoteArgument(python) + " " + quoteArgument(script) + ...
    " " + quoteArgument(configFile);
status = system(char(command), "-echo");
series = spectralab.colorchecker.readSpotreadSeries(outputFolder);
if status ~= 0 && series.State ~= "cancelled"
    error("SpectraLab:ColorChecker:SeriesBridgeFailed", ...
        "Python Spotread series failed with status %d: %s", ...
        status, string(series.Manifest.message));
end
end

function value = quoteArgument(value)
value = char(string(value));
if ispc
    value = string(['"', strrep(value, '"', '""'), '"']);
else
    value = string(['''', strrep(value, '''', '''"''"'''), '''']);
end
end

function writeText(path, value)
fid = fopen(path, "w");
if fid < 0
    error("SpectraLab:ColorChecker:SeriesConfigWriteFailed", ...
        "Could not write Spotread series configuration: %s", path);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, "%s\n", value);
end
