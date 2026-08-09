function amendment = loadRemeasurement(amendmentFile)
%LOADREMEASUREMENT Load a controlled ColorChecker amendment manifest.

arguments
    amendmentFile (1,1) string
end
if ~isfile(amendmentFile)
    error("SpectraLab:ColorChecker:AmendmentNotFound", ...
        "ColorChecker amendment not found: %s", amendmentFile);
end
amendment = jsondecode(fileread(amendmentFile));
if ~isfield(amendment, "Schema") || ...
        string(amendment.Schema) ~= "spectralab.colorchecker-amendment.v1"
    error("SpectraLab:ColorChecker:InvalidAmendment", ...
        "File is not a supported ColorChecker amendment: %s", amendmentFile);
end
amendment.History = reshape(string(amendment.History), [], 1);
end
