function txt = summary(archive)
%SUMMARY Return and optionally display a human-readable archive summary.
%
%   TXT = spectralab.archive.summary(archive)
%
%   spectralab.archive.summary(archive)
%
% When called without an output argument, the summary is printed.
% When called with an output argument, the formatted text is returned.

arguments
    archive (1,1) struct
end

required = ["Identity","Version","Measurement","Metadata","Instrument","Quality","History"];
for k = 1:numel(required)
    if ~isfield(archive, required(k))
        error("SpectraLab:Archive:InvalidArchive", ...
            "Archive is missing required field '%s'.", required(k));
    end
end

measurementName = localStringField(archive.Measurement, "Name", "");
sampleID        = localStringField(archive.Metadata, "SampleID", "");
project         = localStringField(archive.Metadata, "Project", "");
operator        = localStringField(archive.Measurement, "Operator", "");
laboratory      = localStringField(archive.Metadata, "Laboratory", "");
instrumentName  = localStringField(archive.Instrument, "Name", "");
serialNumber    = localStringField(archive.Instrument, "SerialNumber", "");
contentHash     = localStringField(archive.Identity, "ContentHash", "");

created = "";
if isfield(archive.Identity, "Created") && ~isempty(archive.Identity.Created)
    created = string(archive.Identity.Created);
end

wavelength = [];
if isfield(archive.Measurement, "Wavelength")
    wavelength = archive.Measurement.Wavelength;
end

sampleCount = numel(wavelength);

if sampleCount > 0
    rangeText = sprintf("%.1f - %.1f nm", min(wavelength), max(wavelength));
else
    rangeText = "not available";
end

if strlength(instrumentName) == 0
    instrumentText = "not specified";
elseif strlength(serialNumber) == 0
    instrumentText = instrumentName;
else
    instrumentText = instrumentName + " (S/N " + serialNumber + ")";
end

if strlength(contentHash) > 16
    contentHashDisplay = extractBefore(contentHash, 17) + "...";
else
    contentHashDisplay = contentHash;
end

lines = [
    "SpectraLab Archive"
    "------------------"
    "Measurement : " + localDisplayValue(measurementName)
    "Sample ID   : " + localDisplayValue(sampleID)
    "Project     : " + localDisplayValue(project)
    "Operator    : " + localDisplayValue(operator)
    "Laboratory  : " + localDisplayValue(laboratory)
    "Created     : " + localDisplayValue(created)
    "Instrument  : " + localDisplayValue(instrumentText)
    "Samples     : " + string(sampleCount)
    "Range       : " + rangeText
    "ContentHash : " + localDisplayValue(contentHashDisplay)
];

txt = strjoin(lines, newline);

if nargout == 0
    fprintf("%s\n", txt);
    clear txt
end

end

function value = localStringField(s, fieldName, defaultValue)
if isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = string(s.(fieldName));
else
    value = string(defaultValue);
end
end

function value = localDisplayValue(value)
value = string(value);
if strlength(value) == 0
    value = "not specified";
end
end
