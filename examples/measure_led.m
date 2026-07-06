%MEASURE_LED  Measure and plot an LED spectrum with SpectraLab.
%
%   First run startup from the SpectraLab project directory:
%
%       startup
%       measure_led
%
%   Requires ArgyllCMS spotread and a connected supported instrument.

if isempty(which("spectralab.drivers.createInstrument"))
    error("SpectraLab:Example:StartupRequired", ...
        ["ERROR [SPL-002]\n\n" + ...
         "SpectraLab is not on the MATLAB path.\n\n" + ...
         "What to do:\n" + ...
         "1. Change MATLAB current folder to the SpectraLab project directory.\n" + ...
         "2. Run:\n\n" + ...
         "    startup\n" + ...
         "    measure_led"]);
end

inst = spectralab.drivers.createInstrument("spotread");

sess = spectralab.core.Session(inst);
sess = sess.open();
sess = sess.calibrate("Mode", "interactive");

spec = sess.measure("LED spectrum", "Mode", "interactive");

disp(spec.summary());

figure("Name", "SpectraLab LED spectrum");
spec.plot();
