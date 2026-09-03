function output = nextArtifactOutput(artifactFolder, artifactID, type, options)
%NEXTARTIFACTOUTPUT Resolve a short, automatically revisioned output name.
arguments
    artifactFolder (1,1) string
    artifactID {mustBeTextScalar}
    type {mustBeTextScalar}
    options.ProofFolder (1,1) string = ""
    options.MaximumFilenameLength (1,1) double ...
        {mustBeInteger,mustBePositive} = 80
end

type=spectralab.archive.normalizeArtifactID(type,MaximumLength=20);
reserved=strlength("_"+type+"_v99_proof.png");
maximumID=max(1,min(40,options.MaximumFilenameLength-reserved));
artifactID=spectralab.archive.normalizeArtifactID(artifactID, ...
    MaximumLength=maximumID);
proofFolder=options.ProofFolder;
if proofFolder=="", proofFolder=artifactFolder; end

revision=1;
while true
    stem=artifactID+"_"+type+"_v"+compose("%02d",revision);
    artifactFile=fullfile(artifactFolder,stem+".mat");
    proofFile=fullfile(proofFolder,stem+"_proof.png");
    if ~isfile(artifactFile) && ~isfile(proofFile), break; end
    revision=revision+1;
end
output=struct("ArtifactID",artifactID,"Type",type, ...
    "Revision",revision,"Stem",stem,"ArtifactFile",artifactFile, ...
    "ProofPNG",proofFile);
end
