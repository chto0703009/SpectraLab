% SpectraLab v0.4 spotread/i1Pro2 example
%
% Requires ArgyllCMS spotread and connected instrument.

startup

inst = spectralab.drivers.createInstrument("spotread");
sess = spectralab.core.Session(inst);

sess = sess.open();
sess = sess.calibrate("Mode", "interactive");

spec = sess.measure("LED spectrum", "Mode", "interactive");

disp(spec.summary());

spectralab.io.saveSpectrum(spec, "led_spectrum.slab.json");

figure;
spec.plot();
