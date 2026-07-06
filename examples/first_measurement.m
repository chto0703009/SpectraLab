% SpectraLab v0.4 first measurement example

startup

inst = spectralab.drivers.createInstrument("mock");
sess = spectralab.core.Session(inst);

sess = sess.open();
sess = sess.calibrate("Mode", "interactive");

spec = sess.measure("First mock spectrum");

disp(spec.summary());

figure;
spec.plot();

spectralab.io.saveSpectrum(spec, "first_mock_spectrum.slab.json");
