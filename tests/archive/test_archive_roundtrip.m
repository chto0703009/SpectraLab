function test_archive_roundtrip()
%TEST_ARCHIVE_ROUNDTRIP Verify Spectrum -> Archive -> save -> load -> Spectrum.

wavelength = (400:10:700)';
power = linspace(0.1, 1.0, numel(wavelength))';

spec1 = spectralab.core.Spectrum( ...
    wavelength, ...
    power, ...
    "Archive round-trip test", ...
    [], [], [], ...
    "arbitrary");

archive1 = spectralab.archive.create(spec1);

tmp = [tempname ".mat"];
cleanup = onCleanup(@() localDeleteIfExists(tmp));

spectralab.archive.save(archive1, tmp);
archive2 = spectralab.archive.load(tmp);

assert(archive1.Identity.ContentHash == archive2.Identity.ContentHash)

spec2 = spectralab.archive.restore(archive2);

assert(all(spec1.WavelengthNm == spec2.WavelengthNm))
assert(all(spec1.Power == spec2.Power))
assert(spec1.Label == spec2.Label)

disp("PASS: archive round-trip")

end

function localDeleteIfExists(filename)
if exist(filename, "file")
    delete(filename);
end
end