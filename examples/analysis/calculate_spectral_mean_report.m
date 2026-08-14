% calculate_spectral_mean_report
%
% Select two or more SpectraLab archives and calculate the registered
% ANL-009 pointwise arithmetic mean. The scientifically traceable derived
% archive, PDF report and PNG figure are saved below examples/output/.

scriptFile = string(mfilename("fullpath"));
examplesRoot = string(fileparts(fileparts(scriptFile)));
dataFolder = fullfile(examplesRoot, "data");
dataFolder = spectralab.ui.archiveFolder(dataFolder);
archiveFolder = fullfile(examplesRoot, "output", "archive");
reportFolder = fullfile(examplesRoot, "output", "report");
plotFolder = fullfile(examplesRoot, "output", "plot");
for folderName = [archiveFolder, reportFolder, plotFolder]
    if ~isfolder(folderName), mkdir(folderName); end
end

sourceFiles = spectralab.ui.selectArchiveFiles(dataFolder, ...
    Title="SpectraLab - Spectral Mean (ANL-009): select source archives", ...
    MinimumSelection=2);
if isempty(sourceFiles)
    fprintf("Spectral-mean selection cancelled.\n");
    return
end

timestamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
outputBase = "selected_spectra_mean_" + timestamp;
derivedArchiveFile = fullfile(archiveFolder, outputBase + ".mat");
pdfFile = fullfile(reportFolder, outputBase + "_ANL-009_report.pdf");
pngFile = fullfile(plotFolder, outputBase + "_ANL-009_figure.png");
for outputFile = [derivedArchiveFile, pdfFile, pngFile]
    if isfile(outputFile)
        error("SpectraLab:Examples:OutputFileAlreadyExists", ...
            "SpectraLab refuses to overwrite the existing file:\n%s", ...
            outputFile);
    end
end

meanResult = spectralab.analysis.spectralMean( ...
    sourceFiles, ResultName=outputBase);
spectralab.archive.save( ...
    meanResult.Result.DerivedArchive, derivedArchiveFile);

reportInfo = spectralab.report.generate( ...
    sourceFiles, "ANL-009", reportFolder, ...
    OutputBaseName=outputBase, ...
    DerivedArchiveFile=derivedArchiveFile, ...
    ShowFigure=false, OpenPDF=false, FigureOutputFolder=plotFolder);

fprintf("SpectraLab spectral-mean report created:\n");
fprintf("  Sources: %d\n", numel(sourceFiles));
for index = 1:numel(sourceFiles)
    fprintf("    %s\n", sourceFiles(index));
end
fprintf("  Archive: %s\n", derivedArchiveFile);
fprintf("  PDF:     %s\n", reportInfo.PDFFile);
fprintf("  PNG:     %s\n", pngFile);
