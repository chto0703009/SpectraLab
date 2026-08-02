function saveInfo = internal_save_spectrum_outputs( ...
        measurement, measurementName, outputRoot, options)
%INTERNAL_SAVE_SPECTRUM_OUTPUTS Save canonical example measurement outputs.

arguments
    measurement (1,1) spectralab.core.Spectrum
    measurementName (1,1) string
    outputRoot (1,1) string
    options.OpenPDF (1,1) logical = true
end

measurementName = strtrim(measurementName);
if ismissing(measurementName) || strlength(measurementName) == 0 || ...
        ~isempty(regexp(char(measurementName), '[\\/:]', 'once'))
    error("SpectraLab:Examples:InvalidMeasurementName", ...
        "Measurement name must be non-empty and contain no path separators.");
end

archiveFolder = fullfile(outputRoot, "archive");
reportFolder = fullfile(outputRoot, "report");
plotFolder = fullfile(outputRoot, "plot");
for folderName = [archiveFolder, reportFolder, plotFolder]
    ensureFolder(folderName);
end

archiveFile = fullfile(archiveFolder, measurementName + ".mat");
pdfFile = fullfile(reportFolder, ...
    measurementName + "_ANL-SPECTRUM_report.pdf");
pngFile = fullfile(plotFolder, ...
    measurementName + "_ANL-SPECTRUM_figure.png");
for outputFile = [archiveFile, pdfFile, pngFile]
    if isfile(outputFile)
        error("SpectraLab:Examples:OutputFileAlreadyExists", ...
            "SpectraLab refuses to overwrite the existing file:\n%s", ...
            outputFile);
    end
end

archive = spectralab.archive.create(measurement);
spectralab.archive.save(archive, archiveFile);
reportInfo = spectralab.report.generate( ...
    archiveFile, "ANL-SPECTRUM", reportFolder, ...
    ShowFigure=false, OpenPDF=false);

[moved, message] = movefile(reportInfo.PNGFile, pngFile);
if ~moved
    error("SpectraLab:Examples:PlotMoveFailed", ...
        "Could not move the report PNG to:\n%s\n\n%s", pngFile, message);
end
reportInfo.PNGFile = pngFile;
if options.OpenPDF
    open(char(reportInfo.PDFFile));
end

saveInfo = struct( ...
    "ArchiveFile", archiveFile, ...
    "PDFFile", string(reportInfo.PDFFile), ...
    "PNGFile", pngFile);

fprintf("SpectraLab measurement saved:\n");
fprintf("  MAT: %s\n", saveInfo.ArchiveFile);
fprintf("  PDF: %s\n", saveInfo.PDFFile);
fprintf("  PNG: %s\n", saveInfo.PNGFile);
end

function ensureFolder(folderName)
if isfolder(folderName), return; end
[created, message] = mkdir(folderName);
if ~created
    error("SpectraLab:Examples:OutputFolderCreationFailed", ...
        "Could not create output folder:\n%s\n\n%s", ...
        folderName, message);
end
end
