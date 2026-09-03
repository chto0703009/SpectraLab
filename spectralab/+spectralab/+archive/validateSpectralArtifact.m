function result = validateSpectralArtifact(artifact)
%VALIDATESPECTRALARTIFACT Validate the one-file exchange contract.
errors = strings(0,1);
required = ["Schema","SchemaVersion","Identity","Origin","Kind", ...
    "Quantity","Payload","Provenance"];
if ~isstruct(artifact) || ~isscalar(artifact)
    result = struct("IsValid",false,"Errors","Artifact must be a scalar structure.");
    return
end
for field = required
    if ~isfield(artifact, field)
        errors(end+1,1) = "Missing artifact field: " + field; %#ok<AGROW>
    end
end
if ~isempty(errors)
    result = struct("IsValid",false,"Errors",errors); return
end
if string(artifact.Schema) ~= "spectralab.spectral-artifact"
    errors(end+1,1) = "Unsupported spectral artifact schema.";
end
if string(artifact.SchemaVersion) ~= "1.0"
    errors(end+1,1) = "Unsupported spectral artifact version.";
end
if ~any(string(artifact.Origin) == ["measured","derived"])
    errors(end+1,1) = "Origin must be measured or derived.";
end
if ~any(string(artifact.Kind) == ["single_spectrum","spectrum_set"])
    errors(end+1,1) = "Kind must be single_spectrum or spectrum_set.";
end
if ~isfield(artifact.Identity,"ContentHash")
    errors(end+1,1) = "Artifact content hash is missing.";
else
    payload = rmfield(artifact, "Identity");
    calculated = spectralab.archive.contentHash(payload);
    if ~strcmpi(string(artifact.Identity.ContentHash), calculated)
        errors(end+1,1) = "Artifact content hash verification failed.";
    end
end
result = struct("IsValid",isempty(errors),"Errors",errors);
end
