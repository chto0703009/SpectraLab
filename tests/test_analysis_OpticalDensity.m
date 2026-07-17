function tests = test_analysis_optical_density
%TEST_ANALYSIS_OPTICAL_DENSITY Tests for spectral optical-density analysis.

    tests = functiontests(localfunctions);
end


function testKnownValues(testCase)
    transmittance = [1, 0.1, 0.01];

    actual = spectralab.analysis.opticalDensity(transmittance);
    expected = [0, 1, 2];

    verifyEqual(testCase, actual, expected, "AbsTol", 1e-12);
end


function testPreservesInputShape(testCase)
    transmittance = [1, 0.1; 0.01, 0.001];

    actual = spectralab.analysis.opticalDensity(transmittance);

    verifySize(testCase, actual, size(transmittance));
end


function testZeroUsesDefaultMinimumTransmittance(testCase)
    actual = spectralab.analysis.opticalDensity(0);

    verifyEqual(testCase, actual, 12, "AbsTol", 1e-12);
end


function testCustomMinimumTransmittance(testCase)
    actual = spectralab.analysis.opticalDensity( ...
        [0, 1e-8], ...
        MinimumTransmittance=1e-6);

    expected = [6, 6];

    verifyEqual(testCase, actual, expected, "AbsTol", 1e-12);
end


function testAboveUnityProducesNegativeDensity(testCase)
    testFunction = @() ...
        spectralab.analysis.opticalDensity(2);

    verifyWarning( ...
        testCase, ...
        testFunction, ...
        "spectralab:analysis:opticalDensity:AboveUnity");

    warning("off", ...
        "spectralab:analysis:opticalDensity:AboveUnity");
    cleanup = onCleanup(@() warning("on", ...
        "spectralab:analysis:opticalDensity:AboveUnity"));

    actual = spectralab.analysis.opticalDensity(2);

    verifyLessThan(testCase, actual, 0);

    clear cleanup
end


function testRejectsNegativeTransmittance(testCase)
    testFunction = @() ...
        spectralab.analysis.opticalDensity([1, -0.1]);

    verifyError( ...
        testCase, ...
        testFunction, ...
        "spectralab:analysis:opticalDensity:NegativeTransmittance");
end


function testRejectsEmptyInput(testCase)
    testFunction = @() ...
        spectralab.analysis.opticalDensity([]);

    verifyError( ...
        testCase, ...
        testFunction, ...
        "spectralab:analysis:opticalDensity:EmptyInput");
end


function testRejectsNaN(testCase)
    testFunction = @() ...
        spectralab.analysis.opticalDensity([1, NaN]);

    verifyError( ...
        testCase, ...
        testFunction, ...
        "spectralab:analysis:opticalDensity:NonFiniteInput");
end


function testRejectsInfinity(testCase)
    testFunction = @() ...
        spectralab.analysis.opticalDensity([1, Inf]);

    verifyError( ...
        testCase, ...
        testFunction, ...
        "spectralab:analysis:opticalDensity:NonFiniteInput");
end