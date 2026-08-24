% measure_emission_series
%
% Measure a user-selected number of emission spectra in one session.
% SpectraLab calibrates initially and
% automatically recalibrates only if Spotread later requires it. Every
% successful measurement is saved before the next begins.

scriptFile = string(mfilename("fullpath"));
examplesRoot = string(fileparts(fileparts(scriptFile)));
outputRoot = fullfile(examplesRoot, "output");
defaultName = "emission_series_" + ...
    string(datetime("now", "Format", "yyyyMMdd_HHmmss"));

answers = inputdlg( ...
    {"Series name", "Number of spectra", "Operator", "Project", "Comment"}, ...
    "SpectraLab - Measure emission series", ...
    [1 70; 1 20; 1 70; 1 70; 3 70], ...
    {char(defaultName), "5", "Example operator", ...
     "SpectraLab emission series", ""});
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
measurementCount = str2double(strtrim(string(answers{2})));
if ~isscalar(measurementCount) || ~isfinite(measurementCount) || ...
        measurementCount < 1 || fix(measurementCount) ~= measurementCount
    error("SpectraLab:Examples:InvalidMeasurementCount", ...
        "Number of spectra must be a positive whole number.");
end
operatorName = strtrim(string(answers{3}));
projectName = strtrim(string(answers{4}));
commentLines = strip(string(answers{5}), "right");
measurementComment = strip(strjoin(commentLines, newline));
highResolution = strcmp(resolutionChoice, "High resolution");

inst = spectralab.drivers.createInstrument( ...
    instrumentId, MeasurementKind="emissive", ...
    HighResolution=highResolution, ...
    PlacementConfirmation=@spectralab.ui.confirmInstrumentPlacement);
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
        measurement, measurementName, outputRoot, ...
        OpenPDF=false, PNGInformation=true);
end

sess = sess.close();
clear instrumentCleanup
fprintf("SpectraLab series completed: %d measurements saved.\n", ...
    measurementCount);
