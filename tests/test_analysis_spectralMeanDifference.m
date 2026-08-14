function tests = test_analysis_spectralMeanDifference
%TEST_ANALYSIS_SPECTRALMEANDIFFERENCE Derived and diagnostic pair analyses.
tests = functiontests(localfunctions);
end

function testExactMeanCreatesValidTraceableArchive(testCase)
a = makeArchive([400; 500; 600], [2; 4; 8], "A");
b = makeArchive([400; 500; 600], [4; 8; 10], "B");

analysis = spectralab.analysis.spectralMean(a, b, ...
    ResultName="Mean A B", SourceFiles=["a.mat", "b.mat"]);

verifyEqual(testCase, analysis.Result.Value, [3; 6; 9]);
verifyEqual(testCase, analysis.Definition.AnalysisId, "ANL-009");
verifyEqual(testCase, [analysis.Sources.Filename], ["a.mat", "b.mat"]);
derived = analysis.Result.DerivedArchive;
verifyTrue(testCase, spectralab.archive.validate(derived).IsValid);
verifyEqual(testCase, derived.Measurement.Value, [3; 6; 9]);
verifyEqual(testCase, derived.Derivation.Definition.AnalysisId, "ANL-009");
verifyEqual(testCase, [derived.Derivation.Sources.UUID], ...
    [string(a.Identity.UUID), string(b.Identity.UUID)]);
end

function testDifferenceIsSignedAndNotArchivableResult(testCase)
a = makeArchive([400; 500; 600], [2; 9; 5], "A");
b = makeArchive([400; 500; 600], [4; 3; 5], "B");

analysis = spectralab.analysis.spectralDifference(a, b, ...
    SourceFiles=["a.mat", "b.mat"]);

verifyEqual(testCase, analysis.Result.Value, [-2; 6; 0]);
verifyEqual(testCase, analysis.Result.RMSDifference, sqrt(40 / 3), ...
    AbsTol=1e-12);
verifyEqual(testCase, analysis.Result.MaximumAbsoluteDifference, 6);
verifyEqual(testCase, analysis.Definition.Expression, ...
    "D(lambda) = A(lambda) - B(lambda)");
verifyFalse(testCase, isfield(analysis.Result, "DerivedArchive"));
verifyEqual(testCase, [analysis.Sources.Role], ...
    ["Minuend (A)", "Subtrahend (B)"]);
end

function testMeanAcceptsArchiveList(testCase)
a = makeArchive([400; 500; 600], [1; 4; 7], "A");
b = makeArchive([400; 500; 600], [2; 5; 8], "B");
c = makeArchive([400; 500; 600], [3; 6; 9], "C");

analysis = spectralab.analysis.spectralMean([a, b, c], ...
    ResultName="Mean A B C", SourceFiles=["a.mat", "b.mat", "c.mat"]);

verifyEqual(testCase, analysis.Result.Value, [2; 5; 8]);
verifyEqual(testCase, analysis.Result.StandardDeviation, [1; 1; 1]);
verifyEqual(testCase, analysis.Result.RelativeStandardDeviationPercent, ...
    [50; 20; 12.5], AbsTol=1e-12);
verifyEqual(testCase, analysis.Result.MeanRelativeStandardDeviationPercent, ...
    mean([50; 20; 12.5]), AbsTol=1e-12);
verifyEqual(testCase, analysis.Parameters.SourceCount, 3);
verifyEqual(testCase, numel(analysis.Sources), 3);
verifyEqual(testCase, [analysis.Sources.Filename], ...
    ["a.mat", "b.mat", "c.mat"]);
verifyTrue(testCase, ...
    spectralab.archive.validate(analysis.Result.DerivedArchive).IsValid);
end

function testMeanPreservesCommonMeasurementKind(testCase)
a = makeArchive([400; 500], [1; 2], "A");
b = makeArchive([400; 500], [2; 3], "B");
a.Measurement.Context.Kind = "emissive";
b.Measurement.Context.Kind = "emissive";
a = refreshContentHash(a);
b = refreshContentHash(b);

analysis = spectralab.analysis.spectralMean(a, b);

verifyEqual(testCase, ...
    analysis.Result.DerivedArchive.Measurement.Context.Kind, "emissive");
end

function testMeanDoesNotInventMixedMeasurementKind(testCase)
a = makeArchive([400; 500], [1; 2], "A");
b = makeArchive([400; 500], [2; 3], "B");
a.Measurement.Context.Kind = "emissive";
b.Measurement.Context.Kind = "reflectance";
a = refreshContentHash(a);
b = refreshContentHash(b);

analysis = spectralab.analysis.spectralMean(a, b);

verifyEqual(testCase, ...
    analysis.Result.DerivedArchive.Measurement.Context.Kind, "");
end

function testMismatchRequiresExplicitResampling(testCase)
a = makeArchive([400; 500; 600], [2; 4; 6], "A");
b = makeArchive([400; 450; 500; 550; 600], [1; 2; 3; 4; 5], "B");

verifyError(testCase, @() spectralab.analysis.spectralMean(a, b), ...
    "SpectraLab:Analysis:WavelengthMismatch");
analysis = spectralab.analysis.spectralDifference(a, b, Resample=true);
verifyEqual(testCase, analysis.Parameters.Alignment, "Interpolated");
verifyEqual(testCase, analysis.Result.WavelengthNm([1 end]), [400; 600]);
end

function testRejectsDifferentUnits(testCase)
a = makeArchive([400; 500], [1; 2], "A", "arbitrary");
b = makeArchive([400; 500], [1; 2], "B", "W/nm");
verifyError(testCase, @() spectralab.analysis.spectralDifference(a, b), ...
    "SpectraLab:Analysis:UnitMismatch");
end

function archive = makeArchive(wavelength, value, name, unit)
if nargin < 4
    unit = "arbitrary";
end
spec = spectralab.core.Spectrum(wavelength, value, name, ...
    struct("Name", "Test instrument"), struct(), ...
    struct("Operator", "Test"), unit);
archive = spectralab.archive.create(spec);
end

function archive = refreshContentHash(archive)
payload = struct("Measurement", archive.Measurement, ...
    "Instrument", archive.Instrument, "Quality", archive.Quality);
archive.Identity.ContentHash = spectralab.archive.contentHash(payload);
end
