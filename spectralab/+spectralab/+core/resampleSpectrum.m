function result = resampleSpectrum(spec, options)
%RESAMPLESPECTRUM Refine the wavelength grid of a Spectrum.
%
%   RESULT = spectralab.core.resampleSpectrum(SPEC) refines each original
%   wavelength interval by the default factor of 4 using shape-preserving
%   cubic interpolation.
%
%   RESULT = spectralab.core.resampleSpectrum(SPEC, RefinementFactor=N)
%   divides each original wavelength interval into N equal subintervals.
%
%   RESULT = spectralab.core.resampleSpectrum(SPEC, Method=METHOD)
%   selects the interpolation method:
%
%       "pchip"   Shape-preserving cubic interpolation, default
%       "makima"  Modified Akima cubic interpolation
%       "spline"  Cubic spline interpolation
%
%   The new wavelength grid:
%
%       - begins and ends at the original endpoints;
%       - contains every original wavelength;
%       - does not extrapolate beyond the measured wavelength range.
%
%   Example
%   -------
%       refined = spectralab.core.resampleSpectrum( ...
%           spec, ...
%           RefinementFactor=4, ...
%           Method="pchip");
%
%   See also INTERP1.

    arguments
        spec
        options.RefinementFactor (1,1) double ...
            {mustBeInteger, mustBeGreaterThanOrEqual(options.RefinementFactor, 1)} = 4

        options.Method (1,1) string ...
            {mustBeMember(options.Method, ["pchip", "makima", "spline"])} = "pchip"
    end

    wavelengthNm = spec.WavelengthNm(:);
    power        = spec.Power(:);

    validateSpectrumData(wavelengthNm, power);

    refinementFactor = options.RefinementFactor;

    if refinementFactor == 1
        result = spec;
        return
    end

    refinedWavelengthNm = createNestedGrid( ...
        wavelengthNm, refinementFactor);

    refinedPower = interp1( ...
        wavelengthNm, ...
        power, ...
        refinedWavelengthNm, ...
        options.Method);

    % Replace this constructor call if Spectrum uses a different
    % construction or copy API in the current SpectraLab implementation.
    result = spectralab.core.Spectrum( ...
        refinedWavelengthNm, ...
        refinedPower);

end


function refinedGrid = createNestedGrid(originalGrid, refinementFactor)

    numberOfIntervals = numel(originalGrid) - 1;
    numberOfPoints = numberOfIntervals * refinementFactor + 1;

    refinedGrid = zeros(numberOfPoints, 1);

    outputIndex = 1;

    for intervalIndex = 1:numberOfIntervals

        intervalPoints = linspace( ...
            originalGrid(intervalIndex), ...
            originalGrid(intervalIndex + 1), ...
            refinementFactor + 1);

        % Do not repeat the right endpoint. It becomes the left endpoint
        % of the next interval.
        refinedGrid( ...
            outputIndex : outputIndex + refinementFactor - 1) = ...
            intervalPoints(1:end-1);

        outputIndex = outputIndex + refinementFactor;
    end

    refinedGrid(end) = originalGrid(end);

end


function validateSpectrumData(wavelengthNm, power)

    if numel(wavelengthNm) ~= numel(power)
        error( ...
            "spectralab:core:resampleSpectrum:SizeMismatch", ...
            "WavelengthNm and Power must contain the same number of values.");
    end

    if numel(wavelengthNm) < 2
        error( ...
            "spectralab:core:resampleSpectrum:TooFewSamples", ...
            "At least two spectral samples are required for interpolation.");
    end

    if any(~isfinite(wavelengthNm))
        error( ...
            "spectralab:core:resampleSpectrum:InvalidWavelength", ...
            "WavelengthNm must contain only finite values.");
    end

    if any(~isfinite(power))
        error( ...
            "spectralab:core:resampleSpectrum:InvalidPower", ...
            "Power must contain only finite values.");
    end

    if any(diff(wavelengthNm) <= 0)
        error( ...
            "spectralab:core:resampleSpectrum:NonIncreasingWavelength", ...
            "WavelengthNm must be strictly increasing.");
    end

end