function [series, summary, outputs] = measureSeries(labels, outputFolder, options)
%MEASURESERIES Acquire and preserve a Spotread ColorChecker series.
%
% This is the reusable SpectraLab acquisition function. Standard output is
% one immutable SpectraLab archive per patch plus the raw acquisition
% manifest. CSV and aggregate MAT files are explicit secondary exports.

arguments
    labels (1,:) string
    outputFolder (1,1) string
    options.InstrumentId (1,1) string
    options.HighResolution (1,1) logical = false
    options.ChartName (1,1) string
    options.ChartManufacturedDate (1,1) string
    options.ExportCSV (1,1) logical = false
    options.ExportSeriesMAT (1,1) logical = false
    options.OperatorUI (1,1) string = "dialog"
end

dataFolder = fullfile(outputFolder, "data");
if ~isfolder(dataFolder)
    [created, message] = mkdir(dataFolder);
    if ~created
        error("SpectraLab:ColorChecker:DataFolderCreationFailed", ...
            "Could not create ColorChecker data folder:\n%s\n\n%s", ...
            dataFolder, message);
    end
end
series = spectralab.colorchecker.runSpotreadSeries( ...
    labels, dataFolder, ...
    InstrumentId=options.InstrumentId, ...
    HighResolution=options.HighResolution, ...
    ChartName=options.ChartName, ...
    ChartManufacturedDate=options.ChartManufacturedDate, ...
    OperatorUI=options.OperatorUI);

n = series.CompletedPatchCount;
archiveFolder = fullfile(outputFolder, "archive");
if ~isfolder(archiveFolder)
    [created, message] = mkdir(archiveFolder);
    if ~created
        error("SpectraLab:ColorChecker:ArchiveFolderCreationFailed", ...
            "Could not create ColorChecker archive folder:\n%s\n\n%s", ...
            archiveFolder, message);
    end
end
coordinates = strings(n, 1);
lab = nan(n, 3);
xyz = nan(n, 3);
archiveFiles = strings(n, 1);
stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
for index = 1:n
    patch = series.Patches(index);
    coordinates(index) = patch.Coordinate;
    if patch.Colorimetry.available
        lab(index,:) = patch.Colorimetry.lab(:).';
        xyz(index,:) = patch.Colorimetry.xyz(:).';
    end
    primarySpectrum = spectralab.colorchecker.reflectanceOnlySpectrum( ...
        patch.Spectrum, Coordinate=patch.Coordinate, ...
        ChartName=options.ChartName, ...
        ChartManufacturedDate=options.ChartManufacturedDate);
    archive = spectralab.archive.create(primarySpectrum);
    archiveFiles(index) = fullfile(archiveFolder, ...
        safeName(patch.Coordinate) + "_" + stamp + ".mat");
    spectralab.archive.save(archive, archiveFiles(index));
end
summary = table(coordinates, xyz(:,1), xyz(:,2), xyz(:,3), ...
    lab(:,1), lab(:,2), lab(:,3), ...
    VariableNames=["Coordinate", "X", "Y", "Z", "L", "a", "b"]);

csvFile = "";
if options.ExportCSV
    csvFile = fullfile(outputFolder, "colorchecker_summary.csv");
    writetable(summary, csvFile);
end
seriesMatFile = "";
if options.ExportSeriesMAT
    seriesMatFile = fullfile(outputFolder, "colorchecker_series.mat");
    save(seriesMatFile, "series", "summary", "-v7.3");
end
outputs = struct("Folder", outputFolder, ...
    "DataFolder", dataFolder, ...
    "ArchiveFolder", archiveFolder, "ArchiveFiles", archiveFiles, ...
    "ReportFolder", fullfile(outputFolder, "report"), ...
    "PlotFolder", fullfile(outputFolder, "plot"), ...
    "CSVFile", csvFile, "SeriesMATFile", seriesMatFile);
end

function output = safeName(value)
output = regexprep(strtrim(string(value)), "[^A-Za-z0-9_-]+", "_");
output = strip(regexprep(output, "_+", "_"), "_");
if output == "", output = "ColorChecker_patch"; end
end
