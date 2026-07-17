function result = weightedDensity(referenceInput, sampleInput, weightingInput, options)
%WEIGHTEDDENSITY Calculate density using a spectral weighting function.
%
%   RESULT = spectralab.core.weightedDensity(REFERENCE, SAMPLE, WEIGHTING)
%
%   aligns the reference, sample, and weighting spectra onto a common
%   wavelength grid, integrates the weighted reference and sample signals,
%   and calculates:
%
%       Transmittance = weightedSample / weightedReference
%
%       Density = -log10(Transmittance)
%
%   REFERENCE and SAMPLE may be:
%
%       - spectralab.core.Spectrum objects
%       - structures with WavelengthNm and Value fields
%       - SpectraLab archives accepted by spectralab.archive.restore
%
%   WEIGHTING must be a Spectrum-like object or structure containing:
%
%       WavelengthNm
%       Value
%
%   RESULT is a scalar structure containing:
%
%       Density
%       Transmittance
%       ReferenceWeightedValue
%       SampleWeightedValue
%       WavelengthRangeNm
%       WeightingName
%
%   This is the common calculation engine for white, red, green, blue,
%   and other weighted density measurements.

    arguments
        referenceInput
        sampleInput
        weightingInput

        options.WeightingName (1,1) string = "Weighted density"
        options.WarnAboveOne (1,1) logical = true

        options.Resample (1,1) logical = false

        options.RefinementFactor (1,1) double ...
            {mustBeInteger, ...
             mustBeGreaterThanOrEqual(options.RefinementFactor, 1)} = 4

        options.InterpolationMethod (1,1) string ...
            {mustBeMember(options.InterpolationMethod, ...
                ["pchip", "makima", "spline"])} = "pchip"
    end

    reference = localSpectrumData(referenceInput, "reference");
    sample    = localSpectrumData(sampleInput, "sample");
    weighting = localWeightingData(weightingInput);

    localValidateSignal(reference, "reference");
    localValidateSignal(sample, "sample");
    localValidateWeighting(weighting);
    if options.Resample

        reference = localResampleData( ...
            reference, ...
            options.RefinementFactor, ...
            options.InterpolationMethod);

        sample = localResampleData( ...
            sample, ...
            options.RefinementFactor, ...
            options.InterpolationMethod);
    end

    minimumWavelength = max([
        min(reference.WavelengthNm)
        min(sample.WavelengthNm)
        min(weighting.WavelengthNm)
    ]);

    maximumWavelength = min([
        max(reference.WavelengthNm)
        max(sample.WavelengthNm)
        max(weighting.WavelengthNm)
    ]);

    if minimumWavelength >= maximumWavelength
		error( ...
		    "spectralab:core:weightedDensity:NoOverlap", ...
		    "Reference, sample, and weighting data have no common wavelength range.");
    end

    wavelengthNm = localCommonGrid( ...
        reference.WavelengthNm, ...
        sample.WavelengthNm, ...
        weighting.WavelengthNm, ...
        minimumWavelength, ...
        maximumWavelength);

    if numel(wavelengthNm) < 2
        error( ...
            "spectralab:core:weightedDensity:InsufficientOverlap", ...
            [ ...
                "At least two wavelength samples are required in the " ...
                "common wavelength range." ...
            ]);
    end

    referenceValue = interp1( ...
        reference.WavelengthNm, ...
        reference.Value, ...
        wavelengthNm, ...
        "linear");

    sampleValue = interp1( ...
        sample.WavelengthNm, ...
        sample.Value, ...
        wavelengthNm, ...
        "linear");

    weightingValue = interp1( ...
        weighting.WavelengthNm, ...
        weighting.Value, ...
        wavelengthNm, ...
        "linear");

    referenceWeightedValue = trapz( ...
        wavelengthNm, ...
        referenceValue .* weightingValue);

    sampleWeightedValue = trapz( ...
        wavelengthNm, ...
        sampleValue .* weightingValue);

    if ~isfinite(referenceWeightedValue) || referenceWeightedValue <= 0
        error( ...
            "spectralab:core:weightedDensity:InvalidReferenceIntegral", ...
            [ ...
                "The weighted reference integral must be finite and " ...
                "greater than zero." ...
            ]);
    end

    if ~isfinite(sampleWeightedValue) || sampleWeightedValue < 0
        error( ...
            "spectralab:core:weightedDensity:InvalidSampleIntegral", ...
            [ ...
                "The weighted sample integral must be finite and " ...
                "non-negative." ...
            ]);
    end

    transmittance = sampleWeightedValue / referenceWeightedValue;

    if transmittance == 0
        density = Inf;
    else
        density = -log10(transmittance);
    end

    if options.WarnAboveOne && transmittance > 1
        warning( ...
    "spectralab:core:weightedDensity:TransmittanceAboveOne", ...
    "Calculated weighted transmittance exceeds 1. Check the reference measurement, sample measurement, instrument stability, and measurement geometry.");
    end

    result = struct( ...
        "Density", density, ...
        "Transmittance", transmittance, ...
        "ReferenceWeightedValue", referenceWeightedValue, ...
        "SampleWeightedValue", sampleWeightedValue, ...
        "WavelengthRangeNm", [wavelengthNm(1), wavelengthNm(end)], ...
        "WeightingName", options.WeightingName, ...
        "Resampled", options.Resample, ...
        "RefinementFactor", options.RefinementFactor, ...
        "InterpolationMethod", options.InterpolationMethod);end


function data = localSpectrumData(inputValue, inputName)

    if localHasSpectralData(inputValue)
        data = localExtractSpectralData(inputValue);
        return
    end

    if isstruct(inputValue)
        try
            restored = spectralab.archive.restore(inputValue);
        catch exception
            error( ...
                "spectralab:core:weightedDensity:InvalidInput", ...
                "%s input is not a valid spectrum or SpectraLab archive:\n%s", ...
                upperFirst(inputName), ...
                exception.message);
        end

        if ~localHasSpectralData(restored)
            error( ...
                "spectralab:core:weightedDensity:InvalidInput", ...
                "%s archive did not restore to valid spectral data.", ...
                upperFirst(inputName));
        end

        data = localExtractSpectralData(restored);
        return
    end

    error( ...
        "spectralab:core:weightedDensity:InvalidInput", ...
        [ ...
            "%s input must provide WavelengthNm and Value, or be a " ...
            "valid SpectraLab archive." ...
        ], ...
        upperFirst(inputName));
end


function data = localWeightingData(inputValue)

    if ~localHasSpectralData(inputValue)
        error( ...
            "spectralab:core:weightedDensity:InvalidWeighting", ...
            "Weighting must provide WavelengthNm and Value.");
    end

    data = localExtractSpectralData(inputValue);
end


function tf = localHasSpectralData(inputValue)

    if isobject(inputValue)
        tf = isprop(inputValue, "WavelengthNm") && ...
             isprop(inputValue, "Value");
        return
    end

    if isstruct(inputValue)
        tf = isfield(inputValue, "WavelengthNm") && ...
             isfield(inputValue, "Value");
        return
    end

    tf = false;
end


function data = localExtractSpectralData(inputValue)

    data = struct( ...
        "WavelengthNm", double(inputValue.WavelengthNm(:)), ...
        "Value", double(inputValue.Value(:)));
end


function localValidateSignal(data, dataName)

    localValidateCommon(data, dataName);

    if any(data.Value < 0)
        error( ...
            "spectralab:core:weightedDensity:NegativeSignal", ...
            "%s spectrum contains negative values.", ...
            upperFirst(dataName));
    end
end


function localValidateWeighting(data)

    localValidateCommon(data, "weighting");

    if any(data.Value < 0)
        error( ...
            "spectralab:core:weightedDensity:NegativeWeighting", ...
            "Weighting function contains negative values.");
    end

    if ~any(data.Value > 0)
        error( ...
            "spectralab:core:weightedDensity:ZeroWeighting", ...
            "Weighting function must contain at least one positive value.");
    end
end


function localValidateCommon(data, dataName)

    wavelengthNm = data.WavelengthNm;
    value = data.Value;

    if isempty(wavelengthNm) || isempty(value)
        error( ...
            "spectralab:core:weightedDensity:EmptyData", ...
            "%s data is empty.", ...
            upperFirst(dataName));
    end

    if numel(wavelengthNm) ~= numel(value)
        error( ...
            "spectralab:core:weightedDensity:SizeMismatch", ...
            "%s wavelength and value arrays must have equal length.", ...
            upperFirst(dataName));
    end

    if numel(wavelengthNm) < 2
        error( ...
            "spectralab:core:weightedDensity:InsufficientSamples", ...
            "%s data must contain at least two samples.", ...
            upperFirst(dataName));
    end

    if any(~isfinite(wavelengthNm)) || any(~isfinite(value))
        error( ...
            "spectralab:core:weightedDensity:NonFiniteData", ...
            "%s data contains non-finite values.", ...
            upperFirst(dataName));
    end

    if any(diff(wavelengthNm) <= 0)
        error( ...
            "spectralab:core:weightedDensity:InvalidWavelengthOrder", ...
            "%s wavelengths must be strictly increasing.", ...
            upperFirst(dataName));
    end
end


function wavelengthNm = localCommonGrid( ...
        referenceWavelengthNm, ...
        sampleWavelengthNm, ...
        weightingWavelengthNm, ...
        minimumWavelength, ...
        maximumWavelength)

    referenceInside = referenceWavelengthNm( ...
        referenceWavelengthNm >= minimumWavelength & ...
        referenceWavelengthNm <= maximumWavelength);

    sampleInside = sampleWavelengthNm( ...
        sampleWavelengthNm >= minimumWavelength & ...
        sampleWavelengthNm <= maximumWavelength);

    weightingInside = weightingWavelengthNm( ...
        weightingWavelengthNm >= minimumWavelength & ...
        weightingWavelengthNm <= maximumWavelength);

    wavelengthNm = unique([
        minimumWavelength
        referenceInside
        sampleInside
        weightingInside
        maximumWavelength
    ]);
end


function text = upperFirst(text)

    text = char(text);

    if ~isempty(text)
        text(1) = upper(text(1));
    end

    text = string(text);
end
	
	
	function result = localResampleData(data, refinementFactor, method)

	    if refinementFactor == 1
	        result = data;
	        return
	    end

	    originalWavelengthNm = data.WavelengthNm;
	    originalValue = data.Value;

	    numberOfIntervals = numel(originalWavelengthNm) - 1;
	    numberOfPoints = numberOfIntervals * refinementFactor + 1;

	    refinedWavelengthNm = zeros(numberOfPoints, 1);

	    outputIndex = 1;

	    for intervalIndex = 1:numberOfIntervals

	        intervalPoints = linspace( ...
	            originalWavelengthNm(intervalIndex), ...
	            originalWavelengthNm(intervalIndex + 1), ...
	            refinementFactor + 1);

	        refinedWavelengthNm( ...
	            outputIndex : outputIndex + refinementFactor - 1) = ...
	            intervalPoints(1:end-1);

	        outputIndex = outputIndex + refinementFactor;
	    end

	    refinedWavelengthNm(end) = originalWavelengthNm(end);

	    refinedValue = interp1( ...
	        originalWavelengthNm, ...
	        originalValue, ...
	        refinedWavelengthNm, ...
	        method);

	    result = struct( ...
	        "WavelengthNm", refinedWavelengthNm, ...
	        "Value", refinedValue);

	end