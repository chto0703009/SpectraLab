function result = whiteDensity(reference, sample, options)
%WHITEDENSITY Calculate photopically weighted visual density.
%
%   RESULT = spectralab.analysis.whiteDensity(REFERENCE, SAMPLE)
%
%   calculates density using the CIE photopic luminous-efficiency
%   weighting function V(lambda).
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
%   The same weighted-density engine is used for white, red, green, blue,
%   and other weighted density measurements. Only the weighting function
%   differs.

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

    weighting = spectralab.filters.photopic();

    result = spectralab.core.weightedDensity( ...
        reference, ...
        sample, ...
        weighting, ...
        WeightingName="CIE photopic V(lambda)", ...
        Resample=options.Resample, ...
        RefinementFactor=options.RefinementFactor, ...
        InterpolationMethod=options.InterpolationMethod);

end