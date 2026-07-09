function test_archive_roundtrip()
%TEST_ARCHIVE_ROUNDTRIP Verify Spectrum -> Archive -> Spectrum.

wavelength = (400:10:700)';
power = linspace(0.1, 1.0, numel(wavelength))';

spec1 = spectralab.core.Spectrum( ...
    wavelength, ...
    power, ...
    "Archive round-trip test", ...
    [], [], [], ...
    "arbitrary");

archive = spectralab.archive.create(spec1);

spec2 = spectralab.archive.restore(archive);

assert(isequal(spec1.Label, spec2.Label));
assert(isequal(spec1.WavelengthNm, spec2.WavelengthNm));
assert(isequal(spec1.Power, spec2.Power));
assert(isequal(spec1.PowerUnit, spec2.PowerUnit));

fprintf("test_archive_roundtrip PASS\n");

end