function result = transmissionDensity(reference, sample, weightingFilter, options)
%TRANSMISSIONDENSITY Calculate spectrally weighted transmission density.
%
%   RESULT = spectralab.analysis.transmissionDensity( ...
%       REFERENCE, SAMPLE, WEIGHTINGFILTER)
%
%   calculates the effective transmission through SAMPLE relative to
%   REFERENCE using the supplied spectral weighting filter:
%
%       T_eff = integral(T(lambda) W(lambda) dlambda) ...
%               / integral(W(lambda) dlambda)
%
%       D = -log10(T_eff)
%
%   REFERENCE and SAMPLE are processed by
%   spectralab.analysis.transmission. Consequently, all wavelength
%   alignment and optional spectral refinement follow the canonical
%   transmission implementation.
%
%   Name-value options
%   ------------------
%   Resample
%       false:
%           The reference and sample wavelength grids must be identical.
%           The measured samples are used directly.
%
%       true:
%           The reference and sample spectra are always interpolated onto
%           a refined wavelength grid, even when their original grids are
%           identical.
%
%   RefinementFactor
%       Positive integer controlling the density of the refined wavelength
%       grid. The default is 4.
%
%   InterpolationMethod
%       Interpolation method forwarded to
%       spectralab.analysis.transmission. The default is "pchip".
%
%   FilterInterpolationMethod
%       Interpolation method used to align the weighting filter with the
%       transmission wavelength grid. The default is "linear".
%
%   The returned structure contains:
%
%       result.Result.Density
%       result.Result.EffectiveTransmission
%       result.Result.WavelengthNm
%       result.Result.Transmission
%       result.Result.Weight
%
%   and provenance copied from the underlying transmission analysis.
%
%   See also:
%       spectralab.analysis.transmission
%       spectralab.analysis.whiteDensity
%       spectralab.analysis.statusADensity

    arguments
        reference
        sample
        weightingFilter

        options.Resample (1,1) logical = false

        options.RefinementFactor (1,1) double ...
            {mustBeInteger, mustBeGreaterThanOrEqual( ...
            options.RefinementFactor, 1)} = 4

        options.InterpolationMethod (1,1) string ...
            {mustBeMember(options.InterpolationMethod, ...
            ["linear", "pchip", "spline", "makima"])} = "pchip"

        options.FilterInterpolationMethod (1,1) string ...
            {mustBeMember(options.FilterInterpolationMethod, ...
            ["linear", "pchip", "spline", "makima"])} = "linear"
    end


    %% Calculate canonical spectral transmission

    transmissionResult = spectralab.analysis.transmission( ...
        reference, ...
        sample, ...
        Resample=options.Resample, ...
        RefinementFactor=options.RefinementFactor, ...
        InterpolationMethod=options.InterpolationMethod, ...
        WarnAboveOne=false);


    %% Read the transmission spectrum

    wavelengthNm = transmissionResult.Result.WavelengthNm(:);
    transmissionValue = transmissionResult.Result.Value(:);

    validateTransmissionSpectrum(wavelengthNm, transmissionValue);


    %% Read and validate the weighting filter

    filterWavelengthNm = weightingFilter.WavelengthNm(:);
    filterValue = weightingFilter.Value(:);

    validateWeightingFilter(filterWavelengthNm, filterValue);


    %% Determine common wavelength range

    commonMinimumNm = max( ...
        wavelengthNm(1), ...
        filterWavelengthNm(1));

    commonMaximumNm = min( ...
        wavelengthNm(end), ...
        filterWavelengthNm(end));

    if commonMinimumNm >= commonMaximumNm
        error( ...
            "spectralab:analysis:transmissionDensity:NoCommonRange", ...
            "The transmission spectrum and weighting filter have no " + ...
            "common wavelength range.");
    end


    %% Restrict the transmission grid to the common range

    inCommonRange = ...
        wavelengthNm >= commonMinimumNm & ...
        wavelengthNm <= commonMaximumNm;

    densityWavelengthNm = wavelengthNm(inCommonRange);
    densityTransmission = transmissionValue(inCommonRange);

    if numel(densityWavelengthNm) < 2
        error( ...
            "spectralab:analysis:transmissionDensity:InsufficientSamples", ...
            "At least two wavelength samples are required within the " + ...
            "common wavelength range.");
    end


    %% Align the weighting filter with the transmission grid

    densityWeight = interp1( ...
        filterWavelengthNm, ...
        filterValue, ...
        densityWavelengthNm, ...
        options.FilterInterpolationMethod);

    if any(~isfinite(densityWeight))
        error( ...
            "spectralab:analysis:transmissionDensity:" + ...
            "FilterInterpolationFailed", ...
            "The weighting filter could not be evaluated over the " + ...
            "complete transmission wavelength range.");
    end


    %% Calculate effective transmission

    weightedTransmission = densityTransmission .* densityWeight;

    weightIntegral = trapz( ...
        densityWavelengthNm, ...
        densityWeight);

    if ~isfinite(weightIntegral) || weightIntegral <= 0
        error( ...
            "spectralab:analysis:transmissionDensity:InvalidWeightIntegral", ...
            "The integrated weighting filter must be finite and " + ...
            "greater than zero.");
    end

    weightedTransmissionIntegral = trapz( ...
        densityWavelengthNm, ...
        weightedTransmission);

    effectiveTransmission = ...
        weightedTransmissionIntegral / weightIntegral;


    %% Calculate density and issue physical warnings

    if effectiveTransmission < 0
        error( ...
            "spectralab:analysis:transmissionDensity:" + ...
            "NegativeEffectiveTransmission", ...
            "The calculated effective transmission is negative.");
    end

    if effectiveTransmission == 0
        density = Inf;

    else
        density = -log10(effectiveTransmission);
    end

    if effectiveTransmission > 1
        warning( ...
            "spectralab:analysis:transmissionDensity:" + ...
            "SampleAboveReference", ...
            "The effective transmission is %.6g, which is greater " + ...
            "than one. The sample signal exceeds the reference signal " + ...
            "within the weighted wavelength range.", ...
            effectiveTransmission);
    end


    %% Build result

    result = struct();

    result.Analysis = "Transmission density";

    result.Result = struct();

    result.Result.Density = density;
    result.Result.EffectiveTransmission = effectiveTransmission;

    result.Result.WavelengthNm = densityWavelengthNm;
    result.Result.Transmission = densityTransmission;
    result.Result.Weight = densityWeight;
    result.Result.WeightedTransmission = weightedTransmission;

    result.Result.WeightIntegral = weightIntegral;
    result.Result.WeightedTransmissionIntegral = ...
        weightedTransmissionIntegral;

    result.Result.WavelengthRangeNm = [ ...
        densityWavelengthNm(1), ...
        densityWavelengthNm(end)];


    %% Preserve transmission provenance

    result.Provenance = struct();

    result.Provenance.TransmissionIdentity = ...
        transmissionResult.Identity;

    result.Provenance.TransmissionDefinition = ...
        transmissionResult.Definition;

    result.Provenance.TransmissionParameters = ...
        transmissionResult.Parameters;

    result.Provenance.TransmissionSource = ...
        transmissionResult.Source;

    result.Provenance.Alignment = ...
        transmissionResult.Parameters.Alignment;

    result.Provenance.Resampled = ...
        transmissionResult.Parameters.Resampled;

    result.Provenance.RefinementFactor = ...
        transmissionResult.Parameters.RefinementFactor;

    result.Provenance.InterpolationMethod = ...
        transmissionResult.Parameters.InterpolationMethod;

    result.Provenance.FilterInterpolationMethod = ...
        options.FilterInterpolationMethod;

    result.Provenance.FilterWavelengthRangeNm = [ ...
        filterWavelengthNm(1), ...
        filterWavelengthNm(end)];

    result.Provenance.CalculationWavelengthRangeNm = ...
        result.Result.WavelengthRangeNm;
end


function validateTransmissionSpectrum(wavelengthNm, value)

    if numel(wavelengthNm) ~= numel(value)
        error( ...
            "spectralab:analysis:transmissionDensity:" + ...
            "InvalidTransmissionSpectrum", ...
            "The transmission wavelength and value vectors must have " + ...
            "the same number of elements.");
    end

    if numel(wavelengthNm) < 2
        error( ...
            "spectralab:analysis:transmissionDensity:" + ...
            "InvalidTransmissionSpectrum", ...
            "The transmission spectrum must contain at least two samples.");
    end

    if any(~isfinite(wavelengthNm)) || ...
            any(diff(wavelengthNm) <= 0)
        error( ...
            "spectralab:analysis:transmissionDensity:" + ...
            "InvalidTransmissionWavelengths", ...
            "Transmission wavelengths must be finite and strictly " + ...
            "increasing.");
    end

    if any(~isfinite(value))
        error( ...
            "spectralab:analysis:transmissionDensity:" + ...
            "InvalidTransmissionValues", ...
            "Transmission values must be finite.");
    end
end


function validateWeightingFilter(wavelengthNm, value)

    if numel(wavelengthNm) ~= numel(value)
        error( ...
            "spectralab:analysis:transmissionDensity:" + ...
            "InvalidWeightingFilter", ...
            "The filter wavelength and value vectors must have the " + ...
            "same number of elements.");
    end

    if numel(wavelengthNm) < 2
        error( ...
            "spectralab:analysis:transmissionDensity:" + ...
            "InvalidWeightingFilter", ...
            "The weighting filter must contain at least two samples.");
    end

    if any(~isfinite(wavelengthNm)) || ...
            any(diff(wavelengthNm) <= 0)
        error( ...
            "spectralab:analysis:transmissionDensity:" + ...
            "InvalidFilterWavelengths", ...
            "Filter wavelengths must be finite and strictly increasing.");
    end

    if any(~isfinite(value))
        error( ...
            "spectralab:analysis:transmissionDensity:" + ...
            "InvalidFilterValues", ...
            "Filter values must be finite.");
    end

    if any(value < 0)
        error( ...
            "spectralab:analysis:transmissionDensity:" + ...
            "NegativeFilterValues", ...
            "The weighting filter must not contain negative values.");
    end

    if ~any(value > 0)
        error( ...
            "spectralab:analysis:transmissionDensity:" + ...
            "ZeroWeightingFilter", ...
            "The weighting filter must contain at least one value " + ...
            "greater than zero.");
    end
end