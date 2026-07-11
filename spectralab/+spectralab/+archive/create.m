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
archive.Version.Version  = "0.5";
archive.Version.Software = spectralab.version();
archive.Version.Created  = datetime("now");

%----------------------------------------------------------
% Measurement
%----------------------------------------------------------

archive.Measurement.Name       = spec.Label;
archive.Measurement.Wavelength = spec.WavelengthNm;
archive.Measurement.Value      = spec.Power;
archive.Measurement.Unit       = spec.PowerUnit;
if isfield(spec.Metadata, "Operator")
    archive.Measurement.Operator = string(spec.Metadata.Operator);
else
    archive.Measurement.Operator = "";
end
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

% Copy structured metadata from the Spectrum when available
meta = spec.Metadata;

if isfield(meta,"Project"),      archive.Metadata.Project = string(meta.Project); end
if isfield(meta,"SampleID"),     archive.Metadata.SampleID = string(meta.SampleID); end
if isfield(meta,"Description"),  archive.Metadata.Description = string(meta.Description); end
if isfield(meta,"Laboratory"),   archive.Metadata.Laboratory = string(meta.Laboratory); end

if isfield(meta,"Tags")
    archive.Metadata.Tags = string(meta.Tags);
elseif isfield(meta,"Keywords")
    archive.Metadata.Tags = string(meta.Keywords);
end

if isfield(meta,"Comment")
    archive.Metadata.Comment = string(meta.Comment);
elseif isfield(meta,"Notes")
    archive.Metadata.Comment = string(meta.Notes);
end

%----------------------------------------------------------
% Instrument
%----------------------------------------------------------

archive.Instrument.Name          = "";
archive.Instrument.Driver        = "";
archive.Instrument.SerialNumber  = "";
archive.Instrument.CalibrationID = "";

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
