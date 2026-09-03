function archive = load(filename, options)
%LOAD Load a SpectraLab archive from a MAT-file.
%
%   archive = spectralab.archive.load(filename)
%
%   archive = spectralab.archive.load(filename, Quiet=true)
%
%   archive = spectralab.archive.load(filename, Validation="warn")
%
%   archive = spectralab.archive.load(filename, Validation="error")
%
% By default, a concise archive summary is displayed after loading.
% Set Quiet=true for scripts and batch processing.
%
% Validation modes:
%   "none"  Load without content validation (backward-compatible default).
%   "warn"  Load and issue warnings for validation errors and warnings.
%   "error" Reject archives that fail validation.

arguments
    filename {mustBeTextScalar}
    options.Quiet (1,1) logical = false
    options.Validation (1,1) string = "none"
end

validationMode = lower(strtrim(options.Validation));

allowedModes = ["none","warn","error"];
if ~any(validationMode == allowedModes)
    error("SpectraLab:Archive:InvalidValidationMode", ...
        "Validation must be ""none"", ""warn"", or ""error"".");
end

filename = char(string(filename));

if ~isfile(filename)
    error("SpectraLab:Archive:FileNotFound", ...
        "Archive file not found: %s", filename);
end

S = load(filename, "-mat");

if isfield(S,"spectralArtifact")
    artifactValidation=spectralab.archive.validateSpectralArtifact( ...
        S.spectralArtifact);
    if ~artifactValidation.IsValid
        error("SpectraLab:Archive:InvalidArtifact", "%s", ...
            strjoin(artifactValidation.Errors,newline));
    end
    if string(S.spectralArtifact.Kind)~="single_spectrum" || ...
            ~isfield(S.spectralArtifact.Payload,"Archive")
        error("SpectraLab:Archive:ArtifactNotSingleSpectrum", ...
            "This spectral artifact is not one loadable spectrum.");
    end
    S.archive=S.spectralArtifact.Payload.Archive;
end

if ~isfield(S, "archive")
    error("SpectraLab:Archive:InvalidFile", ...
        "MAT-file does not contain a SpectraLab archive.");
end

archive = S.archive;

required = [ ...
    "Identity"
    "Version"
    "Measurement"
    "Metadata"
    "Instrument"
    "Quality"
    "History"];

for k = 1:numel(required)
    if ~isfield(archive, required(k))
        error("SpectraLab:Archive:InvalidArchive", ...
            "Archive is missing required field '%s'.", required(k));
    end
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

if ~options.Quiet
    spectralab.archive.summary(archive);
end
end
