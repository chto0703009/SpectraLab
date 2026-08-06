% calculate_cri_report
%
% Run the registered ANL-CRI analysis for the bundled synthetic reference.
% The PDF is written to output/report and the PNG to output/plot.

scriptFile = string(mfilename("fullpath"));
examplesRoot = string(fileparts(fileparts(scriptFile)));
archiveFile = fullfile(examplesRoot, "data", "example_reference.mat");
reportFolder = fullfile(examplesRoot, "output", "report");
plotFolder = fullfile(examplesRoot, "output", "plot");
if ~isfolder(reportFolder), mkdir(reportFolder); end
if ~isfolder(plotFolder), mkdir(plotFolder); end

pdfFile = fullfile(reportFolder, ...
    "example_reference_ANL-CRI_report.pdf");
pngFile = fullfile(plotFolder, ...
    "example_reference_ANL-CRI_figure.png");
for outputFile = [pdfFile, pngFile]
    if isfile(outputFile)
        error("SpectraLab:Examples:OutputFileAlreadyExists", ...
            "SpectraLab refuses to overwrite the existing file:\n%s", ...
            outputFile);
    end
end

reportInfo = spectralab.report.generate( ...
    archiveFile, "ANL-CRI", reportFolder, ...
    ShowFigure=false, OpenPDF=false, FigureOutputFolder=plotFolder);

fprintf("SpectraLab CRI report created:\n");
fprintf("  PDF: %s\n", reportInfo.PDFFile);
fprintf("  PNG: %s\n", reportInfo.PNGFile);
