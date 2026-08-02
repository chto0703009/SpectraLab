function tests = test_analysis_xyY
%TEST_ANALYSIS_XYY Tests CIE xyY conversion.

    tests = functiontests(localfunctions);
end


function setupOnce(testCase)

    xyz = struct();
    xyz.Type = "CIE1931XYZ";

    xyz.Processing = struct();
    xyz.Processing.Normalization = "Y100";

    xyz.Result = struct();
    xyz.Result.X = 100.765761;
    xyz.Result.Y = 100.000000;
    xyz.Result.Z = 93.144303;

    testCase.TestData.Xyz = xyz;
end


function testCreatesXyYResult(testCase)

    result = spectralab.analysis.xyY( ...
        testCase.TestData.Xyz);

    verifyEqual(testCase, result.Type, "CIExyY");
    verifyTrue(testCase, isfield(result.Result, "x"));
    verifyTrue(testCase, isfield(result.Result, "y"));
    verifyTrue(testCase, isfield(result.Result, "Y"));
end


function testCalculatesExpectedChromaticity(testCase)

    xyz = testCase.TestData.Xyz;

    result = spectralab.analysis.xyY(xyz);

    denominator = ...
        xyz.Result.X + ...
        xyz.Result.Y + ...
        xyz.Result.Z;

    expectedX = xyz.Result.X / denominator;
    expectedY = xyz.Result.Y / denominator;

    verifyEqual( ...
        testCase, ...
        result.Result.x, ...
        expectedX, ...
        "AbsTol", 1e-12);

    verifyEqual( ...
        testCase, ...
        result.Result.y, ...
        expectedY, ...
        "AbsTol", 1e-12);
end


function testPreservesY(testCase)

    xyz = testCase.TestData.Xyz;

    result = spectralab.analysis.xyY(xyz);

    verifyEqual(testCase, result.Result.Y, xyz.Result.Y);
end


function testPreservesNormalizationMetadata(testCase)

    result = spectralab.analysis.xyY( ...
        testCase.TestData.Xyz);

    verifyEqual( ...
        testCase, ...
        result.Processing.SourceNormalization, ...
        "Y100");
end


function testRejectsMissingField(testCase)

    xyz = testCase.TestData.Xyz;
    xyz.Result = rmfield(xyz.Result, "Z");

    verifyError( ...
        testCase, ...
        @() spectralab.analysis.xyY(xyz), ...
        "spectralab:analysis:xyY:MissingField");
end


function testRejectsUnexpectedType(testCase)

    xyz = testCase.TestData.Xyz;
    xyz.Type = "OtherResult";

    verifyError( ...
        testCase, ...
        @() spectralab.analysis.xyY(xyz), ...
        "spectralab:analysis:xyY:UnexpectedType");
end


function testRejectsZeroTristimulusSum(testCase)

    xyz = testCase.TestData.Xyz;
    xyz.Result.X = 0;
    xyz.Result.Y = 0;
    xyz.Result.Z = 0;

    verifyError( ...
        testCase, ...
        @() spectralab.analysis.xyY(xyz), ...
        "spectralab:analysis:xyY:InvalidTristimulusSum");
end
