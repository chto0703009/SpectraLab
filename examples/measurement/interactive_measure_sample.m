% interactive_measure_sample
%
% Prepare a legacy interactive sample measurement with an i1Pro2. The
% command required to trigger and save the measurement is copied to the
% clipboard. Prefer measure_spectrum for the bounded automatic workflow.

scriptFile = string(mfilename("fullpath"));
examplesRoot = string(fileparts(fileparts(scriptFile)));
outputRoot = fullfile(examplesRoot, "output");
measurementName = "interactive_sample_" + ...
    string(datetime("now", "Format", "yyyyMMdd_HHmmss"));

inst = spectralab.drivers.createInstrument("i1Pro2");
sess = spectralab.core.Session(inst);
sess = sess.withOperator("Example operator");
sess = sess.withProject("SpectraLab interactive example");
sess = sess.withSample(measurementName);
sess = sess.withComment("Interactive sample example");
sess = sess.open();
sess = sess.calibrate("Mode", "interactive");

command = sprintf([ ...
    'MEAS = sess.measure(measurementName, "Mode", "interactive");\n' ...
    'interactive_save_spectrum\n']);
clipboard("copy", command);
fprintf("Interactive sample measurement is ready.\n");
fprintf("Paste the clipboard command into the Command Window.\n");
