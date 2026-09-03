function tests = test_analysis_compareDensityPairs
tests = functiontests(localfunctions);
end

function testDensityIsDerivedFromEachTransmissionPair(testCase)
root = string(fileparts(fileparts(mfilename("fullpath"))));
data = fullfile(root, "examples", "data");
reference = spectralab.archive.load(fullfile(data, "example_reference.mat"), ...
    Quiet=true, Validation="error");
sampleA = spectralab.archive.load(fullfile(data, "example_sample_a.mat"), ...
    Quiet=true, Validation="error");
sampleB = spectralab.archive.load(fullfile(data, "example_sample_b.mat"), ...
    Quiet=true, Validation="error");

actual = spectralab.analysis.compareDensityPairs( ...
    reference, sampleA, reference, sampleB);
transmission = spectralab.analysis.compareTransmissionPairs( ...
    reference, sampleA, reference, sampleB);
expectedA = -log10(transmission.Result.TransmissionA);
expectedB = -log10(transmission.Result.TransmissionB);

verifyEqual(testCase, actual.Result.DensityA, expectedA, "AbsTol", 1e-12);
verifyEqual(testCase, actual.Result.DensityB, expectedB, "AbsTol", 1e-12);
verifyEqual(testCase, actual.Result.Difference, expectedA-expectedB, ...
    "AbsTol", 1e-12);
verifyEqual(testCase, actual.Result.RMSDifference, ...
    sqrt(mean((expectedA-expectedB).^2)), "AbsTol", 1e-12);
end

function testDifferentReferencesAreAccepted(testCase)
root = string(fileparts(fileparts(mfilename("fullpath"))));
data = fullfile(root, "examples", "data");
referenceA = spectralab.archive.load(fullfile(data, "example_reference.mat"), ...
    Quiet=true, Validation="error");
referenceB = spectralab.archive.load(fullfile(data, "example_sample_a.mat"), ...
    Quiet=true, Validation="error");
sample = spectralab.archive.load(fullfile(data, "example_sample_b.mat"), ...
    Quiet=true, Validation="error");

actual = spectralab.analysis.compareDensityPairs( ...
    referenceA, sample, referenceB, sample);

verifyNotEqual(testCase, actual.Result.DensityA, actual.Result.DensityB);
end
