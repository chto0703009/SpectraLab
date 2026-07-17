function [referenceResult, sampleResult] = resampleSpectrumPair( ...
    referenceSpec, sampleSpec, options)
%RESAMPLESPECTRUMPAIR Refine a reference and sample spectrum.
%
%   [REFERENCE, SAMPLE] =
%       spectralab.core.resampleSpectrumPair(REFERENCE_SPEC, SAMPLE_SPEC)
%
%   resamples both spectra using the same refinement factor and
%   interpolation method.
%
%   The spectra are refined independently. Their original wavelength
%   ranges do not need to be identical.
%
%   Name-value arguments
%   --------------------
%   RefinementFactor
%       Number of equal subintervals created inside every original
%       wavelength interval. Default: 4.
%
%   Method
%       Interpolation method passed to resampleSpectrum:
%
%           "pchip"   default
%           "makima"
%           "spline"
%
%   Example
%   -------
%       [referenceFine, sampleFine] = ...
%           spectralab.core.resampleSpectrumPair( ...
%               referenceSpec, ...
%               sampleSpec, ...
%               RefinementFactor=4, ...
%               Method="pchip");

    arguments
        referenceSpec
        sampleSpec

        options.RefinementFactor (1,1) double ...
            {mustBeInteger, ...
             mustBeGreaterThanOrEqual(options.RefinementFactor, 1)} = 4

        options.Method (1,1) string ...
            {mustBeMember(options.Method, ...
                ["pchip", "makima", "spline"])} = "pchip"
    end

    referenceResult = spectralab.core.resampleSpectrum( ...
        referenceSpec, ...
        RefinementFactor=options.RefinementFactor, ...
        Method=options.Method);

    sampleResult = spectralab.core.resampleSpectrum( ...
        sampleSpec, ...
        RefinementFactor=options.RefinementFactor, ...
        Method=options.Method);

end