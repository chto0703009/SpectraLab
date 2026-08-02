function tests = test_analysis_statusADensity
%TEST_ANALYSIS_STATUSADENSITY Tests for Status A RGB density analysis.

    tests = functiontests(localfunctions);
end


function testReturnsExpectedFields(testCase)

    [reference, sample] = localConstantTransmissionSpectra(0.5);

    result = spectralab.analysis.statusADensity( ...
        reference, ...
        sample);

    verifyTrue(testCase, isstruct(result));

    verifyTrue(testCase, isfield(result, "Red"));
    verifyTrue(testCase, isfield(result, "Green"));
    verifyTrue(testCase, isfield(result, "Blue"));

    verifyTrue(testCase, isfield(result, "DensityRGB"));
    verifyTrue(testCase, isfield(result, "TransmittanceRGB"));
    verifyTrue(testCase, isfield(result, "Standard"));

    verifyEqual(testCase, result.Standard, "Status A");
end


function testChannelResultsContainDensityInformation(testCase)

    [reference, sample] = localConstantTransmissionSpectra(0.5);

    result = spectralab.analysis.statusADensity( ...
        reference, ...
        sample);

    localVerifyChannelStructure(testCase, result.Red);
    localVerifyChannelStructure(testCase, result.Green);
    localVerifyChannelStructure(testCase, result.Blue);
end


function testHalfTransmissionProducesEqualRGBDensities(testCase)
% A spectrally neutral 50% sample must produce the same density in every
% Status A channel, regardless of the shape of the weighting functions.

    [reference, sample] = localConstantTransmissionSpectra(0.5);

    result = spectralab.analysis.statusADensity( ...
        reference, ...
        sample);

    expectedDensity = -log10(0.5);

    verifyEqual(testCase, result.Red.Transmittance, 0.5, ...
        AbsTol=1e-10);

    verifyEqual(testCase, result.Green.Transmittance, 0.5, ...
        AbsTol=1e-10);

    verifyEqual(testCase, result.Blue.Transmittance, 0.5, ...
        AbsTol=1e-10);

    verifyEqual(testCase, result.Red.Density, expectedDensity, ...
        AbsTol=1e-10);

    verifyEqual(testCase, result.Green.Density, expectedDensity, ...
        AbsTol=1e-10);

    verifyEqual(testCase, result.Blue.Density, expectedDensity, ...
        AbsTol=1e-10);
end


function testTenPercentTransmissionProducesDensityOne(testCase)

    [reference, sample] = localConstantTransmissionSpectra(0.1);

    result = spectralab.analysis.statusADensity( ...
        reference, ...
        sample);

    verifyEqual(testCase, result.DensityRGB, [1, 1, 1], ...
        AbsTol=1e-10);

    verifyEqual(testCase, result.TransmittanceRGB, [0.1, 0.1, 0.1], ...
        AbsTol=1e-10);
end


function testIdenticalSpectraProduceZeroDensity(testCase)

    [reference, sample] = localConstantTransmissionSpectra(1.0);

    result = spectralab.analysis.statusADensity( ...
        reference, ...
        sample);

    verifyEqual(testCase, result.DensityRGB, [0, 0, 0], ...
        AbsTol=1e-10);

    verifyEqual(testCase, result.TransmittanceRGB, [1, 1, 1], ...
        AbsTol=1e-10);
end


function testCompactArraysMatchChannelResults(testCase)

    [reference, sample] = localConstantTransmissionSpectra(0.25);

    result = spectralab.analysis.statusADensity( ...
        reference, ...
        sample);

    expectedDensityRGB = [ ...
        result.Red.Density, ...
        result.Green.Density, ...
        result.Blue.Density];

    expectedTransmittanceRGB = [ ...
        result.Red.Transmittance, ...
        result.Green.Transmittance, ...
        result.Blue.Transmittance];

    verifyEqual(testCase, ...
        result.DensityRGB, ...
        expectedDensityRGB, ...
        AbsTol=1e-12);

    verifyEqual(testCase, ...
        result.TransmittanceRGB, ...
        expectedTransmittanceRGB, ...
        AbsTol=1e-12);
end


function testWeightingNamesAreCorrect(testCase)

    [reference, sample] = localConstantTransmissionSpectra(0.5);

    result = spectralab.analysis.statusADensity( ...
        reference, ...
        sample);

    verifyEqual(testCase, ...
        result.Red.WeightingName, ...
        "Status A Red");

    verifyEqual(testCase, ...
        result.Green.WeightingName, ...
        "Status A Green");

    verifyEqual(testCase, ...
        result.Blue.WeightingName, ...
        "Status A Blue");
end


function testDifferentWavelengthGridsAreSupported(testCase)
% The shared weighted-density engine should interpolate before integration.

    reference = struct( ...
        "WavelengthNm", (380:10:730).', ...
        "Value", ones(36, 1));

    sampleWavelengthNm = (380:5:730).';

    sample = struct( ...
        "WavelengthNm", sampleWavelengthNm, ...
        "Value", 0.5 .* ones(size(sampleWavelengthNm)));

    result = spectralab.analysis.statusADensity( ...
        reference, ...
        sample);

    expectedDensity = -log10(0.5);

    verifyEqual(testCase, ...
        result.DensityRGB, ...
        [expectedDensity, expectedDensity, expectedDensity], ...
        AbsTol=1e-10);
end


function testZeroTransmissionProducesInfiniteDensity(testCase)

    [reference, sample] = localConstantTransmissionSpectra(0);

    result = spectralab.analysis.statusADensity( ...
        reference, ...
        sample);

    verifyEqual(testCase, result.TransmittanceRGB, [0, 0, 0]);

    verifyTrue(testCase, isinf(result.Red.Density));
    verifyTrue(testCase, isinf(result.Green.Density));
    verifyTrue(testCase, isinf(result.Blue.Density));
end


	function testSampleAboveReferenceProducesWarning(testCase)

	    [reference, sample] = localConstantTransmissionSpectra(1.1);

	    verifyWarning(testCase, ...
	        @() spectralab.analysis.statusADensity(reference, sample), ...
	        "spectralab:analysis:statusADensity:TransmittanceAboveOne");
	end

function testNoSpectralOverlapProducesError(testCase)

    reference = struct( ...
        "WavelengthNm", [380; 390; 400], ...
        "Value", [1; 1; 1]);

    sample = struct( ...
        "WavelengthNm", [700; 710; 720], ...
        "Value", [0.5; 0.5; 0.5]);

    verifyError(testCase, ...
        @() spectralab.analysis.statusADensity(reference, sample), ...
        "spectralab:core:weightedDensity:NoOverlap");
end


function localVerifyChannelStructure(testCase, channel)

    verifyTrue(testCase, isstruct(channel));

    verifyTrue(testCase, isfield(channel, "Density"));
    verifyTrue(testCase, isfield(channel, "Transmittance"));

    verifyTrue(testCase, ...
        isfield(channel, "ReferenceWeightedValue"));

    verifyTrue(testCase, ...
        isfield(channel, "SampleWeightedValue"));

    verifyTrue(testCase, ...
        isfield(channel, "WavelengthRangeNm"));

    verifyTrue(testCase, ...
        isfield(channel, "WeightingName"));
end


function [reference, sample] = localConstantTransmissionSpectra(transmittance)

    wavelengthNm = (380:10:730).';

    referenceValue = ones(size(wavelengthNm));
    sampleValue = transmittance .* referenceValue;

    reference = struct( ...
        "WavelengthNm", wavelengthNm, ...
        "Value", referenceValue);

    sample = struct( ...
        "WavelengthNm", wavelengthNm, ...
        "Value", sampleValue);
end
	
	
function testResamplingOptionsAreForwardedToAllChannels(testCase)

    wavelengthNm = (400:50:700).';

    reference = struct( ...
        "WavelengthNm", wavelengthNm, ...
        "Value", ones(size(wavelengthNm)));

    sample = struct( ...
        "WavelengthNm", wavelengthNm, ...
        "Value", 0.5 .* ones(size(wavelengthNm)));

    result = spectralab.analysis.statusADensity( ...
        reference, ...
        sample, ...
        Resample=true, ...
        RefinementFactor=4, ...
        InterpolationMethod="pchip");

    verifyTrue(testCase, result.Resampled);
    verifyEqual(testCase, result.RefinementFactor, 4);
    verifyEqual(testCase, result.InterpolationMethod, "pchip");

    verifyTrue(testCase, result.Red.Resampled);
    verifyTrue(testCase, result.Green.Resampled);
    verifyTrue(testCase, result.Blue.Resampled);

    verifyEqual(testCase, result.Red.RefinementFactor, 4);
    verifyEqual(testCase, result.Green.RefinementFactor, 4);
    verifyEqual(testCase, result.Blue.RefinementFactor, 4);

    verifyEqual( ...
        testCase, ...
        result.DensityRGB, ...
        repmat(-log10(0.5), 1, 3), ...
        "AbsTol", 1e-12);

end