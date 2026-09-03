%% Export one measured or derived spectrum as a self-contained artifact.
% Select a SpectraLab archive (ordinary measurement or derived mean). The
% resulting MAT file is the single spectral input referenced by Camera-41.
clearvars
setup_spectralab
[name,folder]=uigetfile({"*.mat","SpectraLab MAT (*.mat)"}, ...
    "Select spectrum to package");
if isequal(name,0), return; end
sourceFile=fullfile(string(folder),string(name));
archive=spectralab.archive.load(sourceFile,Quiet=true,Validation="error");
artifact=spectralab.archive.createSpectrumArtifact(archive,SourceFile=sourceFile);
[~,stem]=fileparts(sourceFile);
defaultID=spectralab.archive.normalizeArtifactID(stem);
answer=inputdlg("Short artifact ID", "Camera-41 spectral input", ...
    [1 60],cellstr(defaultID));
if isempty(answer), return; end
type=spectralab.archive.normalizeArtifactID(artifact.Quantity,MaximumLength=20);
outputs=spectralab.archive.nextArtifactOutput(string(folder), ...
    string(answer{1}),type);
outputFile=outputs.ArtifactFile;
spectralab.archive.saveSpectralArtifact(artifact,outputFile);
fprintf("SpectraLab spectral artifact saved:\n  %s\n",outputFile);
