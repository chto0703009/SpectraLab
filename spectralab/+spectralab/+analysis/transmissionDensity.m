function result = transmissionDensity(reference, sample, filter, options)
%TRANSMISSIONDENSITY Calculate filtered transmission density.
%
%   result = spectralab.analysis.transmissionDensity( ...
%       reference, sample, filter)
%
%   The function follows the canonical SpectraLab analysis pipeline:
%
%       reference + sample
%               ↓
%       analysis.transmission
%               ↓
%       analysis.filterResponse
%               ↓
%       normalized integration
%               ↓
%       transmission density
%
%   The effective filtered transmission is:
%
%       T = integral(transmission .* filter) / integral(filter)
%
%   and transmission density is:
%
%       D = -log10(T)
%
%   reference and sample are passed directly to
%   spectralab.analysis.transmission and may therefore use any input type
%   supported by that function.
%
%   Name-value options
%   ------------------
%   WavelengthRange
%       Optional [minimum maximum] interval in nm. The interval must lie
%       completely within the valid transmission/filter overlap.
%
%   WarnBelowTransmission
%       Emit a warning when effective transmission is below this positive
%       threshold. Set to 0 to disable. Default: 1e-4.
%
%   WarnAboveDensity
%       Emit a warning when density exceeds this threshold. Set to Inf to
%       disable. Default: 4.
%
%   WarnAboveOne
%       Emit one wrapper-level warning when the final effective filtered
%       transmission exceeds 1. Default: true.
%
%   Output
%   ------
%   result.Transmission
%       Canonical spectral transmission result.
%
%   result.FilterResponse
%       Wavelength-dependent weighted transmission result.
%
%   result.Result.EffectiveTransmission
%       Scalar normalized filtered transmission.
%
%   result.Result.Density
%       Scalar transmission density.

    arguments
        reference
        sample
        filter (1,1) spectralab.core.SpectralFilter

        options.WavelengthRange (1,2) double = [NaN NaN]

        options.WarnBelowTransmission (1,1) double ...
            {mustBeNonnegative} = 1e-4

        options.WarnAboveDensity (1,1) double = 4

        options.WarnAboveOne (1,1) logical = false
    end

    % Suppress wavelength-level above-unity warnings here. This higher-level
    % analysis reports only anomalies relevant to its final scalar result.
    transmissionResult = spectralab.analysis.transmission( ...
        reference, ...
        sample, ...
        WarnAboveOne=false);

    validateTransmissionResult(transmissionResult);

    if all(isfinite(options.WavelengthRange))

        response = spectralab.analysis.filterResponse( ...
            transmissionResult, ...
            filter, ...
            WavelengthRange=options.WavelengthRange);

    elseif any(isfinite(options.WavelengthRange))

        error( ...
            "spectralab:analysis:transmissionDensity:InvalidRange", ...
            "WavelengthRange must contain two finite values or be omitted.");

    else

        response = spectralab.analysis.filterResponse( ...
            transmissionResult, ...
            filter);
    end

    wavelength = response.Result.WavelengthNm(:);
    weightedTransmission = response.Result.Value(:);
    filterValue = response.Result.FilterValue(:);

    numerator = trapz( ...
        wavelength, ...
        weightedTransmission);

    denominator = trapz( ...
        wavelength, ...
        filterValue);

    if ~isfinite(denominator) || denominator <= 0
        error( ...
            "spectralab:analysis:transmissionDensity:InvalidFilterIntegral", ...
            "The integrated filter weighting must be finite and positive.");
    end

    effectiveTransmission = numerator / denominator;

    if ~isfinite(effectiveTransmission) || effectiveTransmission <= 0
        error( ...
            "spectralab:analysis:transmissionDensity:InvalidTransmission", ...
            "The effective filtered transmission must be finite and positive.");
    end

    density = -log10(effectiveTransmission);

    if options.WarnAboveOne && effectiveTransmission > 1
        warning( ...
            "spectralab:analysis:transmissionDensity:AboveUnity", ...
            "Effective filtered transmission exceeds 1. Check the reference measurement, sample measurement, instrument stability, and measurement geometry.");
    end

    if options.WarnBelowTransmission > 0 && ...
            effectiveTransmission < options.WarnBelowTransmission

        warning( ...
            "spectralab:analysis:transmissionDensity:LowTransmission", ...
            "Effective transmission %.6g is below the warning threshold %.6g.", ...
            effectiveTransmission, ...
            options.WarnBelowTransmission);
    end

    if isfinite(options.WarnAboveDensity) && ...
            density > options.WarnAboveDensity

        warning( ...
            "spectralab:analysis:transmissionDensity:HighDensity", ...
            "Transmission density %.6g exceeds the warning threshold %.6g.", ...
            density, ...
            options.WarnAboveDensity);
    end

    result = struct();
    result.Type = "TransmissionDensity";

    result.Filter = filter.summaryStruct();
    result.Transmission = transmissionResult;
    result.FilterResponse = response;

    result.Range = struct();
    result.Range.EffectiveRangeNm = ...
        response.Range.EffectiveRangeNm;
    result.Range.SampleCount = ...
        response.Range.SampleCount;

    result.Processing = struct();

    result.Processing.Pipeline = ...
        "transmission -> filterResponse -> normalized trapezoidal integration -> -log10";

    result.Processing.IntegrationMethod = ...
        "trapezoidal";

    result.Processing.Normalization = ...
        "integral(filter)";

    result.Processing.DensityDefinition = ...
        "-log10(effective transmission)";

    result.Processing.WarnBelowTransmission = ...
        options.WarnBelowTransmission;

    result.Processing.WarnAboveDensity = ...
        options.WarnAboveDensity;

    result.Processing.WarnAboveOne = ...
        options.WarnAboveOne;

    result.Result = struct();
    result.Result.WeightedIntegral = numerator;
    result.Result.FilterIntegral = denominator;
    result.Result.EffectiveTransmission = effectiveTransmission;
    result.Result.Transmittance = effectiveTransmission;
    result.Result.Density = density;
end


function validateTransmissionResult(result)

    if ~isstruct(result)
        error( ...
            "spectralab:analysis:transmissionDensity:InvalidTransmissionResult", ...
            "analysis.transmission must return a result structure.");
    end

    if ~isfield(result, "Result") || ~isstruct(result.Result)
        error( ...
            "spectralab:analysis:transmissionDensity:MissingResult", ...
            "The transmission result is missing its Result section.");
    end

    requiredFields = ["WavelengthNm", "Value"];

    for fieldName = requiredFields

        if ~isfield(result.Result, fieldName)
            error( ...
                "spectralab:analysis:transmissionDensity:MissingField", ...
                "Transmission Result.%s is required.", ...
                fieldName);
        end
    end

    wavelength = result.Result.WavelengthNm(:);
    value = result.Result.Value(:);

    if isempty(wavelength) || isempty(value)
        error( ...
            "spectralab:analysis:transmissionDensity:EmptyTransmissionResult", ...
            "The transmission result must not be empty.");
    end

    if numel(wavelength) ~= numel(value)
        error( ...
            "spectralab:analysis:transmissionDensity:SizeMismatch", ...
            "Transmission wavelength and value vectors must have equal length.");
    end

    if any(~isfinite(wavelength)) || any(~isfinite(value))
        error( ...
            "spectralab:analysis:transmissionDensity:NonFiniteTransmissionResult", ...
            "Transmission wavelength and value vectors must be finite.");
    end

    if any(diff(wavelength) <= 0)
        error( ...
            "spectralab:analysis:transmissionDensity:WavelengthNotIncreasing", ...
            "Transmission wavelengths must be strictly increasing.");
    end
end