function tests = test_spotread_highResolutionCompatibility
%TEST_SPOTREAD_HIGHRESOLUTIONCOMPATIBILITY Physical 109-band fixture tests.

tests = functiontests(localfunctions);
end

function testPhysicalFixtureAndAnalyses(testCase)
fixture = fullfile(fileparts(mfilename("fullpath")), ...
    "fixtures", "spotread_i1pro2_high_resolution.sp");
[wavelength, power, info] = ...
    spectralab.drivers.spotread.Parser.parseSpectrumFile(fixture);

verifyEqual(testCase, numel(power), 109);
verifyEqual(testCase, wavelength([1 end]), [370; 730]);
verifyEqual(testCase, median(diff(wavelength)), 10 / 3, ...
    "AbsTol", 1e-12);
verifyGreaterThan(testCase, min(power), 0);
verifyEqual(testCase, info.samples, 109);

instrument = struct("name", "i1Pro2", "high_resolution", true);
calibration = struct("is_valid", true, "high_resolution", true);
metadata = struct("high_resolution", true);
spec = spectralab.core.Spectrum( ...
    wavelength, power, "Physical high-resolution fixture", ...
    instrument, calibration, metadata, "arbitrary");

xyz = spectralab.analysis.xyz(spec, Normalization="Y100");
xyy = spectralab.analysis.xyY(xyz);
cri = spectralab.analysis.cri(spec, Quiet=true);
values = [xyz.Result.X, xyz.Result.Y, xyz.Result.Z, ...
    xyy.Result.x, xyy.Result.y, cri.Result.CCT, cri.Result.Ra];
verifyTrue(testCase, all(isfinite(values)));
end

function testArchiveRoundTrip(testCase)
fixture = fullfile(fileparts(mfilename("fullpath")), ...
    "fixtures", "spotread_i1pro2_high_resolution.sp");
[wavelength, power] = ...
    spectralab.drivers.spotread.Parser.parseSpectrumFile(fixture);
spec = spectralab.core.Spectrum( ...
    wavelength, power, "High-resolution archive fixture", ...
    struct("name", "i1Pro2", "high_resolution", true), ...
    struct("is_valid", true), ...
    struct("high_resolution", true), ...
    "arbitrary");

archive = spectralab.archive.create(spec);
filename = string(tempname) + ".mat";
cleanup = onCleanup(@() deleteIfExists(filename));
spectralab.archive.save(archive, filename);
restored = spectralab.archive.restore( ...
    spectralab.archive.load(filename));

verifyEqual(testCase, restored.WavelengthNm, wavelength);
verifyEqual(testCase, restored.Power, power);
verifyTrue(testCase, restored.Instrument.HighResolution);
end

function deleteIfExists(filename)
if isfile(filename)
    delete(filename);
end
end
