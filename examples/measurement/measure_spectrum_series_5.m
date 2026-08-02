% measure_spectrum_series_5
%
% Measure five spectra in one session. SpectraLab calibrates initially and
% automatically recalibrates only if Spotread later requires it. Every
% successful measurement is saved before the next begins.

scriptFile = string(mfilename("fullpath"));
examplesRoot = string(fileparts(fileparts(scriptFile)));
outputRoot = fullfile(examplesRoot, "output");
measurementCount = 5;
defaultName = "series_" + ...
    string(datetime("now", "Format", "yyyyMMdd_HHmmss"));

answers = inputdlg( ...
    {"Series name", "Operator", "Project", "Comment"}, ...
    "SpectraLab - Measure five spectra", ...
    [1 70; 1 70; 1 70; 3 70], ...
    {char(defaultName), "Example operator", ...
     "SpectraLab example measurement", ""});
if isempty(answers)
    disp("SpectraLab measurement series cancelled. Nothing was saved.");
    return
end

instrumentId = select_spotread_instrument();
if instrumentId == ""
    disp("SpectraLab measurement series cancelled. Nothing was saved.");
    return
end

resolutionChoice = questdlg( ...
    "Select spectral resolution", "SpectraLab - Resolution", ...
    "Standard", "High resolution", "Cancel", "Standard");
if isempty(resolutionChoice) || strcmp(resolutionChoice, "Cancel")
    disp("SpectraLab measurement series cancelled. Nothing was saved.");
    return
end

seriesName = strtrim(string(answers{1}));
operatorName = strtrim(string(answers{2}));
projectName = strtrim(string(answers{3}));
commentLines = strip(string(answers{4}), "right");
measurementComment = strip(strjoin(commentLines, newline));
highResolution = strcmp(resolutionChoice, "High resolution");

inst = spectralab.drivers.createInstrument( ...
    instrumentId, HighResolution=highResolution);
instrumentCleanup = onCleanup(@() inst.close());
sess = spectralab.core.Session(inst, AudibleFeedback=true);
sess = sess.withOperator(operatorName);
sess = sess.withProject(projectName);
sess = sess.withComment(measurementComment);
sess = sess.open();
sess = sess.calibrate("Mode", "automatic");
calibrationSerialNumber = verify_spotread_instrument( ...
    inst, "", "calibration");
pause(1.0)

for measurementIndex = 1:measurementCount
    measurementName = sprintf("%s_%02d", seriesName, measurementIndex);
    sess = sess.withSample(measurementName);
    fprintf("Measurement %d of %d: %s\n", ...
        measurementIndex, measurementCount, measurementName);
    measurement = sess.measure(measurementName, "Mode", "automatic");
    verify_spotread_instrument( ...
        inst, ...
        calibrationSerialNumber, ...
        "measurement " + string(measurementIndex));
    internal_save_spectrum_outputs( ...
        measurement, measurementName, outputRoot, OpenPDF=false);
end

sess = sess.close();
clear instrumentCleanup
fprintf("SpectraLab series completed: %d measurements saved.\n", ...
    measurementCount);
