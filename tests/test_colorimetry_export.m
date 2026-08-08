function tests = test_colorimetry_export
%TEST_COLORIMETRY_EXPORT Verify one central result drives every export.

tests = functiontests(localfunctions);
end

function testInstrumentReportedPointExportsConsistentValues(testCase)
spec = makeReflectanceSpectrum();
dataset = spectralab.analysis.colorimetry(spec);

verifyEqual(testCase, dataset.SampleCount, 1);
verifyEqual(testCase, dataset.Samples.Colorimetry.Status, "canonical");
verifyEqual(testCase, dataset.Samples.InstrumentReported.XYZ.Y, 56.724391, ...
    "AbsTol", 1e-12);
verifyEqual(testCase, dataset.Samples.InstrumentReported.Lab.b, 84.210804, ...
    "AbsTol", 1e-12);
verifyEqual(testCase, dataset.Samples.Verification.Status, "informational");

folder = string(tempname);
mkdir(folder);
cleanup = onCleanup(@() rmdir(folder, "s")); %#ok<NASGU>
files = spectralab.io.exportColorimetry(dataset, folder, BaseName="H4");

for filename = struct2cell(files).'
    verifyTrue(testCase, isfile(filename{1}));
end
json = jsondecode(fileread(files.JSON));
verifyEqual(testCase, json.Samples.Colorimetry.XYZ.Y, ...
    dataset.Samples.Colorimetry.XYZ.Y, "AbsTol", 1e-12);
verifyEqual(testCase, json.Samples.Spectrum.WavelengthNm(:), ...
    dataset.Samples.Spectrum.WavelengthNm(:));
verifyEqual(testCase, json.Samples.Spectrum.Value(:), ...
    dataset.Samples.Spectrum.Value(:));
verifyTrue(testCase, contains(string(fileread(files.CSVColorimetry)), "H4"));
verifyEqual(testCase, numel(splitlines(strtrim(fileread(files.CSVColorimetry)))), 2);
verifyEqual(testCase, numel(splitlines(strtrim(fileread(files.CSVSpectral)))), 37);
verifyTrue(testCase, contains(string(fileread(files.CGATS)), "H4"));
end

function testCanonicalReflectanceCalculationUsesSuppliedIlluminant(testCase)
spec = makeReflectanceSpectrum();
illuminant = spectralab.core.Spectrum( ...
    (380:10:730).', ones(36,1), "Equal energy test illuminant", ...
    struct(), struct(), struct(), "relative spectral power");

dataset = spectralab.analysis.colorimetry(spec, Illuminant=illuminant);
sample = dataset.Samples;
verifyEqual(testCase, sample.Colorimetry.Status, "canonical");
verifyTrue(testCase, isfinite(sample.Colorimetry.Lab.L));
verifyTrue(testCase, isfinite(sample.Colorimetry.Lab.a));
verifyTrue(testCase, isfinite(sample.Colorimetry.Lab.b));
verifyEqual(testCase, sample.Colorimetry.ReferenceWhiteXYZ.Y, 100, ...
    "AbsTol", 1e-10);
verifyLessThan(testCase, sample.Colorimetry.XYZ.Y, 100);
end

function testRejectsUnsupportedObserver(testCase)
spec = makeReflectanceSpectrum();
verifyError(testCase, @() spectralab.analysis.colorimetry( ...
    spec, Observer="CIE1964_10"), "MATLAB:validators:mustBeMember");
end

function testArchivePreservesReflectanceContext(testCase)
spec = makeReflectanceSpectrum();
archive = spectralab.archive.create(spec);
verifyEqual(testCase, archive.Measurement.Context.Kind, "reflectance");
verifyEqual(testCase, archive.Measurement.Context.SignalQuantity, ...
    "spectral reflectance factor");
verifyTrue(testCase, archive.Measurement.Context. ...
    InstrumentReportedColorimetry.available);

restored = spectralab.archive.restore(archive);
verifyTrue(testCase, restored.Metadata.spotread_colorimetry.available);
end

function testRefusesAllExportsWhenOneTargetAlreadyExists(testCase)
dataset = spectralab.analysis.colorimetry(makeReflectanceSpectrum());
folder = string(tempname);
mkdir(folder);
cleanup = onCleanup(@() rmdir(folder, "s")); %#ok<NASGU>
cgatsFile = fullfile(folder, "H4_colorimetry.cgats");
fid = fopen(cgatsFile, "w");
fprintf(fid, "existing");
fclose(fid);

verifyError(testCase, @() spectralab.io.exportColorimetry( ...
    dataset, folder, BaseName="H4", Formats=["json" "cgats"]), ...
    "SpectraLab:Colorimetry:ExportFileExists");
verifyFalse(testCase, isfile(fullfile(folder, "H4_colorimetry.json")));
verifyEqual(testCase, string(fileread(cgatsFile)), "existing");
end

function spec = makeReflectanceSpectrum()
wavelength = (380:10:730).';
reflectance = linspace(4, 74, numel(wavelength)).';
metadata = struct();
metadata.measurement_kind = "reflectance";
metadata.signal_quantity = "spectral reflectance factor";
metadata.spotread_options = "-s";
metadata.spotread_colorimetry = struct( ...
    "available", true, ...
    "xyz", [55.309789 56.724391 5.550868], ...
    "lab", [80.024327 1.547991 84.210804], ...
    "illuminant", "D50", ...
    "observer", "1931_2", ...
    "source", "spotread Result is XYZ");
spec = spectralab.core.Spectrum(wavelength, reflectance, "H4", ...
    struct("Name", "i1Pro2"), struct(), metadata, ...
    "relative reflectance (%)");
end
