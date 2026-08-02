% calculate_spectral_mean_report
%
% Calculate the registered ANL-009 pointwise mean of the two bundled
% synthetic sample archives. The scientifically traceable derived archive,
% PDF report and PNG figure are saved below examples/output/.

scriptFile = string(mfilename("fullpath"));
examplesRoot = string(fileparts(fileparts(scriptFile)));
dataFolder = fullfile(examplesRoot, "data");
archiveFolder = fullfile(examplesRoot, "output", "archive");
reportFolder = fullfile(examplesRoot, "output", "report");
plotFolder = fullfile(examplesRoot, "output", "plot");
for folderName = [archiveFolder, reportFolder, plotFolder]
    if ~isfolder(folderName), mkdir(folderName); end
end

sourceA = fullfile(dataFolder, "example_sample_a.mat");
sourceB = fullfile(dataFolder, "example_sample_b.mat");
outputBase = "example_samples_mean";
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

archiveA = spectralab.archive.load( ...
    sourceA, Quiet=true, Validation="error");
archiveB = spectralab.archive.load( ...
    sourceB, Quiet=true, Validation="error");
meanResult = spectralab.analysis.spectralMean( ...
    archiveA, archiveB, ResultName=outputBase, ...
    SourceFiles=["example_sample_a.mat", "example_sample_b.mat"]);
spectralab.archive.save( ...
    meanResult.Result.DerivedArchive, derivedArchiveFile);

reportInfo = spectralab.report.generate( ...
    [sourceA, sourceB], "ANL-009", reportFolder, ...
    OutputBaseName=outputBase, ...
    DerivedArchiveFile=derivedArchiveFile, ...
    ShowFigure=false, OpenPDF=false);
[moved, message] = movefile(reportInfo.PNGFile, pngFile);
if ~moved
    error("SpectraLab:Examples:PlotMoveFailed", ...
        "Could not move the report PNG to:\n%s\n\n%s", pngFile, message);
end

fprintf("SpectraLab spectral-mean report created:\n");
fprintf("  Archive: %s\n", derivedArchiveFile);
fprintf("  PDF:     %s\n", reportInfo.PDFFile);
fprintf("  PNG:     %s\n", pngFile);
