% Spotread parser fixture tests

thisFile = mfilename("fullpath");
thisDir = fileparts(thisFile);
base = fullfile(thisDir, "fixtures");

txt1 = fileread(fullfile(base, "spotread_simple_spectrum.txt"));
[wl1, p1, info1] = spectralab.drivers.spotread.Parser.parseSpectrum(txt1);
assert(numel(wl1) == 5);
assert(wl1(1) == 380);
assert(p1(3) == 0.15);
assert(info1.samples == 5);

txt2 = fileread(fullfile(base, "spotread_with_noise_text.txt"));
[wl2, p2, info2] = spectralab.drivers.spotread.Parser.parseSpectrum(txt2);
assert(numel(wl2) >= 5);
assert(wl2(1) == 380);
assert(info2.samples == numel(wl2));


txt3 = fileread(fullfile(base, "spotread_argyll_spectrum_block.txt"));
[wl3, p3, info3] = spectralab.drivers.spotread.Parser.parseSpectrum(txt3);
assert(numel(wl3) == 36);
assert(abs(wl3(1) - 380) < 1e-12);
assert(abs(wl3(end) - 730) < 1e-12);
assert(abs(p3(end) - 0.00117158) < 1e-12);
assert(contains(info3.note, "ArgyllCMS"));


txtBad = fileread(fullfile(base, "spotread_bad_spectrum.txt"));
failed = false;
try
    spectralab.drivers.spotread.Parser.parseSpectrum(txtBad);
catch ME
    failed = strcmp(ME.identifier, "SpectraLab:Spotread:ParseFailed");
end
assert(failed);

ok = spectralab.drivers.spotread.Parser.calibrationSucceeded("Calibration OK", 0);
assert(ok);

bad = spectralab.drivers.spotread.Parser.calibrationSucceeded("Instrument initialisation failed", 255);
assert(~bad);

spFile = fullfile(base, "spotread_i1pro2_measurement_complete.sp");
[wlFile, powerFile, fileInfo] = ...
    spectralab.drivers.spotread.Parser.parseSpectrumFile(spFile);
assert(numel(powerFile) == 36);
assert(wlFile(1) == 380);
assert(wlFile(end) == 730);
assert(abs(max(powerFile) - 277.8154) < 1e-12);
assert(fileInfo.format == "Argyll SPECT");

fprintf("test_spotread_parser_fixtures OK\n");
