% CSV/TXT export test

inst = spectralab.drivers.createInstrument("mock", "NoiseLevel", 0);
sess = spectralab.core.Session(inst);
sess = sess.open();
sess = sess.calibrate();
spec = sess.measure("Export test spectrum");

csvfile = fullfile(tempdir, "spectralab_v040_export.csv");
txtfile = fullfile(tempdir, "spectralab_v040_export.txt");

spectralab.io.exportCsv(spec, csvfile);
spectralab.io.exportTxt(spec, txtfile);

assert(isfile(csvfile));
assert(isfile(txtfile));

T = readtable(csvfile);
assert(height(T) == numel(spec.WavelengthNm));

txt = fileread(txtfile);
assert(contains(txt, "SpectraLab spectrum"));
assert(contains(txt, "wavelength_nm,power"));

fprintf("test_export_csv_txt OK\n");
