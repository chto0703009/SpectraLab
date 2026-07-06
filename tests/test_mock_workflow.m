% Mock workflow integration test

inst = spectralab.drivers.createInstrument("mock", "NoiseLevel", 0, "Scale", 1);
sess = spectralab.core.Session(inst);

r0 = sess.measureResult("Before open");
assert(~r0.Success);

sess = sess.open();

r1 = sess.measureResult("Before calibration");
assert(~r1.Success);

sess = sess.calibrate("interactive");

r2 = sess.measureResult("After calibration", "interactive");
assert(r2.Success);
assert(r2.Spectrum.integratedPower() > 0);

labels = ["One", "Two", "Three"];
collection = sess.measureMany(labels);
assert(collection.count() == 3);

% Mode syntax regression tests
sess2 = spectralab.core.Session(spectralab.drivers.createInstrument("mock", "NoiseLevel", 0));
sess2 = sess2.open();
sess2 = sess2.calibrate("Mode", "interactive");
spec2 = sess2.measure("Mode syntax spectrum", "Mode", "interactive");
assert(isa(spec2, "spectralab.core.Spectrum"));

failed = false;
try
    sess2.measure("Automatic mode", "Mode", "automatic");
catch ME
    failed = strcmp(ME.identifier, "SpectraLab:Session:AutomaticModeUnsupported");
end
assert(failed);

fprintf("test_mock_workflow OK\n");
