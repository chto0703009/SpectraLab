% Export all original measured ColorChecker patch spectra as one standalone JSON.
[name,folder]=uigetfile('*.json','Select completed target-defined SpectraLab ColorChecker session');
if isequal(name,0),return;end
sessionFile=fullfile(string(folder),string(name));
[outName,outFolder]=uiputfile('*.json','Export standalone ColorChecker spectra JSON',fullfile(folder,'colorchecker_spectra.json'));
if isequal(outName,0),return;end
outputFile=fullfile(string(outFolder),string(outName));
spectralab.colorchecker.exportSpectralJSON(sessionFile,outputFile);
fprintf("Self-contained ColorChecker spectra JSON saved:\n  %s\n",outputFile);
