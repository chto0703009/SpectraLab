% Export one complete ColorChecker spectral dataset as a single MAT file.
[sessionName,sessionFolder]=uigetfile({"*.json","SpectraLab session (*.json)"}, ...
    "Select completed ColorChecker session");
if isequal(sessionName,0), return; end
sessionFile=string(fullfile(sessionFolder,sessionName));
[~,stem]=fileparts(sessionFile);
defaultID=spectralab.archive.normalizeArtifactID(stem);
answer=inputdlg("Short artifact ID", "Camera-41 ColorChecker input", ...
    [1 60],cellstr(defaultID));
if isempty(answer), return; end
outputs=spectralab.archive.nextArtifactOutput(string(sessionFolder), ...
    string(answer{1}),"reflectance_set");
artifact=spectralab.colorchecker.createSpectralArtifact(sessionFile);
spectralab.archive.saveSpectralArtifact(artifact,outputs.ArtifactFile);
fprintf("ColorChecker spectral artifact saved:\n  %s\n", ...
    outputs.ArtifactFile);
