function tests = test_analysis_whiteDensity
%TEST_ANALYSIS_WHITEDENSITY Tests for white-density analysis.

    tests = functiontests(localfunctions);
end


function testReturnsExpectedFields(testCase)

    [reference, sample] = localConstantTransmissionSpectra(0.5);

    result = spectralab.analysis.whiteDensity(reference, sample);

    verifyTrue(testCase, isstruct(result));
    verifyTrue(testCase, isfield(result, "Density"));
    verifyTrue(testCase, isfield(result, "Transmittance"));
    verifyTrue(testCase, isfield(result, "ReferenceWeightedValue"));
    verifyTrue(testCase, isfield(result, "SampleWeightedValue"));
    verifyTrue(testCase, isfield(result, "WavelengthRangeNm"));
    verifyTrue(testCase, isfield(result, "WeightingName"));
end


function testHalfTransmissionProducesExpectedDensity(testCase)

    [reference, sample] = localConstantTransmissionSpectra(0.5);

    result = spectralab.analysis.whiteDensity(reference, sample);

    verifyEqual(testCase, result.Transmittance, 0.5, ...
        AbsTol=1e-10);

    verifyEqual(testCase, result.Density, -log10(0.5), ...
        AbsTol=1e-10);
end


function testTenPercentTransmissionProducesDensityOne(testCase)

    [reference, sample] = localConstantTransmissionSpectra(0.1);

    result = spectralab.analysis.whiteDensity(reference, sample);

    verifyEqual(testCase, result.Transmittance, 0.1, ...
        AbsTol=1e-10);

    verifyEqual(testCase, result.Density, 1, ...
        AbsTol=1e-10);
end


function testIdenticalSpectraProduceZeroDensity(testCase)

    [reference, sample] = localConstantTransmissionSpectra(1);

    result = spectralab.analysis.whiteDensity(reference, sample);

    verifyEqual(testCase, result.Transmittance, 1, ...
        AbsTol=1e-10);

    verifyEqual(testCase, result.Density, 0, ...
        AbsTol=1e-10);
end


function testUsesPhotopicWeighting(testCase)

    [reference, sample] = localConstantTransmissionSpectra(0.5);

    result = spectralab.analysis.whiteDensity(reference, sample);

    verifyEqual(testCase, ...
        result.WeightingName, ...
        "CIE photopic V(lambda)");
end


function testDifferentWavelengthGridsAreSupported(testCase)

    referenceWavelengthNm = (380:10:730).';
    sampleWavelengthNm = (380:5:730).';

    reference = struct( ...
        "WavelengthNm", referenceWavelengthNm, ...
        "Value", ones(size(referenceWavelengthNm)));

    sample = struct( ...
        "WavelengthNm", sampleWavelengthNm, ...
        "Value", 0.25 .* ones(size(sampleWavelengthNm)));

    result = spectralab.analysis.whiteDensity(reference, sample);

    verifyEqual(testCase, result.Transmittance, 0.25, ...
        AbsTol=1e-10);

    verifyEqual(testCase, result.Density, -log10(0.25), ...
        AbsTol=1e-10);
end


function testZeroTransmissionProducesInfiniteDensity(testCase)

    [reference, sample] = localConstantTransmissionSpectra(0);

    result = spectralab.analysis.whiteDensity(reference, sample);

    verifyEqual(testCase, result.Transmittance, 0);
    verifyTrue(testCase, isinf(result.Density));
end


function testSampleAboveReferenceProducesWarning(testCase)

    [reference, sample] = localConstantTransmissionSpectra(1.1);

    verifyWarning(testCase, ...
        @() spectralab.analysis.whiteDensity(reference, sample), ...
        "spectralab:core:weightedDensity:TransmittanceAboveOne");
end


function [reference, sample] = ...
        localConstantTransmissionSpectra(transmittance)

    wavelengthNm = (380:10:730).';

    reference = struct( ...
        "WavelengthNm", wavelengthNm, ...
        "Value", ones(size(wavelengthNm)));

    sample = struct( ...
        "WavelengthNm", wavelengthNm, ...
        "Value", transmittance .* ones(size(wavelengthNm)));
end
	
	
function testResamplingOptionsAreForwarded(testCase)

    wavelengthNm = (400:50:700).';

    reference = struct( ...
        "WavelengthNm", wavelengthNm, ...
        "Value", ones(size(wavelengthNm)));

    sample = struct( ...
        "WavelengthNm", wavelengthNm, ...
        "Value", 0.5 .* ones(size(wavelengthNm)));

    result = spectralab.analysis.whiteDensity( ...
        reference, ...
        sample, ...
        Resample=true, ...
        RefinementFactor=4, ...
        InterpolationMethod="pchip");

    verifyTrue(testCase, result.Resampled);
    verifyEqual(testCase, result.RefinementFactor, 4);
    verifyEqual(testCase, result.InterpolationMethod, "pchip");

    verifyEqual( ...
        testCase, ...
        result.Density, ...
        -log10(0.5), ...
        "AbsTol", 1e-12);

end