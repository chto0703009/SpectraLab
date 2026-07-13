% NOTE
%
% The archive structure is part of the SpectraLab
% engineering contract (ED-001).
%
% Changes to this structure require an Engineering
% Decision review.
function archive = create(spec)
%CREATE Create a SpectraLab archive from a Spectrum object.
%
%   archive = spectralab.archive.create(spec)
%
% This function converts a Spectrum object into the
% standard SpectraLab archive structure. The returned
% structure is independent of MATLAB class definitions
% and is intended for long-term preservation.

arguments
    spec (1,1) spectralab.core.Spectrum
end

%----------------------------------------------------------
% Archive identity
%----------------------------------------------------------

archive.Identity.UUID          = string(java.util.UUID.randomUUID);
archive.Identity.Created       = datetime("now");
archive.Identity.CreatedBy     = "SpectraLab";
archive.Identity.HashAlgorithm = "SHA-256";

%----------------------------------------------------------
% Archive version
%----------------------------------------------------------

archive.Version.Format   = "SLAB-MAT";
archive.Version.Version  = "0.6";
archive.Version.Software = spectralab.version();
archive.Version.Created  = datetime("now");

%----------------------------------------------------------
% Measurement
%----------------------------------------------------------

archive.Measurement.Name       = spec.Label;
archive.Measurement.Wavelength = spec.WavelengthNm;
archive.Measurement.Value      = spec.Power;
archive.Measurement.Unit       = spec.PowerUnit;
archive.Measurement.Operator   = readTextField(spec.Metadata, ...
    ["Operator", "operator"]);
archive.Measurement.Timestamp  = spec.Timestamp;

%----------------------------------------------------------
% Metadata
%----------------------------------------------------------

archive.Metadata.Project     = "";
archive.Metadata.SampleID    = "";
archive.Metadata.Description = "";
archive.Metadata.Laboratory  = "";
archive.Metadata.Tags        = strings(0);
archive.Metadata.Comment     = "";

% Copy structured metadata from the Spectrum when available.
meta = spec.Metadata;

archive.Metadata.Project = readTextField(meta, ...
    ["Project", "project"]);

archive.Metadata.SampleID = readTextField(meta, ...
    ["SampleID", "SampleId", "sample_id", "sample"]);

archive.Metadata.Description = readTextField(meta, ...
    ["Description", "description"]);

archive.Metadata.Laboratory = readTextField(meta, ...
    ["Laboratory", "laboratory", "Lab"]);

tags = readField(meta, ["Tags", "Keywords", "tags", "keywords"]);
if ~isempty(tags)
    archive.Metadata.Tags = string(tags);
end

archive.Metadata.Comment = readTextField(meta, ...
    ["Comment", "Notes", "comment", "notes"]);

%----------------------------------------------------------
% Instrument
%----------------------------------------------------------

% META-001:
% Preserve the instrument provenance already captured in Spectrum.
% Aliases are accepted defensively because drivers may expose equivalent
% information under different field names.

instrument = spec.Instrument;
calibration = spec.Calibration;

archive.Instrument.Name = readTextField(instrument, ...
    ["Name", "Model", "InstrumentName", "Instrument", ...
     "name", "model", "instrument_name"]);

archive.Instrument.Driver = readTextField(instrument, ...
    ["Driver", "Backend", "DriverName", ...
     "driver", "backend", "driver_name"]);

archive.Instrument.SerialNumber = readTextField(instrument, ...
    ["SerialNumber", "Serial", "SerialNo", ...
     "serial_number", "serial", "serial_no"]);

archive.Instrument.CalibrationID = readTextField(calibration, ...
    ["CalibrationID", "CalibrationId", "ID", "Id", ...
     "calibration_id", "id"]);

% If a driver stores calibration identity with the instrument information,
% use it only when the calibration structure did not provide one.
if strlength(archive.Instrument.CalibrationID) == 0
    archive.Instrument.CalibrationID = readTextField(instrument, ...
        ["CalibrationID", "CalibrationId", "calibration_id"]);
end

%----------------------------------------------------------
% Quality
%----------------------------------------------------------

archive.Quality.Valid       = true;
archive.Quality.Warning     = "";
archive.Quality.Saturated   = false;
archive.Quality.SignalLevel = [];
archive.Quality.Comment     = "";

%----------------------------------------------------------
% History
%----------------------------------------------------------

archive.History = struct.empty;

%----------------------------------------------------------
% Deterministic scientific content hash
%----------------------------------------------------------
%
% The ContentHash is a deterministic SHA-256 fingerprint of
% the scientific payload. It intentionally excludes UUIDs,
% creation timestamps, software version fields and editable
% descriptive metadata.
%
% UUID identifies this archive instance.
% ContentHash identifies the scientific measurement content.

payload = struct();
payload.Measurement = archive.Measurement;
payload.Instrument  = archive.Instrument;
payload.Quality     = archive.Quality;

archive.Identity.ContentHash = spectralab.archive.contentHash(payload);

end

function value = readTextField(source, candidates)
%READTEXTFIELD Return the first matching field as a scalar string.

value = "";
raw = readField(source, candidates);

if isempty(raw)
    return
end

try
    converted = string(raw);
catch
    return
end

if isempty(converted)
    return
end

value = strtrim(converted(1));
end

function value = readField(source, candidates)
%READFIELD Return the first matching struct field, ignoring case.

value = [];

if ~isstruct(source) || isempty(source)
    return
end

available = string(fieldnames(source));

for candidate = string(candidates)
    index = find(strcmpi(available, candidate), 1);

    if ~isempty(index)
        value = source.(char(available(index)));
        return
    end
end
end
