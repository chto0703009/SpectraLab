function tests = test_analysis_transmissionDensity
%TEST_ANALYSIS_TRANSMISSIONDENSITY
% Tests for spectralab.analysis.transmissionDensity.

    tests = functiontests(localfunctions);
end


function testIdenticalSignalsGiveZeroDensity(testCase)

    wavelengthNm = (400:10:700).';
    reference = makeArchive(wavelengthNm, ones(size(wavelengthNm)));
    sample = makeArchive(wavelengthNm, ones(size(wavelengthNm)));
    filter = makeFilter(wavelengthNm, ones(size(wavelengthNm)));

    result = spectralab.analysis.transmissionDensity( ...
        reference, sample, filter, Resample=false);

    verifyEqual(testCase, result.Result.EffectiveTransmission, 1, AbsTol=1e-12);
    verifyEqual(testCase, result.Result.Density, 0, AbsTol=1e-12);
    verifyEqual(testCase, result.Provenance.Resampled, false);
end


function testHalfTransmissionProducesExpectedDensity(testCase)

    wavelengthNm = (400:10:700).';
    reference = makeArchive(wavelengthNm, ones(size(wavelengthNm)));
    sample = makeArchive(wavelengthNm, 0.5 .* ones(size(wavelengthNm)));
    filter = makeFilter(wavelengthNm, ones(size(wavelengthNm)));

    result = spectralab.analysis.transmissionDensity( ...
        reference, sample, filter, Resample=false);

    verifyEqual(testCase, result.Result.EffectiveTransmission, 0.5, AbsTol=1e-12);
    verifyEqual(testCase, result.Result.Density, -log10(0.5), AbsTol=1e-12);
end


function testTenPercentTransmissionProducesDensityOne(testCase)

    wavelengthNm = (400:10:700).';
    reference = makeArchive(wavelengthNm, ones(size(wavelengthNm)));
    sample = makeArchive(wavelengthNm, 0.1 .* ones(size(wavelengthNm)));
    filter = makeFilter(wavelengthNm, ones(size(wavelengthNm)));

    result = spectralab.analysis.transmissionDensity( ...
        reference, sample, filter, Resample=false);

    verifyEqual(testCase, result.Result.EffectiveTransmission, 0.1, AbsTol=1e-12);
    verifyEqual(testCase, result.Result.Density, 1, AbsTol=1e-12);
end


function testZeroTransmissionProducesInfiniteDensity(testCase)

    wavelengthNm = (400:10:700).';
    reference = makeArchive(wavelengthNm, ones(size(wavelengthNm)));
    sample = makeArchive(wavelengthNm, zeros(size(wavelengthNm)));
    filter = makeFilter(wavelengthNm, ones(size(wavelengthNm)));

    result = spectralab.analysis.transmissionDensity( ...
        reference, sample, filter, Resample=false);

    verifyEqual(testCase, result.Result.EffectiveTransmission, 0, AbsTol=1e-12);
    verifyTrue(testCase, isinf(result.Result.Density));
    verifyGreaterThan(testCase, result.Result.Density, 0);
end


function testWeightingFilterAffectsEffectiveTransmission(testCase)

    wavelengthNm = [400; 500; 600; 700];
    reference = makeArchive(wavelengthNm, [1; 1; 1; 1]);
    sample = makeArchive(wavelengthNm, [0.2; 0.2; 0.8; 0.8]);
    filter = makeFilter(wavelengthNm, [0; 0; 1; 1]);

    result = spectralab.analysis.transmissionDensity( ...
        reference, sample, filter, Resample=false);

    verifyGreaterThan(testCase, result.Result.EffectiveTransmission, 0.7);
    verifyLessThan(testCase, result.Result.EffectiveTransmission, 0.9);
end


function testIdenticalGridsAreRefinedWhenResamplingEnabled(testCase)

    wavelengthNm = (400:20:700).';
    reference = makeArchive(wavelengthNm, ones(size(wavelengthNm)));
    sample = makeArchive(wavelengthNm, 0.5 .* ones(size(wavelengthNm)));
    filter = makeFilter(wavelengthNm, ones(size(wavelengthNm)));

    result = spectralab.analysis.transmissionDensity( ...
        reference, sample, filter, ...
        Resample=true, ...
        RefinementFactor=4, ...
        InterpolationMethod="pchip");

    verifyEqual(testCase, result.Provenance.Resampled, true);
    verifyGreaterThan(testCase, numel(result.Result.WavelengthNm), numel(wavelengthNm));
    verifyEqual(testCase, result.Result.Density, -log10(0.5), AbsTol=1e-10);
end


function testExactModePreservesMeasuredGrid(testCase)

    wavelengthNm = (400:20:700).';
    reference = makeArchive(wavelengthNm, ones(size(wavelengthNm)));
    sample = makeArchive(wavelengthNm, 0.5 .* ones(size(wavelengthNm)));
    filter = makeFilter(wavelengthNm, ones(size(wavelengthNm)));

    result = spectralab.analysis.transmissionDensity( ...
        reference, sample, filter, Resample=false);

    verifyEqual(testCase, result.Provenance.Resampled, false);
    verifyEqual(testCase, result.Result.WavelengthNm, wavelengthNm);
end


function testDifferentWavelengthGridsRequireResampling(testCase)

    referenceWavelengthNm = (400:10:700).';
    sampleWavelengthNm = (405:10:695).';

    reference = makeArchive( ...
        referenceWavelengthNm, ones(size(referenceWavelengthNm)));
    sample = makeArchive( ...
        sampleWavelengthNm, 0.5 .* ones(size(sampleWavelengthNm)));
    filter = makeFilter( ...
        referenceWavelengthNm, ones(size(referenceWavelengthNm)));

    verifyError(testCase, ...
        @() spectralab.analysis.transmissionDensity( ...
            reference, sample, filter, Resample=false), ...
        "SpectraLab:Analysis:WavelengthMismatch");
end


function testDifferentWavelengthGridsWorkWithResampling(testCase)

    referenceWavelengthNm = (400:10:700).';
    sampleWavelengthNm = (405:10:695).';

    reference = makeArchive( ...
        referenceWavelengthNm, ones(size(referenceWavelengthNm)));
    sample = makeArchive( ...
        sampleWavelengthNm, 0.5 .* ones(size(sampleWavelengthNm)));
    filter = makeFilter( ...
        referenceWavelengthNm, ones(size(referenceWavelengthNm)));

    result = spectralab.analysis.transmissionDensity( ...
        reference, sample, filter, ...
        Resample=true, ...
        RefinementFactor=4, ...
        InterpolationMethod="pchip");

    verifyEqual(testCase, result.Provenance.Resampled, true);
    verifyEqual(testCase, result.Result.Density, -log10(0.5), AbsTol=1e-10);
end


function testSampleAboveReferenceProducesWarning(testCase)

    wavelengthNm = (400:10:700).';
    reference = makeArchive(wavelengthNm, ones(size(wavelengthNm)));
    sample = makeArchive(wavelengthNm, 1.1 .* ones(size(wavelengthNm)));
    filter = makeFilter(wavelengthNm, ones(size(wavelengthNm)));

    verifyWarning(testCase, ...
        @() spectralab.analysis.transmissionDensity( ...
            reference, sample, filter, Resample=false), ...
        "spectralab:analysis:transmissionDensity:SampleAboveReference");
end


function testSampleAboveReferenceProducesNegativeDensity(testCase)

    wavelengthNm = (400:10:700).';
    reference = makeArchive(wavelengthNm, ones(size(wavelengthNm)));
    sample = makeArchive(wavelengthNm, 1.1 .* ones(size(wavelengthNm)));
    filter = makeFilter(wavelengthNm, ones(size(wavelengthNm)));

    warningState = warning( ...
        "off", ...
        "spectralab:analysis:transmissionDensity:SampleAboveReference");
    cleanup = onCleanup(@() warning(warningState));

    result = spectralab.analysis.transmissionDensity( ...
        reference, sample, filter, Resample=false);

    verifyGreaterThan(testCase, result.Result.EffectiveTransmission, 1);
    verifyLessThan(testCase, result.Result.Density, 0);
end


function testNoCommonFilterRangeThrowsError(testCase)

    spectrumWavelengthNm = (400:10:500).';
    filterWavelengthNm = (600:10:700).';

    reference = makeArchive( ...
        spectrumWavelengthNm, ones(size(spectrumWavelengthNm)));
    sample = makeArchive( ...
        spectrumWavelengthNm, 0.5 .* ones(size(spectrumWavelengthNm)));
    filter = makeFilter( ...
        filterWavelengthNm, ones(size(filterWavelengthNm)));

    verifyError(testCase, ...
        @() spectralab.analysis.transmissionDensity( ...
            reference, sample, filter, Resample=false), ...
        "spectralab:analysis:transmissionDensity:NoCommonRange");
end


function testZeroWeightingFilterThrowsError(testCase)

    wavelengthNm = (400:10:700).';
    reference = makeArchive(wavelengthNm, ones(size(wavelengthNm)));
    sample = makeArchive(wavelengthNm, 0.5 .* ones(size(wavelengthNm)));
    filter = makeFilter(wavelengthNm, zeros(size(wavelengthNm)));

    verifyError(testCase, ...
        @() spectralab.analysis.transmissionDensity( ...
            reference, sample, filter, Resample=false), ...
        "spectralab:analysis:transmissionDensity:ZeroWeightingFilter");
end


function testNegativeFilterValuesThrowError(testCase)

    wavelengthNm = (400:10:700).';
    filterValue = ones(size(wavelengthNm));
    filterValue(5) = -0.1;

    reference = makeArchive(wavelengthNm, ones(size(wavelengthNm)));
    sample = makeArchive(wavelengthNm, 0.5 .* ones(size(wavelengthNm)));

    verifyError(testCase, ...
        @() runWithFilter( ...
            reference, sample, wavelengthNm, filterValue), ...
        "spectralab:analysis:transmissionDensity:NegativeFilterValues");
end


function testProvenanceRecordsProcessingOptions(testCase)

    wavelengthNm = (400:20:700).';
    reference = makeArchive(wavelengthNm, ones(size(wavelengthNm)));
    sample = makeArchive(wavelengthNm, 0.5 .* ones(size(wavelengthNm)));
    filter = makeFilter(wavelengthNm, ones(size(wavelengthNm)));

    result = spectralab.analysis.transmissionDensity( ...
        reference, sample, filter, ...
        Resample=true, ...
        RefinementFactor=4, ...
        InterpolationMethod="pchip", ...
        FilterInterpolationMethod="linear");

    verifyEqual(testCase, result.Provenance.Resampled, true);
    verifyEqual(testCase, result.Provenance.RefinementFactor, 4);
    verifyEqual(testCase, result.Provenance.InterpolationMethod, "pchip");
    verifyEqual(testCase, result.Provenance.FilterInterpolationMethod, "linear");
end


function testResultContainsCalculationData(testCase)

    wavelengthNm = (400:10:700).';
    reference = makeArchive(wavelengthNm, ones(size(wavelengthNm)));
    sample = makeArchive(wavelengthNm, 0.5 .* ones(size(wavelengthNm)));
    filter = makeFilter(wavelengthNm, ones(size(wavelengthNm)));

    result = spectralab.analysis.transmissionDensity( ...
        reference, sample, filter, Resample=false);

    requiredFields = [ ...
        "Density", ...
        "EffectiveTransmission", ...
        "WavelengthNm", ...
        "Transmission", ...
        "Weight", ...
        "WeightedTransmission"];

    for fieldName = requiredFields
        verifyTrue(testCase, isfield(result.Result, fieldName));
    end

    verifySize(testCase, result.Result.Transmission, size(result.Result.WavelengthNm));
    verifySize(testCase, result.Result.Weight, size(result.Result.WavelengthNm));
    verifySize(testCase, result.Result.WeightedTransmission, size(result.Result.WavelengthNm));
end


function archive = makeArchive(wavelengthNm, value)
%MAKEARCHIVE Create a valid SpectraLab archive from controlled test data.

    spectrum = spectralab.core.Spectrum( ...
        wavelengthNm(:), ...
        value(:));

    archive = spectralab.archive.create(spectrum);
end


function filter = makeFilter(wavelengthNm, value)
%MAKEFILTER Create a tabulated test weighting filter.

    filter = spectralab.core.SpectralFilter.fromTable( ...
        wavelengthNm(:), ...
        value(:), ...
        Name="Test weighting filter");
end


function runWithFilter(reference, sample, wavelengthNm, filterValue)
%RUNWITHFILTER Keep filter construction inside verifyError evaluation.

    filter = makeFilter(wavelengthNm, filterValue);

    spectralab.analysis.transmissionDensity( ...
        reference, sample, filter, Resample=false);
end
