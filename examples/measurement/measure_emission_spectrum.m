% measure_emission_spectrum
%
% Measure one emitted-light spectrum with the bounded Spotread workflow and
% save a trusted MAT archive, registered PDF report and PNG figure below
% examples/output/. Requires ArgyllCMS and a connected i1Pro or i1Pro2.

scriptFile = string(mfilename("fullpath"));
examplesRoot = string(fileparts(fileparts(scriptFile)));
outputRoot = fullfile(examplesRoot, "output");
defaultName = "emission_" + ...
    string(datetime("now", "Format", "yyyyMMdd_HHmmss"));

answers = inputdlg( ...
    {"Emission measurement name", "Operator", "Project", "Comment"}, ...
    "SpectraLab - Measure emitted-light spectrum (emission)", ...
    [1 70; 1 70; 1 70; 3 70], ...
    {char(defaultName), "Example operator", ...
     "SpectraLab emission measurement", ""});
if isempty(answers)
    disp("SpectraLab measurement cancelled. Nothing was saved.");
    return
end

instrumentId = select_spotread_instrument();
if instrumentId == ""
    disp("SpectraLab measurement cancelled. Nothing was saved.");
    return
end

resolutionChoice = questdlg( ...
    "Select spectral resolution for the emission measurement", ...
    "SpectraLab - Emitted-light spectrum resolution", ...
    "Standard", "High resolution", "Cancel", "Standard");
if isempty(resolutionChoice) || strcmp(resolutionChoice, "Cancel")
    disp("SpectraLab measurement cancelled. Nothing was saved.");
    return
end

measurementName = strtrim(string(answers{1}));
operatorName = strtrim(string(answers{2}));
projectName = strtrim(string(answers{3}));
commentLines = strip(string(answers{4}), "right");
measurementComment = strip(strjoin(commentLines, newline));
highResolution = strcmp(resolutionChoice, "High resolution");

[measurement, archive, outputs] = spectralab.measurement.oneShot( ...
    instrumentId, measurementName, fullfile(outputRoot, "archive"), ...
    MeasurementKind="emissive", ...
    HighResolution=highResolution, ...
    Operator=operatorName, Project=projectName, ...
    Comment=measurementComment, ...
    GenerateReport=true, ShowFigure=true, ...
    PNGSpectrumSummary=true); %#ok<ASGLU>

fprintf("SpectraLab emitted-light spectrum saved:\n");
fprintf("  Archive: %s\n", outputs.ArchiveFile);
fprintf("  PDF:     %s\n", outputs.Report.PDFFile);
fprintf("  PNG:     %s\n", outputs.Report.PNGFile);
