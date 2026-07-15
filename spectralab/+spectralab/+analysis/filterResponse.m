function result = filterResponse(inputData, filter, options)
%FILTERRESPONSE Apply a SpectralFilter to spectral data.
%
%   result = spectralab.analysis.filterResponse(inputData, filter)
%
%   inputData may be:
%
%       1. a scalar spectralab.core.Spectrum object; or
%       2. a canonical SpectraLab analysis result containing:
%
%              inputData.Result.WavelengthNm
%              inputData.Result.Value
%
%   Examples:
%
%       response = spectralab.analysis.filterResponse(spec, filter);
%
%       transmission = spectralab.analysis.transmission(ref, sample);
%       response = spectralab.analysis.filterResponse(transmission, filter);
%
%   The output remains wavelength dependent. No integration is performed.
%   No silent extrapolation is permitted.

    arguments
        inputData
        filter (1,1) spectralab.core.SpectralFilter
        options.WavelengthRange (1,2) double = [NaN NaN]
    end

    [sourceType, sourceName, wavelengthAll, valueAll] = ...
        resolveSpectralInput(inputData);

    validateSpectralData(wavelengthAll, valueAll);

    inputRange = [wavelengthAll(1), wavelengthAll(end)];

    commonRange = [ ...
        max(inputRange(1), filter.RangeNm(1)), ...
        min(inputRange(2), filter.RangeNm(2))];

    if commonRange(1) >= commonRange(2)
        error( ...
            "spectralab:analysis:filterResponse:NoOverlap", ...
            "The spectral input and SpectralFilter wavelength ranges do not overlap.");
    end

    effectiveRange = resolveRange( ...
        options.WavelengthRange, ...
        commonRange);

    useSample = wavelengthAll >= effectiveRange(1) & ...
                wavelengthAll <= effectiveRange(2);

    wavelength = wavelengthAll(useSample);
    inputValue = valueAll(useSample);

    if numel(wavelength) < 2
        error( ...
            "spectralab:analysis:filterResponse:TooFewSamples", ...
            "The effective wavelength interval must contain at least two samples.");
    end

    filterValue = filter.evaluate(wavelength);
    filterValue = filterValue(:);

    weightedValue = inputValue .* filterValue;

    result = struct();
    result.Type = "FilterResponse";

    result.Source = struct();
    result.Source.Type = sourceType;
    result.Source.Name = sourceName;

    result.Filter = filter.summaryStruct();

    result.Range = struct();
    result.Range.InputRangeNm = inputRange;
    result.Range.FilterRangeNm = filter.RangeNm;
    result.Range.CommonRangeNm = commonRange;
    result.Range.EffectiveRangeNm = effectiveRange;
    result.Range.SampleCount = numel(wavelength);

    result.Processing = struct();
    result.Processing.FilterRepresentation = filter.Representation;
    result.Processing.InterpolationMethod = "linear";
    result.Processing.GridSource = sourceType;
    result.Processing.Integrated = false;

    result.Result = struct();
    result.Result.WavelengthNm = wavelength;
    result.Result.InputValue = inputValue;
    result.Result.FilterValue = filterValue;
    result.Result.Value = weightedValue;
end


function [sourceType, sourceName, wavelength, value] = ...
        resolveSpectralInput(inputData)

    if isa(inputData, "spectralab.core.Spectrum")
        sourceType = "Spectrum";
        sourceName = string(inputData.Label);
        wavelength = inputData.WavelengthNm(:);
        value = inputData.Power(:);
        return
    end

    if isstruct(inputData) && ...
            isfield(inputData, "Result") && ...
            isstruct(inputData.Result) && ...
            isfield(inputData.Result, "WavelengthNm") && ...
            isfield(inputData.Result, "Value")

        sourceType = "AnalysisResult";

        if isfield(inputData, "Type")
            sourceName = string(inputData.Type);
        else
            sourceName = "Unnamed analysis result";
        end

        wavelength = inputData.Result.WavelengthNm(:);
        value = inputData.Result.Value(:);
        return
    end

    error( ...
        "spectralab:analysis:filterResponse:InvalidInput", ...
        ["Input must be a spectralab.core.Spectrum or a canonical " ...
         "SpectraLab analysis result containing Result.WavelengthNm " ...
         "and Result.Value."]);
end


function effectiveRange = resolveRange(requestedRange, commonRange)

    if all(isfinite(requestedRange))
        if requestedRange(1) >= requestedRange(2)
            error( ...
                "spectralab:analysis:filterResponse:InvalidRange", ...
                "WavelengthRange must be [minimum maximum].");
        end

        if requestedRange(1) < commonRange(1) || ...
                requestedRange(2) > commonRange(2)
            error( ...
                "spectralab:analysis:filterResponse:RangeOutsideOverlap", ...
                "The requested WavelengthRange must lie within the common overlap of %.6g to %.6g nm.", ...
                commonRange(1), ...
                commonRange(2));
        end

        effectiveRange = requestedRange;
        return
    end

    if any(isfinite(requestedRange))
        error( ...
            "spectralab:analysis:filterResponse:InvalidRange", ...
            "WavelengthRange must contain two finite values or be omitted.");
    end

    effectiveRange = commonRange;
end


function validateSpectralData(wavelength, value)

    if isempty(wavelength)
        error( ...
            "spectralab:analysis:filterResponse:EmptyWavelength", ...
            "The spectral input must contain wavelength values.");
    end

    if isempty(value)
        error( ...
            "spectralab:analysis:filterResponse:EmptyValue", ...
            "The spectral input must contain spectral values.");
    end

    if numel(wavelength) ~= numel(value)
        error( ...
            "spectralab:analysis:filterResponse:SizeMismatch", ...
            "Wavelength and value vectors must have equal length.");
    end

    if any(~isfinite(wavelength))
        error( ...
            "spectralab:analysis:filterResponse:NonFiniteWavelength", ...
            "Wavelength values must be finite.");
    end

    if any(~isfinite(value))
        error( ...
            "spectralab:analysis:filterResponse:NonFiniteValue", ...
            "Spectral values must be finite.");
    end

    if any(diff(wavelength) <= 0)
        error( ...
            "spectralab:analysis:filterResponse:WavelengthNotIncreasing", ...
            "Wavelength values must be strictly increasing.");
    end
end
