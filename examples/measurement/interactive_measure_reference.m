% interactive_measure_reference
%
% Prepare a legacy interactive reference measurement with an i1Pro2. The
% command required to trigger and save the measurement is copied to the
% clipboard. Prefer measure_spectrum for the bounded automatic workflow.

scriptFile = string(mfilename("fullpath"));
examplesRoot = string(fileparts(fileparts(scriptFile)));
outputRoot = fullfile(examplesRoot, "output");
measurementName = "interactive_reference_" + ...
    string(datetime("now", "Format", "yyyyMMdd_HHmmss"));

inst = spectralab.drivers.createInstrument("i1Pro2");
sess = spectralab.core.Session(inst);
sess = sess.withOperator("Example operator");
sess = sess.withProject("SpectraLab interactive example");
sess = sess.withSample(measurementName);
sess = sess.withComment("Interactive reference example");
sess = sess.open();
sess = sess.calibrate("Mode", "interactive");

command = sprintf([ ...
    'MEAS = sess.measure(measurementName, "Mode", "interactive");\n' ...
    'interactive_save_spectrum\n']);
clipboard("copy", command);
fprintf("Interactive reference measurement is ready.\n");
fprintf("Paste the clipboard command into the Command Window.\n");
