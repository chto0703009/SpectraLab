function spectralArtifact = loadSpectralArtifact(filename)
%LOADSPECTRALARTIFACT Load and validate one spectral exchange artifact.
arguments
    filename (1,1) string
end
if ~isfile(filename)
    error("SpectraLab:Artifact:NotFound", ...
        "Spectral artifact was not found:\n%s", filename);
end
payload = load(filename, "spectralArtifact");
if ~isfield(payload, "spectralArtifact") || ...
        ~isstruct(payload.spectralArtifact) || ~isscalar(payload.spectralArtifact)
    error("SpectraLab:Artifact:VariableMissing", ...
        "MAT file does not contain one spectralArtifact structure: %s", filename);
end
spectralArtifact = payload.spectralArtifact;
validation = spectralab.archive.validateSpectralArtifact(spectralArtifact);
if ~validation.IsValid
    error("SpectraLab:Artifact:Invalid", "%s", ...
        strjoin(validation.Errors, newline));
end
end
