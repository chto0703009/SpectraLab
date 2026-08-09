function [jsonFile, pdfFile, csvFile] = colorimetryOutputFiles( ...
        sessionFile, illuminant, observer)
%COLORIMETRYOUTPUTFILES Return deterministic ColorChecker result paths.

arguments
    sessionFile (1,1) string
    illuminant (1,1) spectralab.core.Spectrum
    observer (1,1) string = "CIE1931_2"
end
if isfolder(sessionFile)
    sessionFile = fullfile(sessionFile, "colorchecker_session.json");
end
[folder, baseName] = fileparts(sessionFile);
illuminantName = fileToken(illuminant.Label);
if contains(upper(illuminant.Label), "D50")
    illuminantName = "D50";
end
convertedBaseName = baseName + "_colorimetry_" + ...
    illuminantName + "_" + fileToken(observer);
jsonFile = fullfile(folder, convertedBaseName + ".json");
pdfFile = fullfile(folder, "report", convertedBaseName + "_report.pdf");
csvFile = fullfile(folder, convertedBaseName + ".csv");
end

function token = fileToken(value)
token = regexprep(strtrim(string(value)), "[^A-Za-z0-9_-]+", "_");
token = strip(regexprep(token, "_+", "_"), "_");
if token == "", token = "unspecified"; end
end
