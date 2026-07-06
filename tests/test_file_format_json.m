% JSON file format test

inst = spectralab.drivers.createInstrument("mock", "NoiseLevel", 0);
sess = spectralab.core.Session(inst);
sess = sess.open();
sess = sess.calibrate();
spec = sess.measure("JSON test spectrum");

tmp = fullfile(tempdir, "spectralab_v040_test.slab.json");

spectralab.io.saveSpectrum(spec, tmp);
assert(isfile(tmp));
assert(spectralab.io.isSpectraLabFile(tmp));

spec2 = spectralab.io.readSpectrum(tmp);

assert(isa(spec2, "spectralab.core.Spectrum"));
assert(numel(spec.WavelengthNm) == numel(spec2.WavelengthNm));
assert(max(abs(spec.WavelengthNm - spec2.WavelengthNm)) == 0);
assert(max(abs(spec.Power - spec2.Power)) < 1e-12);

fprintf("test_file_format_json OK\n");
