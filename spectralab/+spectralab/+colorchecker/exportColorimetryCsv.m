function csvFile = exportColorimetryCsv(conversion, csvFile)
%EXPORTCOLORIMETRYCSV Export one ColorChecker conversion as traceable CSV.

arguments
    conversion (1,1) struct
    csvFile (1,1) string
end
if ~isfield(conversion, "Results") || isempty(conversion.Results)
    error("SpectraLab:ColorChecker:ColorimetryResultsMissing", ...
        "The conversion contains no ColorChecker results.");
end
if isfile(csvFile)
    error("SpectraLab:ColorChecker:ColorimetryCsvAlreadyExists", ...
        "SpectraLab refuses to overwrite the ColorChecker CSV file:\n%s", ...
        csvFile);
end
results = conversion.Results;
count = numel(results);
patch = strings(count,1);
x = zeros(count,1); y = x; z = x;
lStar = x; aStar = x; bStar = x;
archiveFile = strings(count,1);
archiveUuid = strings(count,1);
archiveHash = strings(count,1);
for index = 1:count
    result = results(index);
    patch(index) = string(result.Coordinate);
    x(index) = double(result.XYZ.X);
    y(index) = double(result.XYZ.Y);
    z(index) = double(result.XYZ.Z);
    lStar(index) = double(result.Lab.L);
    aStar(index) = double(result.Lab.a);
    bStar(index) = double(result.Lab.b);
    archiveFile(index) = string(result.ArchiveFile);
    archiveUuid(index) = string(result.ArchiveUUID);
    archiveHash(index) = string(result.ArchiveContentHash);
end
illuminant = repmat(string(conversion.Illuminant.Label), count, 1);
observer = repmat(string(conversion.Observer), count, 1);
data = table(patch, x, y, z, lStar, aStar, bStar, illuminant, observer, ...
    archiveFile, archiveUuid, archiveHash, ...
    VariableNames=["Patch", "X", "Y", "Z", "L_star", "a_star", ...
        "b_star", "Illuminant", "Observer", "ArchiveFile", ...
        "ArchiveUUID", "ArchiveContentHash"]);
folder = string(fileparts(csvFile));
if folder ~= "" && ~isfolder(folder), mkdir(folder); end
temporary = csvFile + ".tmp-" + string(java.util.UUID.randomUUID);
cleanup = onCleanup(@() deleteIfExists(temporary));
writetable(data, temporary, FileType="text", Delimiter=",");
[ok, message] = movefile(temporary, csvFile);
if ~ok
    error("SpectraLab:ColorChecker:ColorimetryCsvWriteFailed", ...
        "Could not create ColorChecker CSV file:\n%s\n\n%s", ...
        csvFile, message);
end
clear cleanup
end

function deleteIfExists(filename)
if isfile(filename), delete(filename); end
end
