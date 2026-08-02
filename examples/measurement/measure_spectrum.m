% measure_spectrum
%
% Measure one spectrum with the bounded Spotread automatic workflow and
% save a trusted MAT archive, registered PDF report and PNG figure below
% examples/output/. Requires ArgyllCMS and a connected i1Pro2.

scriptFile = string(mfilename("fullpath"));
examplesRoot = string(fileparts(fileparts(scriptFile)));
outputRoot = fullfile(examplesRoot, "output");
defaultName = "measurement_" + ...
    string(datetime("now", "Format", "yyyyMMdd_HHmmss"));

answers = inputdlg( ...
    {"Measurement name", "Operator", "Project", "Comment"}, ...
    "SpectraLab - Measure spectrum", ...
    [1 70; 1 70; 1 70; 3 70], ...
    {char(defaultName), "Example operator", ...
     "SpectraLab example measurement", ""});
if isempty(answers)
    disp("SpectraLab measurement cancelled. Nothing was saved.");
    return
end

resolutionChoice = questdlg( ...
    "Select spectral resolution", "SpectraLab - Resolution", ...
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

inst = spectralab.drivers.createInstrument( ...
    "i1Pro2", HighResolution=highResolution);
instrumentCleanup = onCleanup(@() inst.close());
sess = spectralab.core.Session(inst, AudibleFeedback=true);
sess = sess.withOperator(operatorName);
sess = sess.withProject(projectName);
sess = sess.withSample(measurementName);
sess = sess.withComment(measurementComment);
sess = sess.open();
sess = sess.calibrate("Mode", "automatic");
pause(1.0)
measurement = sess.measure(measurementName, "Mode", "automatic");

saveInfo = internal_save_spectrum_outputs( ...
    measurement, measurementName, outputRoot);
sess = sess.close();
clear instrumentCleanup
