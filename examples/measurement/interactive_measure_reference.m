% interactive_measure_reference
%
% Prepare a legacy interactive reference measurement with an i1Pro family
% instrument. The
% command required to trigger and save the measurement is copied to the
% clipboard. Prefer measure_spectrum for the bounded automatic workflow.

scriptFile = string(mfilename("fullpath"));
examplesRoot = string(fileparts(fileparts(scriptFile)));
outputRoot = fullfile(examplesRoot, "output");
measurementName = "interactive_reference_" + ...
    string(datetime("now", "Format", "yyyyMMdd_HHmmss"));

instrumentId = select_spotread_instrument();
if instrumentId == ""
    disp("SpectraLab interactive measurement cancelled.");
    return
end

inst = spectralab.drivers.createInstrument(instrumentId);
sess = spectralab.core.Session(inst);
sess = sess.withOperator("Example operator");
sess = sess.withProject("SpectraLab interactive example");
sess = sess.withSample(measurementName);
sess = sess.withComment("Interactive reference example");
sess = sess.open();
sess = sess.calibrate("Mode", "interactive");
calibrationSerialNumber = verify_spotread_instrument( ...
    inst, "", "calibration");

command = sprintf([ ...
    'MEAS = sess.measure(measurementName, "Mode", "interactive");\n' ...
    'interactive_save_spectrum\n']);
clipboard("copy", command);
fprintf("Interactive reference measurement is ready.\n");
fprintf("Paste the clipboard command into the Command Window.\n");
