function tests = test_analysis_lab
%TEST_ANALYSIS_LAB Tests measured-reference CIELAB conversion.

    tests = functiontests(localfunctions);
end


function setupOnce(testCase)

    reference = makeXyz(95.047, 100.000, 108.883, "Y100");
    sample = makeXyz(41.24, 21.26, 1.93, "Y100");

    testCase.TestData.Reference = reference;
    testCase.TestData.Sample = sample;
end


function testCreatesLabResult(testCase)

    result = spectralab.analysis.lab( ...
        testCase.TestData.Sample, ...
        testCase.TestData.Reference);

    verifyEqual(testCase, result.Type, "CIELAB");
    verifyTrue(testCase, isfield(result.Result, "L"));
    verifyTrue(testCase, isfield(result.Result, "a"));
    verifyTrue(testCase, isfield(result.Result, "b"));
end


function testReferenceWhiteMapsToNeutralWhite(testCase)

    reference = testCase.TestData.Reference;

    result = spectralab.analysis.lab(reference, reference);

    verifyEqual(testCase, result.Result.L, 100, "AbsTol", 1e-12);
    verifyEqual(testCase, result.Result.a, 0, "AbsTol", 1e-12);
    verifyEqual(testCase, result.Result.b, 0, "AbsTol", 1e-12);
end


function testKnownRedExample(testCase)

    result = spectralab.analysis.lab( ...
        testCase.TestData.Sample, ...
        testCase.TestData.Reference);

    verifyEqual(testCase, result.Result.L, 53.2329, "AbsTol", 1e-3);
    verifyEqual(testCase, result.Result.a, 80.1093, "AbsTol", 1e-3);
    verifyEqual(testCase, result.Result.b, 67.2201, "AbsTol", 1e-3);
end


function testPreservesReferenceWhite(testCase)

    reference = testCase.TestData.Reference;

    result = spectralab.analysis.lab( ...
        testCase.TestData.Sample, ...
        reference);

    verifyEqual(testCase, result.ReferenceWhite.X, reference.Result.X);
    verifyEqual(testCase, result.ReferenceWhite.Y, reference.Result.Y);
    verifyEqual(testCase, result.ReferenceWhite.Z, reference.Result.Z);
end


function testRejectsNormalizationMismatch(testCase)

    sample = testCase.TestData.Sample;
    reference = testCase.TestData.Reference;

    sample.Processing.Normalization = "none";

    verifyError( ...
        testCase, ...
        @() spectralab.analysis.lab(sample, reference), ...
        "spectralab:analysis:lab:NormalizationMismatch");
end


function testRejectsInvalidReferenceWhite(testCase)

    sample = testCase.TestData.Sample;
    reference = testCase.TestData.Reference;

    reference.Result.Y = 0;

    verifyError( ...
        testCase, ...
        @() spectralab.analysis.lab(sample, reference), ...
        "spectralab:analysis:lab:InvalidReferenceWhite");
end


function xyz = makeXyz(X, Y, Z, normalization)

    xyz = struct();
    xyz.Type = "CIE1931XYZ";

    xyz.Processing = struct();
    xyz.Processing.Normalization = normalization;

    xyz.Result = struct();
    xyz.Result.X = X;
    xyz.Result.Y = Y;
    xyz.Result.Z = Z;
end
