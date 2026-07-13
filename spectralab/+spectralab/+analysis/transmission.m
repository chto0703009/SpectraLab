function analysis = transmission(referenceArchive, sampleArchive)
%TRANSMISSION Create a transmission-spectrum analysis.
arguments
    referenceArchive (1,1) struct
    sampleArchive (1,1) struct
end

rv = spectralab.archive.validate(referenceArchive);
sv = spectralab.archive.validate(sampleArchive);

if ~rv.IsValid
    error("SpectraLab:Analysis:InvalidReference", ...
        "Reference archive is invalid:\n%s", strjoin(rv.Errors, newline));
end
if ~sv.IsValid
    error("SpectraLab:Analysis:InvalidSample", ...
        "Sample archive is invalid:\n%s", strjoin(sv.Errors, newline));
end

rw = referenceArchive.Measurement.Wavelength(:);
sw = sampleArchive.Measurement.Wavelength(:);
rr = referenceArchive.Measurement.Value(:);
sr = sampleArchive.Measurement.Value(:);

if numel(rw) ~= numel(sw) || ~isequal(rw, sw)
	error("SpectraLab:Analysis:WavelengthMismatch", ...
	    "Reference and sample wavelength grids are not identical. " + ...
	    "Explicit spectral alignment is required.");
end
if numel(rr) ~= numel(sr)
    error("SpectraLab:Analysis:ValueLengthMismatch", ...
        "Reference and sample value vectors have different lengths.");
end
if any(~isfinite(rr)) || any(~isfinite(sr))
    error("SpectraLab:Analysis:NonFiniteInput", ...
        "Reference and sample values must be finite.");
end
if any(rr <= 0)
    error("SpectraLab:Analysis:InvalidReferenceSignal", ...
        "Reference values must be greater than zero.");
end

t = sr ./ rr;

analysis.Identity.UUID = string(java.util.UUID.randomUUID);
analysis.Identity.Created = datetime("now");
analysis.Identity.CreatedBy = "SpectraLab";
analysis.Identity.HashAlgorithm = "SHA-256";

analysis.Version.Format = "SLAB-ANALYSIS-MAT";
analysis.Version.Version = "0.1";
analysis.Version.Software = spectralab.version();

analysis.Definition.Type = "TransmissionSpectrum";
analysis.Definition.Method = "SampleReferenceRatio";

analysis.Result.Kind = "Spectral";
analysis.Result.Quantity = "Transmittance";
analysis.Result.WavelengthNm = rw;
analysis.Result.Value = t;
analysis.Result.Unit = "1";
analysis.Result.DisplayUnit = "%";
analysis.Result.DisplayScale = 100;

analysis.Sources = [
    makeSource(referenceArchive, "Reference")
    makeSource(sampleArchive, "Sample")
];

analysis.Parameters.Alignment = "Exact";
analysis.Metadata = struct();
analysis.History = struct.empty;

payload.Definition = analysis.Definition;
payload.Result = analysis.Result;
payload.Sources = analysis.Sources;
payload.Parameters = analysis.Parameters;
analysis.Identity.ContentHash = spectralab.archive.contentHash(payload);

if any(t > 1)
    warning("SpectraLab:Analysis:TransmittanceAboveOne", ...
        "Calculated transmittance exceeds 1 at one or more wavelengths.");
end
end

function source = makeSource(archive, role)
source.Kind = "Measurement";
source.Role = string(role);
source.Format = string(archive.Version.Format);
source.UUID = string(archive.Identity.UUID);
source.ContentHash = string(archive.Identity.ContentHash);
source.Quantity = "MeasuredSpectrum";
source.MeasurementMode = "Unspecified";
if isfield(archive.Measurement, "Mode") && ~isempty(archive.Measurement.Mode)
    source.MeasurementMode = string(archive.Measurement.Mode);
end
source.MeasurementName = string(archive.Measurement.Name);
source.Timestamp = archive.Measurement.Timestamp;
end
