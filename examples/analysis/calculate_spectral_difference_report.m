% calculate_spectral_difference_report
%
% Calculate the registered ANL-010 signed pointwise difference between the
% bundled synthetic samples. The diagnostic result is reported as PDF and
% PNG; no derived archive is created.

scriptFile = string(mfilename("fullpath"));
examplesRoot = string(fileparts(fileparts(scriptFile)));
dataFolder = fullfile(examplesRoot, "data");
reportFolder = fullfile(examplesRoot, "output", "report");
plotFolder = fullfile(examplesRoot, "output", "plot");
for folderName = [reportFolder, plotFolder]
    if ~isfolder(folderName), mkdir(folderName); end
end

sourceA = fullfile(dataFolder, "example_sample_a.mat");
sourceB = fullfile(dataFolder, "example_sample_b.mat");
outputBase = "example_samples_difference";
pdfFile = fullfile(reportFolder, outputBase + "_ANL-010_report.pdf");
pngFile = fullfile(plotFolder, outputBase + "_ANL-010_figure.png");
for outputFile = [pdfFile, pngFile]
    if isfile(outputFile)
        error("SpectraLab:Examples:OutputFileAlreadyExists", ...
            "SpectraLab refuses to overwrite the existing file:\n%s", ...
            outputFile);
    end
end

reportInfo = spectralab.report.generate( ...
    [sourceA, sourceB], "ANL-010", reportFolder, ...
    OutputBaseName=outputBase, ShowFigure=false, OpenPDF=false);
[moved, message] = movefile(reportInfo.PNGFile, pngFile);
if ~moved
    error("SpectraLab:Examples:PlotMoveFailed", ...
        "Could not move the report PNG to:\n%s\n\n%s", pngFile, message);
end

fprintf("SpectraLab spectral-difference report created:\n");
fprintf("  PDF: %s\n", reportInfo.PDFFile);
fprintf("  PNG: %s\n", pngFile);
