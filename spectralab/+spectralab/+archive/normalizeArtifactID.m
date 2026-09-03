function artifactID = normalizeArtifactID(value, options)
%NORMALIZEARTIFACTID Create a short filesystem-safe artifact identifier.
arguments
    value {mustBeTextScalar}
    options.MaximumLength (1,1) double {mustBeInteger,mustBePositive} = 40
end

artifactID=lower(strip(string(value)));
artifactID=replace(artifactID,["å","ä","ö"],["a","a","o"]);
artifactID=regexprep(artifactID,"[^a-z0-9]+","_");
artifactID=regexprep(artifactID,"^_+|_+$","");
if strlength(artifactID)>options.MaximumLength
    artifactID=extractBefore(artifactID,options.MaximumLength+1);
    artifactID=regexprep(artifactID,"_+$","");
end
if artifactID==""
    error("SpectraLab:ArtifactName:EmptyID", ...
        "Artifact ID must contain at least one letter or digit.");
end
end
