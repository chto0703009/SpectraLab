function artifact = createSpectrumArtifact(archive, options)
%CREATESPECTRUMARTIFACT Wrap one measured or derived archive for exchange.
arguments
    archive (1,1) struct
    options.Quantity (1,1) string = ""
    options.Origin (1,1) string = ""
    options.SourceFile (1,1) string = ""
end

validation = spectralab.archive.validate(archive);
if ~validation.IsValid
    error("SpectraLab:Artifact:SourceArchiveInvalid", "%s", ...
        strjoin(validation.Errors,newline));
end
quantity = options.Quantity;
if quantity == ""
    quantity = inferQuantity(archive);
end
origin = lower(strip(options.Origin));
if origin == ""
    origin = "measured";
    if isfield(archive,"Derivation") || ...
            (isfield(archive.Measurement,"Context") && ...
            isfield(archive.Measurement.Context,"Origin") && ...
            string(archive.Measurement.Context.Origin)=="derived")
        origin = "derived";
    end
end
if ~any(origin == ["measured" "derived"])
    error("SpectraLab:Artifact:Origin", ...
        "Origin must be measured or derived.");
end
provenance = struct("SourceFile",options.SourceFile, ...
    "SourceUUID",string(archive.Identity.UUID), ...
    "SourceContentHash",string(archive.Identity.ContentHash), ...
    "Output",struct("Type","Spectrum","Cardinality",1, ...
    "Role","ReusableAnalysisInput"));
if isfield(archive,"Derivation"), provenance.Derivation=archive.Derivation; end
artifact = struct("Schema","spectralab.spectral-artifact", ...
    "SchemaVersion","1.0","Identity",struct(),"Origin",origin, ...
    "Kind","single_spectrum","Quantity",quantity, ...
    "Payload",struct("Archive",archive),"Provenance",provenance);
artifact.Identity = struct("UUID",string(java.util.UUID.randomUUID), ...
    "Created",datetime("now","TimeZone","UTC"), ...
    "ContentHash",spectralab.archive.contentHash(rmfield(artifact,"Identity")));
end

function quantity = inferQuantity(archive)
quantity = "spectral_power";
context=archive.Measurement.Context;
signal=""; kind="";
if isfield(context,"SignalQuantity"), signal=lower(string(context.SignalQuantity)); end
if isfield(context,"Kind"), kind=lower(string(context.Kind)); end
if contains(signal,"transmitt") || contains(kind,"transmiss")
    quantity="spectral_transmittance";
elseif contains(signal,"reflect") || contains(kind,"reflect")
    quantity="spectral_reflectance";
end
end
