function output = reflectanceOnlySpectrum(input, options)
%REFLECTANCEONLYSPECTRUM Prepare primary ColorChecker archive data.
%
% Derived colorimetric values and raw Spotread output are deliberately not
% preserved. XYZ and Lab are calculated later from R(lambda), an explicit
% illuminant and an explicit observer.

arguments
    input (1,1) spectralab.core.Spectrum
    options.Coordinate (1,1) string = ""
    options.SessionUUID (1,1) string = ""
    options.ChartName (1,1) string = ""
    options.ChartManufacturedDate (1,1) string = ""
end

if ~contains(lower(input.PowerUnit), "reflectance") && ...
        ~strcmpi(readMetadata(input.Metadata, "measurement_kind"), ...
            "reflectance")
    error("SpectraLab:ColorChecker:MeasurementIsNotReflectance", ...
        "ColorChecker patch archives must contain spectral reflectance.");
end

metadata = struct( ...
    "measurement_kind", "reflectance", ...
    "signal_quantity", "spectral reflectance factor");
copyNames = ["Operator", "Project", "SampleID", "Comment", ...
    "backend", "command", "status", "duration_seconds", ...
    "parse_info", "spectrum_file_info", "spectrum_source", ...
    "one_shot", "high_resolution", "spotread_options"];
for name = copyNames
    actualName = matchingField(input.Metadata, name);
    if actualName ~= ""
        metadata.(char(name)) = input.Metadata.(char(actualName));
    end
end
if options.Coordinate ~= ""
    metadata.ColorCheckerCoordinate = upper(strtrim(options.Coordinate));
end
if options.SessionUUID ~= ""
    metadata.ColorCheckerSessionUUID = strtrim(options.SessionUUID);
end
if options.ChartName ~= ""
    metadata.ColorCheckerName = strtrim(options.ChartName);
end
if options.ChartManufacturedDate ~= ""
    metadata.ColorCheckerManufacturedDate = ...
        strtrim(options.ChartManufacturedDate);
end

output = spectralab.core.Spectrum( ...
    input.WavelengthNm, input.Power, input.Label, input.Instrument, ...
    input.Calibration, metadata, "relative reflectance (%)");
output = output.withTimestamp(input.Timestamp);
end

function value = readMetadata(metadata, name)
field = matchingField(metadata, name);
if field == "", value = ""; else, value = string(metadata.(char(field))); end
end

function field = matchingField(data, requested)
field = "";
if ~isstruct(data), return, end
names = string(fieldnames(data));
index = find(strcmpi(names, requested), 1);
if ~isempty(index), field = names(index); end
end
