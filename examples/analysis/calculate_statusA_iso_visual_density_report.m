% calculate_statusA_iso_visual_density_report
%
% Generate the registered ANL-005 Status A RGB and ISO visual density PDF
% for the bundled synthetic reference and sample archives. ANL-005 has no
% registered figure, so this example creates no PNG.

scriptFile = string(mfilename("fullpath"));
examplesRoot = string(fileparts(fileparts(scriptFile)));
dataFolder = fullfile(examplesRoot, "data");
reportFolder = fullfile(examplesRoot, "output", "report");
if ~isfolder(reportFolder), mkdir(reportFolder); end

referenceFile = fullfile(dataFolder, "example_reference.mat");
sampleFile = fullfile(dataFolder, "example_sample_a.mat");
outputBase = "example_sample_a_StatusA";
pdfFile = fullfile(reportFolder, outputBase + "_ANL-005_report.pdf");
if isfile(pdfFile)
    error("SpectraLab:Examples:OutputFileAlreadyExists", ...
        "SpectraLab refuses to overwrite the existing file:\n%s", pdfFile);
end

reportInfo = spectralab.report.generate( ...
    [referenceFile, sampleFile], "ANL-005", reportFolder, ...
    OutputBaseName=outputBase, OpenPDF=false);
fprintf("SpectraLab Status A report created:\n  %s\n", ...
    reportInfo.PDFFile);
