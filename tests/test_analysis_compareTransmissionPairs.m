function tests = test_analysis_compareTransmissionPairs
tests = functiontests(localfunctions);
end

function testComparesIndependentPairs(testCase)
root = string(fileparts(fileparts(mfilename("fullpath"))));
data = fullfile(root, "examples", "data");
reference = spectralab.archive.load(fullfile(data, "example_reference.mat"), ...
    Quiet=true, Validation="error");
sampleA = spectralab.archive.load(fullfile(data, "example_sample_a.mat"), ...
    Quiet=true, Validation="error");
sampleB = spectralab.archive.load(fullfile(data, "example_sample_b.mat"), ...
    Quiet=true, Validation="error");

actual = spectralab.analysis.compareTransmissionPairs( ...
    reference, sampleA, reference, sampleB);
expectedA = spectralab.analysis.transmission(reference, sampleA);
expectedB = spectralab.analysis.transmission(reference, sampleB);

verifyEqual(testCase, actual.Result.TransmissionA, ...
    expectedA.Result.Value, "AbsTol", 1e-12);
verifyEqual(testCase, actual.Result.TransmissionB, ...
    expectedB.Result.Value, "AbsTol", 1e-12);
verifyEqual(testCase, actual.Result.Difference, ...
    expectedA.Result.Value - expectedB.Result.Value, "AbsTol", 1e-12);
verifyEqual(testCase, actual.Parameters.Alignment, "Exact");
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

actual = spectralab.analysis.compareTransmissionPairs( ...
    referenceA, sample, referenceB, sample);

verifyNotEqual(testCase, actual.Result.TransmissionA, ...
    actual.Result.TransmissionB);
end
