function result = validate(archive)
%VALIDATE Validate a SpectraLab archive without modifying it.
%
%   result = spectralab.archive.validate(archive)
%
% The returned structure contains:
%   result.IsValid
%   result.Errors
%   result.Warnings
%   result.StoredContentHash
%   result.CalculatedContentHash
%
% Validation checks:
%   - required top-level sections
%   - archive format and version presence
%   - wavelength/value vector consistency
%   - finite numeric measurement data
%   - strictly increasing wavelengths
%   - deterministic scientific content hash

arguments
    archive (1,1) struct
end


errors = strings(0,1);
warnings = strings(0,1);

required = [ ...
    "Identity", ...
    "Version", ...
    "Measurement", ...
    "Metadata", ...
    "Instrument", ...
    "Quality" ...
];

missingRequired = required(~isfield(archive, required));

if ~isempty(missingRequired)
    errors = "Missing required section: " + missingRequired(:);
end

result = makeResult(false, errors, warnings, "", "");

if ~isempty(errors)
    return
end
		
if ~isempty(missingRequired)
    errors = "Missing required section: " + missingRequired(:);
end

result = makeResult(false, errors, warnings, "", "");

if ~isempty(errors)
    return
end

format = readText(archive.Version, "Format");
version = readText(archive.Version, "Version");

if strlength(format) == 0
    errors(end+1,1) = "Archive format is missing.";
elseif format ~= "SLAB-MAT"
    errors(end+1,1) = "Unsupported archive format: " + format;
end

if strlength(version) == 0
    errors(end+1,1) = "Archive version is missing.";
end

wavelength = readNumeric(archive.Measurement, "Wavelength");
value = readNumeric(archive.Measurement, "Value");

if isempty(wavelength)
    errors(end+1,1) = "Measurement wavelength data is missing.";
end

if isempty(value)
    errors(end+1,1) = "Measurement value data is missing.";
end

if ~isempty(wavelength) && ~isvector(wavelength)
    errors(end+1,1) = "Measurement wavelengths must be a vector.";
end

if ~isempty(value) && ~isvector(value)
    errors(end+1,1) = "Measurement values must be a vector.";
end

if ~isempty(wavelength) && ~isempty(value) && ...
        numel(wavelength) ~= numel(value)
    errors(end+1,1) = ...
        "Measurement wavelength and value vectors have different lengths.";
end

if ~isempty(wavelength)
    wavelength = wavelength(:);

    if any(~isfinite(wavelength))
        errors(end+1,1) = ...
            "Measurement wavelengths contain non-finite values.";
    elseif any(diff(wavelength) <= 0)
        errors(end+1,1) = ...
            "Measurement wavelengths must be strictly increasing.";
    end
end

if ~isempty(value)
    value = value(:);

    if any(~isfinite(value))
        errors(end+1,1) = ...
            "Measurement values contain non-finite values.";
    end
end

operator = readText(archive.Measurement, "Operator");
if strlength(operator) == 0
    warnings(end+1,1) = "Measurement operator is not recorded.";
end

instrumentName = readText(archive.Instrument, "Name");
if strlength(instrumentName) == 0
    warnings(end+1,1) = "Instrument name is not recorded.";
end

serialNumber = readText(archive.Instrument, "SerialNumber");
if strlength(serialNumber) == 0
    warnings(end+1,1) = "Instrument serial number is not recorded.";
end

storedHash = readText(archive.Identity, "ContentHash");
calculatedHash = "";

if strlength(storedHash) == 0
    errors(end+1,1) = "Content hash is missing.";
else
    payload = struct();
    payload.Measurement = archive.Measurement;
    payload.Instrument = archive.Instrument;
    payload.Quality = archive.Quality;

    calculatedHash = spectralab.archive.contentHash(payload);

    if ~strcmpi(storedHash, calculatedHash)
        errors(end+1,1) = "Content hash verification failed.";
    end
end

result = makeResult(isempty(errors), errors, warnings, ...
    storedHash, calculatedHash);
end

function result = makeResult(isValid, errors, warnings, storedHash, calculatedHash)
result = struct();
result.IsValid = logical(isValid);
result.Errors = string(errors);
result.Warnings = string(warnings);
result.StoredContentHash = string(storedHash);
result.CalculatedContentHash = string(calculatedHash);
end

function value = readText(source, fieldName)
value = "";

if ~isstruct(source) || isempty(source) || ...
        ~isfield(source, fieldName)
    return
end

raw = source.(fieldName);

if isempty(raw)
    return
end

try
    converted = string(raw);
catch
    return
end

if ~isempty(converted)
    value = strtrim(converted(1));
end
end

function value = readNumeric(source, fieldName)
value = [];

if ~isstruct(source) || isempty(source) || ...
        ~isfield(source, fieldName)
    return
end

raw = source.(fieldName);

if isnumeric(raw)
    value = raw;
end
end
