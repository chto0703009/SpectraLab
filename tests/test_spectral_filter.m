function tests = test_spectral_filter
%TEST_SPECTRAL_FILTER Tests for spectralab.core.SpectralFilter.

    tests = functiontests(localfunctions);
end


function testCreatesTabulatedFilter(testCase)

    wavelength = [400 500 600];
    value = [0.1 0.8 0.2];

    filter = spectralab.core.SpectralFilter.fromTable( ...
        wavelength, ...
        value, ...
        Name="Test table");

    verifyEqual(testCase, filter.Name, "Test table");
    verifyEqual(testCase, filter.Representation, "table");
    verifyEqual(testCase, filter.RangeNm, [400 600]);
    verifyEqual(testCase, filter.WavelengthNm, wavelength(:));
    verifyEqual(testCase, filter.Value, value(:));
end


function testEvaluatesTabulatedFilter(testCase)

    filter = spectralab.core.SpectralFilter.fromTable( ...
        [400 500 600], ...
        [0 1 0]);

    actual = filter.evaluate([450 500 550]);

    verifyEqual(testCase, actual, [0.5 1.0 0.5], "AbsTol", 1e-12);
end


function testCreatesFunctionFilter(testCase)

    filter = spectralab.core.SpectralFilter.fromFunction( ...
        @(lambda) lambda ./ 1000, ...
        [400 700], ...
        Name="Analytical");

    verifyEqual(testCase, filter.Name, "Analytical");
    verifyEqual(testCase, filter.Representation, "function");
    verifyEqual(testCase, filter.RangeNm, [400 700]);
end


function testEvaluatesFunctionFilter(testCase)

    filter = spectralab.core.SpectralFilter.fromFunction( ...
        @(lambda) lambda ./ 1000, ...
        [400 700]);

    actual = filter.evaluate([400 550 700]);

    verifyEqual(testCase, actual, [0.4 0.55 0.7], "AbsTol", 1e-12);
end


function testPreservesInputShape(testCase)

    filter = spectralab.core.SpectralFilter.fromFunction( ...
        @(lambda) lambda .* 0 + 1, ...
        [400 700]);

    columnValue = filter.evaluate([400; 500; 600]);

    verifySize(testCase, columnValue, [3 1]);
end


function testSupportsRange(testCase)

    filter = spectralab.core.SpectralFilter.fromTable( ...
        [400 500 600], ...
        [0 1 0]);

    verifyTrue(testCase, filter.supportsRange([420 580]));
    verifyFalse(testCase, filter.supportsRange([380 580]));
end


function testRejectsEvaluationOutsideRange(testCase)

    filter = spectralab.core.SpectralFilter.fromTable( ...
        [400 500 600], ...
        [0 1 0]);

    verifyError( ...
        testCase, ...
        @() filter.evaluate([390 500]), ...
        "spectralab:core:SpectralFilter:OutsideRange");
end


function testRejectsSizeMismatch(testCase)

    verifyError( ...
        testCase, ...
        @() spectralab.core.SpectralFilter.fromTable( ...
            [400 500 600], ...
            [0 1]), ...
        "spectralab:core:SpectralFilter:SizeMismatch");
end


function testRejectsUnsortedWavelength(testCase)

    verifyError( ...
        testCase, ...
        @() spectralab.core.SpectralFilter.fromTable( ...
            [400 600 500], ...
            [0 1 0]), ...
        "spectralab:core:SpectralFilter:WavelengthNotIncreasing");
end


function testRejectsInvalidFunctionOutput(testCase)

    verifyError( ...
        testCase, ...
        @() spectralab.core.SpectralFilter.fromFunction( ...
            @(lambda) "invalid", ...
            [400 700]), ...
        "spectralab:core:SpectralFilter:InvalidFunctionOutput");
end
