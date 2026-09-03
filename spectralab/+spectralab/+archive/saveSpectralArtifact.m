function saveSpectralArtifact(spectralArtifact, filename)
%SAVESPECTRALARTIFACT Save one self-contained spectral exchange artifact.
arguments
    spectralArtifact (1,1) struct
    filename (1,1) string
end

validation = spectralab.archive.validateSpectralArtifact(spectralArtifact);
if ~validation.IsValid
    error("SpectraLab:Artifact:Invalid", "%s", ...
        strjoin(validation.Errors, newline));
end
if isfile(filename)
    error("SpectraLab:Artifact:OutputExists", ...
        "SpectraLab refuses to overwrite the existing file:\n%s", filename);
end
folder = string(fileparts(filename));
if folder ~= "" && ~isfolder(folder), mkdir(folder); end
save(filename, "spectralArtifact", "-v7");
end
