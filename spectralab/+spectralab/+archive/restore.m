function spec = restore(archive, options)
%RESTORE Restore a Spectrum object from a SpectraLab archive.
%
%   spec = spectralab.archive.restore(archive)
%
%   spec = spectralab.archive.restore(archive, Validation="warn")
%
%   spec = spectralab.archive.restore(archive, Validation="none")
%
% Validation modes:
%   "error" Reject invalid archives before restoring (default).
%   "warn"  Restore but issue warnings for validation errors and warnings.
%   "none"  Restore without validation.
%
% Archived metadata and calibration identity are preserved in the restored
% Spectrum object.

arguments
    archive (1,1) struct
    options.Validation (1,1) string = "error"
end

validationMode = lower(strtrim(options.Validation));
allowedModes = ["none","warn","error"];

if ~any(validationMode == allowedModes)
    error("SpectraLab:Archive:InvalidValidationMode", ...
        "Validation must be ""none"", ""warn"", or ""error"".");
end

if validationMode ~= "none"
    validation = spectralab.archive.validate(archive);

    if validationMode == "error" && ~validation.IsValid
        message = strjoin(validation.Errors, newline);
        error("SpectraLab:Archive:ValidationFailed", ...
            "Archive validation failed:\n%s", message);
    end

    if validationMode == "warn"
        for k = 1:numel(validation.Errors)
            warning("SpectraLab:Archive:ValidationError", ...
                "%s", validation.Errors(k));
        end

        for k = 1:numel(validation.Warnings)
            warning("SpectraLab:Archive:ValidationWarning", ...
                "%s", validation.Warnings(k));
        end
    end
end

metadata = archive.Metadata;

if isfield(archive.Measurement, "Operator")
    metadata.Operator = string(archive.Measurement.Operator);
end

calibration = struct();

if isfield(archive.Instrument, "CalibrationID")
    calibration.CalibrationID = ...
        string(archive.Instrument.CalibrationID);
end

spec = spectralab.core.Spectrum( ...
    archive.Measurement.Wavelength, ...
    archive.Measurement.Value, ...
    archive.Measurement.Name, ...
    archive.Instrument, ...
    calibration, ...
    metadata, ...
    archive.Measurement.Unit);
end
