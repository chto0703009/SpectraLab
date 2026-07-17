function result = isoVisualDensity(reference, sample, options)
%ISOVISUALDENSITY Calculate ISO visual transmission density.
%
%   RESULT = spectralab.analysis.isoVisualDensity(REFERENCE, SAMPLE)
%
%   calculates ISO visual transmission density using the spectral product
%   of:
%
%       CIE standard illuminant A
%       CIE photopic luminous-efficiency function V(lambda)
%
%   The spectral condition is provided by:
%
%       spectralab.filters.isoVisual()
%
%   Name-value arguments
%   --------------------
%   Resample
%       Enable spectral pre-resampling before weighted integration.
%       Default: false.
%
%   RefinementFactor
%       Number of equal subintervals created within each original
%       wavelength interval.
%       Default: 4.
%
%   InterpolationMethod
%       Interpolation method:
%
%           "pchip"   (default)
%           "makima"
%           "spline"
%
%   The weighted-density calculation is delegated to the common
%   spectralab.core.weightedDensity engine.

    arguments
        reference
        sample

        options.Resample (1,1) logical = false

        options.RefinementFactor (1,1) double ...
            {mustBeInteger, ...
             mustBeGreaterThanOrEqual(options.RefinementFactor, 1)} = 4

        options.InterpolationMethod (1,1) string ...
            {mustBeMember(options.InterpolationMethod, ...
                ["pchip", "makima", "spline"])} = "pchip"
    end

    weighting = spectralab.filters.isoVisual();

    result = spectralab.core.weightedDensity( ...
        reference, ...
        sample, ...
        weighting, ...
        WeightingName="ISO visual: illuminant A × V(lambda)", ...
        Resample=options.Resample, ...
        RefinementFactor=options.RefinementFactor, ...
        InterpolationMethod=options.InterpolationMethod);

end