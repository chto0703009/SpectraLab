% measure_transmission_pair
%
% Measure the emitted-light reference and the same light transmitted through
% a sample in one controlled Spotread session. Each source measurement is
% archived and reported independently. A registered transmission PDF and PNG
% are then calculated from the two immutable MAT archives.

scriptFile = string(mfilename("fullpath"));
examplesRoot = string(fileparts(fileparts(scriptFile)));
outputRoot = fullfile(examplesRoot, "output");
defaultName = "transmission_" + ...
    string(datetime("now", "Format", "yyyyMMdd_HHmmss"));

answers = inputdlg( ...
    {"Measurement-pair name", "Operator", "Project", "Comment"}, ...
    "SpectraLab - Measure transmission reference and sample", ...
    [1 70; 1 70; 1 70; 3 70], ...
    {char(defaultName), "Example operator", ...
     "SpectraLab transmission measurement", ""});
if isempty(answers)
    disp("SpectraLab transmission measurement cancelled. Nothing was saved.");
    return
end

baseName = strtrim(string(answers{1}));
if strlength(baseName) == 0 || ...
        ~isempty(regexp(char(baseName), '[\\/:]', 'once'))
    error("SpectraLab:Examples:InvalidMeasurementName", ...
        "Measurement-pair name must be non-empty and contain no path separators.");
end
operatorName = strtrim(string(answers{2}));
projectName = strtrim(string(answers{3}));
commentLines = strip(string(answers{4}), "right");
measurementComment = strip(strjoin(commentLines, newline));
referenceName = baseName + "_reference";
sampleName = baseName + "_sample";

instrumentId = select_spotread_instrument();
if instrumentId == ""
    disp("SpectraLab transmission measurement cancelled. Nothing was saved.");
    return
end
resolutionChoice = questdlg( ...
    "Select spectral resolution", ...
    "SpectraLab - Transmission resolution", ...
    "Standard", "High resolution", "Cancel", "Standard");
if isempty(resolutionChoice) || strcmp(resolutionChoice, "Cancel")
    disp("SpectraLab transmission measurement cancelled. Nothing was saved.");
    return
end
highResolution = strcmp(resolutionChoice, "High resolution");

preflightOutputs(outputRoot, referenceName, sampleName);

inst = spectralab.drivers.createInstrument( ...
    instrumentId, MeasurementKind="emissive", ...
    HighResolution=highResolution);
instrumentCleanup = onCleanup(@() inst.close());
sess = spectralab.core.Session(inst, AudibleFeedback=true);
sess = sess.withOperator(operatorName);
sess = sess.withProject(projectName);
sess = sess.withComment(measurementComment);
sess = sess.open();
sess = sess.calibrate("Mode", "automatic");
calibrationSerialNumber = verify_spotread_instrument( ...
    inst, "", "transmission calibration");
pause(1.0)

referencePrompt = "REFERENCE measurement" + newline + newline + ...
    "Remove the sample from the optical path." + newline + ...
    "Keep the source, instrument geometry and exposure fixed." + ...
    newline + newline + ...
    "Continue when the unfiltered source is ready.";
choice = questdlg(referencePrompt, ...
    "SpectraLab - Transmission reference", ...
    "Measure reference", "Cancel", "Measure reference");
if isempty(choice) || choice == "Cancel"
    sess = sess.close();
    clear instrumentCleanup
    disp("SpectraLab transmission measurement cancelled. Nothing was saved.");
    return
end

sess = sess.withSample(referenceName);
reference = sess.measure(referenceName, "Mode", "automatic");
verify_spotread_instrument( ...
    inst, calibrationSerialNumber, "transmission reference");
referenceInfo = internal_save_spectrum_outputs( ...
    reference, referenceName, outputRoot, OpenPDF=false);

samplePrompt = "SAMPLE measurement" + newline + newline + ...
    "Place the sample in the optical path without changing the source," + ...
    newline + "instrument geometry or exposure." + newline + newline + ...
    "The saved reference remains preserved if you stop now.";
choice = questdlg(samplePrompt, ...
    "SpectraLab - Transmission sample", ...
    "Measure sample", "Stop after reference", "Cancel", ...
    "Measure sample");
if isempty(choice) || choice == "Cancel" || choice == "Stop after reference"
    sess = sess.close();
    clear instrumentCleanup
    fprintf("Transmission workflow stopped after the reference.\n");
    fprintf("  Reference MAT: %s\n", referenceInfo.ArchiveFile);
    return
end

sess = sess.withSample(sampleName);
sample = sess.measure(sampleName, "Mode", "automatic");
verify_spotread_instrument( ...
    inst, calibrationSerialNumber, "transmission sample");
sampleInfo = internal_save_spectrum_outputs( ...
    sample, sampleName, outputRoot, OpenPDF=false);
sess = sess.close();
clear instrumentCleanup

reportFolder = fullfile(outputRoot, "report");
plotFolder = fullfile(outputRoot, "plot");
transmissionReport = spectralab.report.generate( ...
    [referenceInfo.ArchiveFile, sampleInfo.ArchiveFile], ...
    "ANL-001", reportFolder, ...
    ShowFigure=false, OpenPDF=false, FigureOutputFolder=plotFolder);
open(char(transmissionReport.PDFFile));

fprintf("SpectraLab transmission pair complete:\n");
fprintf("  INPUT reference MAT: %s\n", referenceInfo.ArchiveFile);
fprintf("  INPUT sample MAT:    %s\n", sampleInfo.ArchiveFile);
fprintf("  OUTPUT PDF report:   %s\n", transmissionReport.PDFFile);
fprintf("  OUTPUT PNG figure:   %s\n", transmissionReport.PNGFile);

function preflightOutputs(outputRoot, referenceName, sampleName)
archiveFolder = fullfile(outputRoot, "archive");
reportFolder = fullfile(outputRoot, "report");
plotFolder = fullfile(outputRoot, "plot");
expected = [ ...
    fullfile(archiveFolder, referenceName + ".mat"), ...
    fullfile(reportFolder, referenceName + "_ANL-SPECTRUM_report.pdf"), ...
    fullfile(plotFolder, referenceName + "_ANL-SPECTRUM_figure.png"), ...
    fullfile(archiveFolder, sampleName + ".mat"), ...
    fullfile(reportFolder, sampleName + "_ANL-SPECTRUM_report.pdf"), ...
    fullfile(plotFolder, sampleName + "_ANL-SPECTRUM_figure.png"), ...
    fullfile(reportFolder, sampleName + "_ANL-001_report.pdf"), ...
    fullfile(plotFolder, sampleName + "_ANL-001_figure.png")];
for file = expected
    if isfile(file)
        error("SpectraLab:Examples:OutputFileAlreadyExists", ...
            "SpectraLab refuses to overwrite the existing file:\n%s", file);
    end
end
end
